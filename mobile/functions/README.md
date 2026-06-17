# Rifq Cloud Functions

Server-side hooks that fan-out push notifications and run background work.

These are **not bundled with the mobile app** — they live in a separate
Firebase Functions deployment. Drop them next to your `firebase.json` and
deploy with:

```bash
firebase deploy --only functions
```

## Triggers wired up here

| Trigger | Notifies |
|---|---|
| `dailyLog.editedReport` set or `sentAt` updated | All linked parents of the child |
| `attendance.checkInTimes[childId]` set | All linked parents of the child |
| `attendance.checkOutTimes[childId]` set | All linked parents of the child |
| `messages/{threadId}/messages/{id}` created | All other thread participants |
| `nurseries/{nid}/announcements/{id}` created | Audience (all parents or one classroom) |

All of these fetch FCM tokens from the recipient's `/users/{uid}.fcmTokens`
array (written by the mobile app's `NotificationService`).

## Stub functions

The TypeScript stubs in `index.ts` are intentionally minimal — they fetch
the relevant docs, build the payload, and call `messaging.sendEachForMulticast`.
Wire them into your project after `firebase init functions`.
