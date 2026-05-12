import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { defineSecret } from "firebase-functions/params";
import { GoogleGenAI } from "@google/genai";

import { gemma4BaseSampling, GEMMA4_TEMP_SUPPORT_PLAN } from "./genai-sampling";
import { DEFAULT_REMOTE_GEMMA_MODEL } from "./model-ids";
import { buildSupportPlanPrompt, SupportPlanOutput, ProfileData, PersonaPolicyOverrides, SUPPORT_PLAN_SCHEMA } from "./prompts";
import { checkSafety, applySafetyToResponse } from "./safety";

const gemma4ApiKey = defineSecret("GEMMA4_API_KEY");
const gemma4Model = defineSecret("GEMMA4_MODEL");

const db = admin.firestore();

interface GeneratePlanRequest {
  profileId?: string;
  incidentId?: string;
  profileData?: ProfileData;
  challenges?: string[];
  personaData?: Record<string, unknown>;
  incidentContext?: Record<string, unknown>;
  policyOverrides?: PersonaPolicyOverrides;
}

export const generateSupportPlan = functions.https.onCall(
  { secrets: [gemma4ApiKey, gemma4Model], enforceAppCheck: false },
  async (request: functions.https.CallableRequest<GeneratePlanRequest>) => {
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
    }

    const uid = request.auth.uid;
    const data = request.data;

    const apiKey = process.env.GEMMA4_API_KEY;
    if (!apiKey) {
      functions.logger.error("GEMMA4_API_KEY not configured");
      throw new functions.https.HttpsError("internal", "AI service not configured. Please contact support.");
    }

    // Resolve profile + incident from Firestore
    let profileData: ProfileData = data.profileData || (data.personaData as ProfileData) || {};
    let incidentDescription: string | undefined;

    if (data.profileId && data.profileId !== "") {
      try {
        const profileDoc = await db
          .collection("users").doc(uid)
          .collection("profiles").doc(data.profileId)
          .get();
        if (profileDoc.exists) {
          profileData = { ...profileData, ...profileDoc.data() };
        }

        if (data.incidentId) {
          const incidentDoc = await db
            .collection("users").doc(uid)
            .collection("profiles").doc(data.profileId)
            .collection("incidents").doc(data.incidentId)
            .get();
          if (incidentDoc.exists) {
            const incident = incidentDoc.data()!;
            incidentDescription = incident.description as string;
            if (!data.challenges || data.challenges.length === 0) {
              data.challenges = [incident.title as string];
            }
          }
        }
      } catch (err) {
        functions.logger.warn("Could not fetch profile/incident:", err);
      }
    }

    const challenges = data.challenges || [];
    const userInputText = [...challenges, incidentDescription || ""].join(" ");
    const safetyCheck = checkSafety(userInputText);

    const prompt = buildSupportPlanPrompt(profileData, challenges, incidentDescription, data.policyOverrides, data.incidentContext);
    const modelName = process.env.GEMMA4_MODEL || DEFAULT_REMOTE_GEMMA_MODEL;

    // @google/genai — current unified SDK (replaces deprecated @google/generative-ai)
    const ai = new GoogleGenAI({ apiKey });

    let planData: SupportPlanOutput;
    const planGenStart = Date.now();
    try {
      const response = await ai.models.generateContent({
        model: modelName,
        contents: prompt,
        config: {
          ...gemma4BaseSampling({
            temperature: GEMMA4_TEMP_SUPPORT_PLAN,
            maxOutputTokens: 1024,
          }),
          responseMimeType: "application/json",
          responseJsonSchema: SUPPORT_PLAN_SCHEMA,
        },
      });
      functions.logger.info(
        `generateSupportPlan: model=${modelName} ms=${Date.now() - planGenStart}`
      );

      const text = (response.text ?? "").trim();
      const cleaned = text.replace(/^```json\n?/, "").replace(/\n?```$/, "");
      planData = JSON.parse(cleaned) as SupportPlanOutput;
    } catch (err) {
      functions.logger.error("Gemma 4 API error:", err);
      throw new functions.https.HttpsError("internal", "Could not generate support plan. Please try again.");
    }

    // Apply safety
    const safePlan = applySafetyToResponse(
      planData as unknown as Record<string, unknown>,
      userInputText,
      planData.summary
    ) as unknown as SupportPlanOutput;

    if (safetyCheck.isHighRisk) {
      safePlan.escalation_flag = true;
      safePlan.safety_note = safetyCheck.crisisNote;
    }

    // Persist plan to Firestore
    let planId = "";
    if (data.profileId && data.profileId !== "") {
      try {
        const planRef = await db
          .collection("users").doc(uid)
          .collection("profiles").doc(data.profileId)
          .collection("plans")
          .add({
            profileId: data.profileId,
            incidentId: data.incidentId || null,
            summary: safePlan.summary,
            whatMightBeHappening: safePlan.what_might_be_happening,
            whatToDoNow: safePlan.what_to_do_now,
            whatToAvoid: safePlan.what_to_avoid,
            messageDraft: safePlan.message_draft,
            followUpTasks: safePlan.follow_up_tasks,
            reflectionPrompt: safePlan.reflection_prompt,
            escalationFlag: safePlan.escalation_flag,
            safetyNote: safePlan.safety_note,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        planId = planRef.id;
      } catch (err) {
        functions.logger.warn("Could not persist plan:", err);
      }
    }

    functions.logger.info(`generateSupportPlan: uid=${uid} plan=${planId}`);
    return { ...safePlan, planId };
  }
);
