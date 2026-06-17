# رِفق — Firestore rules tests

Real cross-tenant security tests that run against `../firestore.rules`
on the Firebase emulator.

## Run

```bash
cd tests-rules
npm install
npx firebase --project rifq-rules-test emulators:exec --only firestore \
  "node firestore.test.js"
```

Requires JDK 11+ for the emulator. Last run: **31 / 31 passing**.

## What's covered

Cross-tenant attacks (parent / teacher / admin from nursery A trying to
touch nursery B's nurseries, children, classrooms, media, invoices,
announcements, invites, dailyLogs, top-level invite codes). Privilege
escalation via `/users` self-update (role, nurseryId, childIds,
classroomId). Per-child invoice scoping. Unauthenticated reads. Public
enrollment writes. Super-admin global access. Happy paths for every role.

## What's not covered here

Storage rules (`storage.rules`) are deployed alongside but not exercised
by this harness — they'd need the Storage emulator which doesn't run
client-side rule tests as cleanly. The path-prefix tenancy in
`storage.rules` is straightforward and easy to verify with manual
Storage emulator interactions if needed.
