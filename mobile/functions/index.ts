// Skeleton Firebase Cloud Functions for رِفق push notifications.
//
// Drop this into your `functions/src/index.ts` after `firebase init
// functions`. Add `firebase-admin` and `firebase-functions` as deps.
//
// All function bodies are intentionally short — they fetch the relevant
// child + parent docs from Firestore, build an FCM payload, and call
// `messaging.sendEachForMulticast`. Add error handling / dead-token
// cleanup once you observe real traffic.

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2/firestore";

admin.initializeApp();
const db = admin.firestore();

async function fcmTokensForUsers(uids: string[]): Promise<string[]> {
  if (uids.length === 0) return [];
  const docs = await db.getAll(...uids.map((u) => db.doc(`users/${u}`)));
  const tokens: string[] = [];
  for (const doc of docs) {
    const arr = (doc.get("fcmTokens") ?? []) as string[];
    tokens.push(...arr);
  }
  return Array.from(new Set(tokens));
}

async function sendToParentsOfChild(
  nurseryId: string,
  childId: string,
  notification: { title: string; body: string },
  data?: Record<string, string>,
) {
  const child = await db.doc(`nurseries/${nurseryId}/children/${childId}`).get();
  const parentIds = (child.get("parentIds") ?? []) as string[];
  const tokens = await fcmTokensForUsers(parentIds);
  if (tokens.length === 0) return;
  await admin.messaging().sendEachForMulticast({
    tokens,
    notification,
    data: data ?? {},
  });
}

/** Daily-log → parents */
export const onDailyLogWritten = functions.onDocumentWritten(
  "nurseries/{nurseryId}/children/{childId}/dailyLogs/{date}",
  async (event) => {
    const after = event.data?.after.data();
    const before = event.data?.before.data();
    if (!after) return;
    const sentBefore = before?.sentAt?.toMillis?.() ?? 0;
    const sentAfter = after?.sentAt?.toMillis?.() ?? 0;
    if (sentAfter === sentBefore) return;
    const { nurseryId, childId } = event.params;
    await sendToParentsOfChild(
      nurseryId,
      childId,
      { title: "تقرير اليوم", body: "وصلك تقرير جديد عن طفلك" },
      { type: "dailyReport", childId, nurseryId },
    );
  },
);

/** Attendance changes → parents */
export const onAttendanceWritten = functions.onDocumentWritten(
  "nurseries/{nurseryId}/attendance/{date}",
  async (event) => {
    const after = event.data?.after.data();
    const before = event.data?.before.data() ?? {};
    if (!after) return;
    const { nurseryId } = event.params;

    const newCheckIns = after.checkInTimes ?? {};
    const oldCheckIns = before.checkInTimes ?? {};
    for (const childId of Object.keys(newCheckIns)) {
      if (oldCheckIns[childId]?.isEqual?.(newCheckIns[childId])) continue;
      await sendToParentsOfChild(
        nurseryId,
        childId,
        { title: "دخل طفلك للحضانة", body: "تم تسجيل دخول طفلك الآن" },
        { type: "checkIn", childId, nurseryId },
      );
    }
    const newCheckOuts = after.checkOutTimes ?? {};
    const oldCheckOuts = before.checkOutTimes ?? {};
    for (const childId of Object.keys(newCheckOuts)) {
      if (oldCheckOuts[childId]?.isEqual?.(newCheckOuts[childId])) continue;
      await sendToParentsOfChild(
        nurseryId,
        childId,
        { title: "تم استلام طفلك", body: "تم تسجيل خروج طفلك من الحضانة" },
        { type: "checkOut", childId, nurseryId },
      );
    }
  },
);

/** Messages → thread participants (excluding the sender) */
export const onMessageCreated = functions.onDocumentCreated(
  "messages/{threadId}/messages/{messageId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const threadId = event.params.threadId;
    const thread = await db.doc(`messages/${threadId}`).get();
    const participants = (thread.get("participantUids") ?? []) as string[];
    const recipients = participants.filter((u) => u !== data.senderUid);
    const tokens = await fcmTokensForUsers(recipients);
    if (tokens.length === 0) return;
    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title: "رسالة جديدة", body: data.body ?? "" },
      data: { type: "message", threadId },
    });
  },
);

/** Announcements → parents (everyone in the nursery, optionally one classroom) */
export const onAnnouncementCreated = functions.onDocumentCreated(
  "nurseries/{nurseryId}/announcements/{id}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const { nurseryId } = event.params;
    let parentsQuery = db
      .collection("users")
      .where("nurseryId", "==", nurseryId)
      .where("role", "==", "parent");
    if (data.classroomId) {
      // If the announcement targets one classroom, filter by children in it.
      const children = await db
        .collection(`nurseries/${nurseryId}/children`)
        .where("classroomId", "==", data.classroomId)
        .get();
      const childIds = children.docs.map((d) => d.id);
      parentsQuery = parentsQuery.where("childIds", "array-contains-any", childIds);
    }
    const parents = await parentsQuery.get();
    const tokens = await fcmTokensForUsers(parents.docs.map((d) => d.id));
    if (tokens.length === 0) return;
    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title: data.title ?? "إعلان", body: data.body ?? "" },
      data: { type: "announcement", nurseryId },
    });
  },
);
