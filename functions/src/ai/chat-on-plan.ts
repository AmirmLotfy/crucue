import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { defineSecret } from "firebase-functions/params";
import { GoogleGenAI } from "@google/genai";

import { gemma4BaseSampling, GEMMA4_TEMP_CHAT } from "./genai-sampling";
import { DEFAULT_REMOTE_GEMMA_MODEL } from "./model-ids";
import { buildChatPrompt, ProfileData, ChatMessage, PersonaPolicyOverrides } from "./prompts";
import { checkSafety } from "./safety";

const gemma4ApiKey = defineSecret("GEMMA4_API_KEY");
const gemma4Model = defineSecret("GEMMA4_MODEL");

const db = admin.firestore();

interface ChatOnPlanRequest {
  profileId: string;
  planId?: string;
  userMessage: string;
  threadId?: string;
  history?: ChatMessage[];
  policyOverrides?: PersonaPolicyOverrides;
}

const CRISIS_RESPONSE =
  "I want to make sure you and your loved one are safe. " +
  "If there is immediate risk of harm, please call 911 or contact the 988 Suicide & Crisis Lifeline " +
  "by calling or texting 988. You can also text HOME to 741741. " +
  "I'm here to support you through difficult moments, but your safety comes first.";

export const chatOnPlan = functions.https.onCall(
  { secrets: [gemma4ApiKey, gemma4Model], enforceAppCheck: false },
  async (request: functions.https.CallableRequest<ChatOnPlanRequest>) => {
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
    }

    const uid = request.auth.uid;
    const data = request.data;

    if (!data.userMessage?.trim()) {
      throw new functions.https.HttpsError("invalid-argument", "Message cannot be empty.");
    }

    // Safety check on user message first
    const safetyCheck = checkSafety(data.userMessage);
    if (safetyCheck.isHighRisk) {
      return { response: CRISIS_RESPONSE, escalated: true };
    }

    const apiKey = process.env.GEMMA4_API_KEY;
    if (!apiKey) {
      throw new functions.https.HttpsError("internal", "AI service not configured.");
    }

    // Load profile context + recent reflections for grounding
    let profileData: ProfileData = {};
    let planSummary: string | null = null;
    const recentReflections: string[] = [];

    try {
      if (data.profileId) {
        const profileDoc = await db
          .collection("users").doc(uid)
          .collection("profiles").doc(data.profileId)
          .get();
        if (profileDoc.exists) profileData = profileDoc.data() as ProfileData;

        const checkinsSnap = await db
          .collection("users").doc(uid)
          .collection("profiles").doc(data.profileId)
          .collection("checkins")
          .orderBy("createdAt", "desc")
          .limit(3)
          .get();
        for (const doc of checkinsSnap.docs) {
          const c = doc.data();
          const parts: string[] = [];
          if (c.didThisHelp) parts.push("helped");
          if (c.stepsHelpedMost?.length) parts.push(`worked: ${c.stepsHelpedMost.join(", ")}`);
          if (c.whatMadeItWorse) parts.push(`harder: ${c.whatMadeItWorse}`);
          if (parts.length) recentReflections.push(parts.join("; "));
        }
      }

      if (data.profileId && data.planId) {
        const planDoc = await db
          .collection("users").doc(uid)
          .collection("profiles").doc(data.profileId)
          .collection("plans").doc(data.planId)
          .get();
        if (planDoc.exists) {
          planSummary = (planDoc.data()?.summary as string) ?? null;
        }
      }
    } catch (err) {
      functions.logger.warn("Could not load context:", err);
    }

    if (recentReflections.length && planSummary) {
      planSummary = `${planSummary}\n\nRecent reflections: ${recentReflections.join(" | ")}`;
    }

    const history = data.history || [];
    const prompt = buildChatPrompt(profileData, planSummary, history, data.userMessage, data.policyOverrides);
    const modelName = process.env.GEMMA4_MODEL || DEFAULT_REMOTE_GEMMA_MODEL;

    // @google/genai — current unified SDK
    const ai = new GoogleGenAI({ apiKey });

    let responseText: string;
    const chatStart = Date.now();
    try {
      const response = await ai.models.generateContent({
        model: modelName,
        contents: prompt,
        config: gemma4BaseSampling({
          temperature: GEMMA4_TEMP_CHAT,
          maxOutputTokens: 512,
        }),
      });
      functions.logger.info(
        `chatOnPlan: model=${modelName} ms=${Date.now() - chatStart}`
      );
      responseText = (response.text ?? "").trim();
    } catch (err) {
      functions.logger.error("Gemma 4 chat error:", err);
      throw new functions.https.HttpsError("internal", "Could not process message.");
    }

    // Safety check on AI output
    const outputCheck = checkSafety(responseText);
    if (outputCheck.isHighRisk) {
      responseText = CRISIS_RESPONSE;
    }

    // Persist to thread if provided
    if (data.threadId) {
      try {
        const threadRef = db
          .collection("users").doc(uid)
          .collection("chatThreads").doc(data.threadId);

        await threadRef.collection("messages").add({
          role: "user",
          content: data.userMessage,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        await threadRef.collection("messages").add({
          role: "assistant",
          content: responseText,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        await threadRef.update({ updatedAt: admin.firestore.FieldValue.serverTimestamp() });
      } catch (err) {
        functions.logger.warn("Could not persist chat messages:", err);
      }
    }

    functions.logger.info(`chatOnPlan: uid=${uid} thread=${data.threadId || "none"}`);
    return { response: responseText, escalated: false };
  }
);
