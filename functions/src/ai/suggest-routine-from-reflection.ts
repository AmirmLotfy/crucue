import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { defineSecret } from "firebase-functions/params";
import { GoogleGenAI } from "@google/genai";

import { gemma4BaseSampling, GEMMA4_TEMP_ROUTINE_SUGGEST } from "./genai-sampling";
import { DEFAULT_REMOTE_GEMMA_MODEL } from "./model-ids";
import {
  buildRoutineSuggestionPrompt,
  ROUTINE_SUGGESTION_SCHEMA,
} from "./prompts";
import { checkSafety } from "./safety";

const gemma4ApiKey = defineSecret("GEMMA4_API_KEY");
const gemma4Model = defineSecret("GEMMA4_MODEL");

const db = admin.firestore();

interface SuggestRoutineRequest {
  profileId: string;
  planId: string;
  reflectionNotes?: string;
  stepsHelpedMost?: string[];
  personaTypeKey?: string;
}

export interface RoutineSuggestionOutput {
  title: string;
  steps: string[];
  frequency: string;
  estimatedDurationMinutes?: number;
  tags?: string[];
  rationale?: string;
}

export const suggestRoutineFromReflection = functions.https.onCall(
  {
    secrets: [gemma4ApiKey, gemma4Model],
    enforceAppCheck: false,
  },
  async (request: functions.https.CallableRequest<SuggestRoutineRequest>) => {
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
    }

    const uid = request.auth.uid;
    const data = request.data;

    if (!data.profileId?.trim() || !data.planId?.trim()) {
      throw new functions.https.HttpsError("invalid-argument", "profileId and planId are required.");
    }

    const apiKey = process.env.GEMMA4_API_KEY;
    if (!apiKey) {
      throw new functions.https.HttpsError("internal", "AI service not configured.");
    }

    const profileRef = db
      .collection("users").doc(uid)
      .collection("profiles").doc(data.profileId);
    const planRef = profileRef.collection("plans").doc(data.planId);

    const [profileSnap, planSnap] = await Promise.all([profileRef.get(), planRef.get()]);

    if (!planSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Support plan not found.");
    }

    const plan = planSnap.data()!;
    const summary = (plan.summary as string) || "";
    const whatToDoNow = (plan.whatToDoNow as string[]) || [];
    const followUpTasks = (plan.followUpTasks as string[]) || [];

    let personaTypeKey = data.personaTypeKey;
    if (!personaTypeKey && profileSnap.exists) {
      const rel = profileSnap.data()!.relationship as string | undefined;
      if (rel) personaTypeKey = rel;
    }

    const reflectionText = [
      data.reflectionNotes || "",
      ...(data.stepsHelpedMost || []),
    ].join(" ");
    const safetyCheck = checkSafety(reflectionText);
    if (safetyCheck.isHighRisk) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Cannot generate a routine for this reflection. If you are in crisis, please contact emergency services or 988."
      );
    }

    const prompt = buildRoutineSuggestionPrompt({
      planSummary: summary,
      whatToDoNow,
      followUpTasks,
      reflectionNotes: data.reflectionNotes,
      stepsHelpedMost: data.stepsHelpedMost,
      personaTypeKey,
    });

    const modelName = process.env.GEMMA4_MODEL || DEFAULT_REMOTE_GEMMA_MODEL;
    const ai = new GoogleGenAI({ apiKey });

    let routine: RoutineSuggestionOutput;
    const routineStart = Date.now();
    try {
      const response = await ai.models.generateContent({
        model: modelName,
        contents: prompt,
        config: {
          ...gemma4BaseSampling({
            temperature: GEMMA4_TEMP_ROUTINE_SUGGEST,
            maxOutputTokens: 512,
          }),
          responseMimeType: "application/json",
          responseJsonSchema: ROUTINE_SUGGESTION_SCHEMA,
        },
      });
      functions.logger.info(
        `suggestRoutineFromReflection: model=${modelName} ms=${Date.now() - routineStart}`
      );

      const text = (response.text ?? "").trim();
      const cleaned = text.replace(/^```json\n?/, "").replace(/\n?```$/, "");
      routine = JSON.parse(cleaned) as RoutineSuggestionOutput;
    } catch (err) {
      functions.logger.error("suggestRoutineFromReflection Gemma error:", err);
      throw new functions.https.HttpsError(
        "internal",
        "Could not suggest a routine. Please try again."
      );
    }

    if (!routine.title?.trim() || !Array.isArray(routine.steps) || routine.steps.length === 0) {
      throw new functions.https.HttpsError("internal", "Invalid routine suggestion from model.");
    }

    functions.logger.info(`suggestRoutineFromReflection: uid=${uid} profile=${data.profileId}`);
    return routine;
  }
);
