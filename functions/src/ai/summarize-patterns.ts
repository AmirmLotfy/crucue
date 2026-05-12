import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { defineSecret } from "firebase-functions/params";
import { GoogleGenAI } from "@google/genai";

import { gemma4BaseSampling, GEMMA4_TEMP_WEEKLY_INSIGHT } from "./genai-sampling";
import { DEFAULT_REMOTE_GEMMA_MODEL } from "./model-ids";
import { buildSummarizePrompt, INSIGHT_SCHEMA } from "./prompts";

const gemma4ApiKey = defineSecret("GEMMA4_API_KEY");
const gemma4Model = defineSecret("GEMMA4_MODEL");

const db = admin.firestore();

interface SummarizePatternsRequest {
  profileId: string;
  weekStart?: string;
}

export const summarizePatterns = functions.https.onCall(
  { secrets: [gemma4ApiKey, gemma4Model], enforceAppCheck: false },
  async (request: functions.https.CallableRequest<SummarizePatternsRequest>) => {
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
    }

    const uid = request.auth.uid;
    const data = request.data;

    if (!data.profileId) {
      throw new functions.https.HttpsError("invalid-argument", "profileId is required.");
    }

    const apiKey = process.env.GEMMA4_API_KEY;
    if (!apiKey) {
      throw new functions.https.HttpsError("internal", "AI service not configured.");
    }

    const weekStart = data.weekStart ? new Date(data.weekStart) : getLastMonday();
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekEnd.getDate() + 7);

    const profileBase = db
      .collection("users").doc(uid)
      .collection("profiles").doc(data.profileId);

    const [incidentsSnap, plansSnap, checkinsSnap] = await Promise.all([
      profileBase.collection("incidents")
        .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(weekStart))
        .where("createdAt", "<", admin.firestore.Timestamp.fromDate(weekEnd))
        .orderBy("createdAt", "desc").limit(20).get(),
      profileBase.collection("plans")
        .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(weekStart))
        .orderBy("createdAt", "desc").limit(10).get(),
      profileBase.collection("checkins")
        .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(weekStart))
        .orderBy("createdAt", "desc").limit(20).get(),
    ]);

    const incidents = incidentsSnap.docs.map((d) => ({
      title: d.data().title as string,
      category: d.data().category as string,
      intensity: d.data().intensity as number,
    }));
    const plans = plansSnap.docs.map((d) => ({
      summary: d.data().summary as string,
      followUpTasks: (d.data().followUpTasks as string[]) || [],
    }));
    const checkins = checkinsSnap.docs.map((d) => ({
      didThisHelp: d.data().didThisHelp as boolean,
      notes: d.data().notes as string | undefined,
    }));

    const prompt = buildSummarizePrompt(incidents, plans, checkins);
    const modelName = process.env.GEMMA4_MODEL || DEFAULT_REMOTE_GEMMA_MODEL;

    // @google/genai — current unified SDK
    const ai = new GoogleGenAI({ apiKey });

    let insight: Record<string, unknown>;
    const summarizeStart = Date.now();
    try {
      const response = await ai.models.generateContent({
        model: modelName,
        contents: prompt,
        config: {
          ...gemma4BaseSampling({
            temperature: GEMMA4_TEMP_WEEKLY_INSIGHT,
            maxOutputTokens: 512,
          }),
          responseMimeType: "application/json",
          responseJsonSchema: INSIGHT_SCHEMA,
        },
      });
      functions.logger.info(
        `summarizePatterns: model=${modelName} ms=${Date.now() - summarizeStart}`
      );

      const text = (response.text ?? "").trim();
      const cleaned = text.replace(/^```json\n?/, "").replace(/\n?```$/, "");
      insight = JSON.parse(cleaned) as Record<string, unknown>;
    } catch (err) {
      functions.logger.error("Gemma 4 summarize error:", err);
      insight = {
        summary: "Keep going — you're learning what works best for your family.",
        patterns: [],
        whatWorked: [],
        suggestions: ["Continue logging daily moments to build insights."],
      };
    }

    // Insight persistence is handled by the Flutter client ([FirestoreService.saveInsight])
    // so hybrid mode (local Gemma + same UI path) does not create duplicate documents.

    functions.logger.info(`summarizePatterns: uid=${uid} profile=${data.profileId}`);
    return insight;
  }
);

function getLastMonday(): Date {
  const now = new Date();
  const day = now.getDay();
  const diff = now.getDate() - day + (day === 0 ? -6 : 1);
  const monday = new Date(now.setDate(diff));
  monday.setHours(0, 0, 0, 0);
  return monday;
}
