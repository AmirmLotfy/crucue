import * as admin from "firebase-admin";

admin.initializeApp();

// Export all callable functions
export { generateSupportPlan } from "./ai/generate-support-plan";
export { chatOnPlan } from "./ai/chat-on-plan";
export { summarizePatterns } from "./ai/summarize-patterns";
export { processVoiceIncident, transcribeShortClip } from "./ai/process-voice-incident";
export { suggestRoutineFromReflection } from "./ai/suggest-routine-from-reflection";
export { sendTestPushNotification } from "./messaging/send-test-push";
