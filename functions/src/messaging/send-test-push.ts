import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

const db = admin.firestore();

interface SendTestPushRequest {
  title?: string;
  body?: string;
}

/**
 * Sends a test notification to all FCM tokens stored under users/{uid}/devices/*.
 */
export const sendTestPushNotification = functions.https.onCall(
  { enforceAppCheck: false },
  async (request: functions.https.CallableRequest<SendTestPushRequest>) => {
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
    }

    const uid = request.auth.uid;
    const title = request.data.title?.trim() || "Crucue";
    const body = request.data.body?.trim() || "Test notification";

    const snap = await db.collection("users").doc(uid).collection("devices").get();
    const tokens = snap.docs
      .map((d) => d.data().token as string | undefined)
      .filter((t): t is string => typeof t === "string" && t.length > 10);

    if (tokens.length === 0) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "No FCM tokens registered. Open the app on a device after signing in."
      );
    }

    const messaging = admin.messaging();
    let sent = 0;
    let failed = 0;

    for (const token of tokens) {
      try {
        await messaging.send({
          token,
          notification: { title, body },
          android: { priority: "high" },
          apns: {
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
        });
        sent++;
      } catch (e) {
        functions.logger.warn("sendTestPush token failed:", e);
        failed++;
      }
    }

    functions.logger.info(`sendTestPushNotification: uid=${uid} sent=${sent} failed=${failed}`);
    return { sent, failed, totalTokens: tokens.length };
  }
);
