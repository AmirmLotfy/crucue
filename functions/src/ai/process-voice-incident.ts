/**
 * processVoiceIncident — Crucue Voice AI Pipeline
 *
 * Pipeline:
 *   1. Download audio from Firebase Storage
 *   2. Transcribe with Google Cloud Speech-to-Text REST API
 *   3. Extract structured incident fields with Gemma 4 via @google/genai
 *   4. Update VoiceNote in Firestore with results
 *   5. Return transcript + extractedIncident to Flutter
 *
 * Also exports: transcribeShortClip — lightweight STT for voice chat input.
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { defineSecret } from "firebase-functions/params";
import { GoogleGenAI } from "@google/genai";

import { gemma4BaseSampling, GEMMA4_TEMP_VOICE_EXTRACT } from "./genai-sampling";
import { DEFAULT_REMOTE_GEMMA_MODEL } from "./model-ids";
import {
  buildExtractIncidentPrompt,
  VoiceIncidentOutput,
  VOICE_INCIDENT_SCHEMA,
  PersonaPolicyOverrides,
} from "./prompts";
import { checkSafety } from "./safety";

const gemma4ApiKey = defineSecret("GEMMA4_API_KEY");
const gemma4Model = defineSecret("GEMMA4_MODEL");

const db = admin.firestore();
const storage = admin.storage();

interface ProcessVoiceRequest {
  voiceNoteId: string;
  profileId: string;
  audioStoragePath: string;
  policyOverrides?: PersonaPolicyOverrides;
}

// ─── processVoiceIncident ─────────────────────────────────────────────────────

export const processVoiceIncident = functions.https.onCall(
  { secrets: [gemma4ApiKey, gemma4Model], enforceAppCheck: false },
  async (request: functions.https.CallableRequest<ProcessVoiceRequest>) => {
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
    }

    const uid = request.auth.uid;
    const { voiceNoteId, profileId, audioStoragePath, policyOverrides } = request.data;

    if (!voiceNoteId || !profileId || !audioStoragePath) {
      throw new functions.https.HttpsError("invalid-argument", "Missing required fields.");
    }

    const apiKey = process.env.GEMMA4_API_KEY;
    if (!apiKey) {
      throw new functions.https.HttpsError("internal", "AI service not configured.");
    }

    const voiceNoteRef = db
      .collection("users").doc(uid)
      .collection("profiles").doc(profileId)
      .collection("voiceNotes").doc(voiceNoteId);

    await voiceNoteRef.update({
      status: "transcribing",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Step 1: Google Cloud Speech-to-Text
    let transcript: string;
    try {
      transcript = await transcribeAudio(audioStoragePath);
    } catch (err) {
      functions.logger.error("STT error:", err);
      await voiceNoteRef.update({
        status: "failed",
        errorMessage: "Transcription failed. Please try again.",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      throw new functions.https.HttpsError("internal", "Transcription failed.");
    }

    const safetyCheck = checkSafety(transcript);

    await voiceNoteRef.update({
      transcript,
      status: "extracting",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Step 2: Gemma 4 incident extraction via @google/genai
    let extracted: VoiceIncidentOutput;
    try {
      const modelName = process.env.GEMMA4_MODEL || DEFAULT_REMOTE_GEMMA_MODEL;
      const ai = new GoogleGenAI({ apiKey });

      const prompt = buildExtractIncidentPrompt(transcript, undefined, policyOverrides);

      const extractStart = Date.now();
      const response = await ai.models.generateContent({
        model: modelName,
        contents: prompt,
        config: {
          ...gemma4BaseSampling({
            temperature: GEMMA4_TEMP_VOICE_EXTRACT,
            maxOutputTokens: 768,
          }),
          responseMimeType: "application/json",
          responseJsonSchema: VOICE_INCIDENT_SCHEMA,
        },
      });
      functions.logger.info(
        `processVoiceIncident extract: model=${modelName} ms=${Date.now() - extractStart}`
      );

      const text = (response.text ?? "").trim();
      const cleaned = text.replace(/^```json\n?/, "").replace(/\n?```$/, "");
      extracted = JSON.parse(cleaned) as VoiceIncidentOutput;
    } catch (err) {
      functions.logger.error("Gemma 4 extraction error:", err);
      extracted = buildFallbackExtraction(transcript);
    }

    if (safetyCheck.isHighRisk) {
      extracted.safety_flag = true;
    }

    // Step 3: Write results to Firestore
    await voiceNoteRef.update({
      transcript,
      extractedIncident: { ...extracted, transcript },
      safetyFlag: extracted.safety_flag,
      status: "completed",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    try {
      await storage.bucket().file(audioStoragePath).delete({ ignoreNotFound: true });
      functions.logger.info(`Deleted voice audio after processing: ${audioStoragePath}`);
    } catch (delErr) {
      functions.logger.warn("Voice audio delete after processing failed (non-fatal):", delErr);
    }

    functions.logger.info(`processVoiceIncident: uid=${uid} voiceNote=${voiceNoteId} confidence=${extracted.confidence}`);

    return {
      transcript,
      extractedIncident: { ...extracted, transcript },
      safetyFlag: extracted.safety_flag,
    };
  }
);

// ─── transcribeShortClip ──────────────────────────────────────────────────────

interface TranscribeClipRequest {
  audioStoragePath: string;
}

export const transcribeShortClip = functions.https.onCall(
  { secrets: [gemma4ApiKey, gemma4Model], enforceAppCheck: false },
  async (request: functions.https.CallableRequest<TranscribeClipRequest>) => {
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
    }

    const { audioStoragePath } = request.data;
    if (!audioStoragePath) {
      throw new functions.https.HttpsError("invalid-argument", "audioStoragePath required.");
    }

    try {
      const transcript = await transcribeAudio(audioStoragePath, { shortClip: true });
      try {
        await storage.bucket().file(audioStoragePath).delete({ ignoreNotFound: true });
      } catch (delErr) {
        functions.logger.warn("Short-clip audio delete after STT failed (non-fatal):", delErr);
      }
      return { transcript };
    } catch (err) {
      functions.logger.error("transcribeShortClip error:", err);
      return { transcript: "" };
    }
  }
);

// ─── Internal helpers ─────────────────────────────────────────────────────────

async function transcribeAudio(
  storagePath: string,
  options: { maxAlternatives?: number; shortClip?: boolean } = {}
): Promise<string> {
  const bucket = storage.bucket();
  const file = bucket.file(storagePath);
  const [audioBytes] = await file.download();
  const audioContent = audioBytes.toString("base64");

  const sttRequest = {
    config: {
      encoding: "MP3",
      sampleRateHertz: 16000,
      languageCode: "en-US",
      enableAutomaticPunctuation: true,
      maxAlternatives: options.maxAlternatives ?? 1,
      model: options.shortClip ? "phone_call" : "latest_long",
    },
    audio: { content: audioContent },
  };

  // Get access token from metadata server (available in Cloud Functions runtime)
  const metadataFetch = await globalThis.fetch(
    "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token",
    { headers: { "Metadata-Flavor": "Google" } }
  );

  let accessToken: string;
  if (metadataFetch.ok) {
    const tokenData = await metadataFetch.json() as { access_token: string };
    accessToken = tokenData.access_token;
  } else {
    const credential = admin.app().options.credential;
    if (credential) {
      const token = await (credential as admin.credential.Credential).getAccessToken();
      accessToken = token.access_token;
    } else {
      throw new Error("Cannot obtain access token for Speech-to-Text.");
    }
  }

  const sttResponse = await globalThis.fetch(
    "https://speech.googleapis.com/v1/speech:recognize",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(sttRequest),
    }
  );

  if (!sttResponse.ok) {
    const errText = await sttResponse.text();
    functions.logger.error("STT API error:", errText);
    throw new Error(`Speech-to-Text API error: ${sttResponse.status}`);
  }

  const sttData = await sttResponse.json() as {
    results?: Array<{
      alternatives?: Array<{ transcript?: string; confidence?: number }>;
    }>;
  };

  const transcript = sttData.results
    ?.flatMap((r) => r.alternatives ?? [])
    .map((a) => a.transcript ?? "")
    .filter(Boolean)
    .join(" ")
    .trim();

  return transcript || "";
}

function buildFallbackExtraction(transcript: string): VoiceIncidentOutput {
  const lower = transcript.toLowerCase();
  let category = "other";
  if (lower.includes("school") || lower.includes("homework") || lower.includes("morning")) {
    category = "routine";
  } else if (lower.includes("upset") || lower.includes("cry") || lower.includes("anxious")) {
    category = "emotion";
  } else if (lower.includes("hit") || lower.includes("kick") || lower.includes("threw")) {
    category = "behavior";
  } else if (lower.includes("said") || lower.includes("listen") || lower.includes("talk")) {
    category = "communication";
  }

  const shortTitle = transcript.slice(0, 60).replace(/\n/g, " ").trim();
  const safetyFlag = /harm|hurt|suicid|injur|danger|emergency/.test(lower);

  return {
    transcript,
    cleaned_summary: transcript.slice(0, 200).trim(),
    incident_title: shortTitle.length > 5 ? shortTitle : "Voice note",
    incident_category: category,
    intensity: 3,
    possible_trigger: null,
    what_user_already_tried: null,
    desired_outcome: null,
    key_entities: [],
    confidence: 0.4,
    safety_flag: safetyFlag,
  };
}
