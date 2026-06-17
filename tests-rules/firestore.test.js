/**
 * Real cross-tenant security tests against the deployed firestore.rules.
 *
 * Setup:
 *   - Spawns two tenants (nurseries A and B), each with admin + teacher +
 *     parent + a child.
 *   - For each "attack", we attempt the operation as a user from tenant A
 *     against tenant B's data and assert that it is REJECTED.
 *   - For each "happy path", we run the same operation as the legitimate
 *     tenant member and assert it SUCCEEDS.
 *
 * Run via: `npm test` (which calls `firebase emulators:exec`).
 */

const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  setDoc,
  getDoc,
  updateDoc,
  deleteDoc,
  collection,
  addDoc,
  setLogLevel,
} = require('firebase/firestore');

setLogLevel('error');

const PROJECT_ID = 'rifq-rules-test';
const RULES = fs.readFileSync(
  path.resolve(__dirname, '..', 'firestore.rules'),
  'utf8',
);

let testEnv;

const NID_A = 'nursery_a';
const NID_B = 'nursery_b';

const UIDS = {
  superAdmin: 'super_uid',
  adminA: 'admin_a_uid',
  teacherA: 'teacher_a_uid',
  parentA: 'parent_a_uid',
  childA: 'child_a_id',
  classroomA: 'classroom_a_id',
  adminB: 'admin_b_uid',
  teacherB: 'teacher_b_uid',
  parentB: 'parent_b_uid',
  childB: 'child_b_id',
  classroomB: 'classroom_b_id',
};

async function seed() {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    // Users
    await setDoc(doc(db, `users/${UIDS.superAdmin}`), {
      name: 'Super', role: 'superAdmin', nurseryId: null, childIds: [],
    });

    // Tenant A
    await setDoc(doc(db, `users/${UIDS.adminA}`), {
      name: 'Admin A', role: 'admin', nurseryId: NID_A, childIds: [],
    });
    await setDoc(doc(db, `users/${UIDS.teacherA}`), {
      name: 'Teacher A', role: 'teacher', nurseryId: NID_A,
      classroomId: UIDS.classroomA, childIds: [],
    });
    await setDoc(doc(db, `users/${UIDS.parentA}`), {
      name: 'Parent A', role: 'parent', nurseryId: NID_A,
      childIds: [UIDS.childA],
    });
    await setDoc(doc(db, `nurseries/${NID_A}`), {
      name: 'حضانة أ', ownerUid: UIDS.adminA, plan: 'متوسط',
      subscriptionStatus: 'active', trialActive: false, childrenCount: 1,
    });
    await setDoc(doc(db, `nurseries/${NID_A}/classrooms/${UIDS.classroomA}`), {
      name: 'فصل أ', capacity: 20,
    });
    await setDoc(doc(db, `nurseries/${NID_A}/children/${UIDS.childA}`), {
      name: 'طفل أ', classroomId: UIDS.classroomA, parentIds: [UIDS.parentA],
    });
    await setDoc(doc(db, `nurseries/${NID_A}/invoices/inv_a`), {
      childId: UIDS.childA, amount: 1000, status: 'unpaid',
    });
    await setDoc(doc(db, `nurseries/${NID_A}/media/m_a`), {
      classroomId: UIDS.classroomA, url: 'https://example.com/a.jpg',
      type: 'photo', uploadedByUid: UIDS.teacherA, childIds: [UIDS.childA],
    });
    await setDoc(doc(db, `nurseries/${NID_A}/announcements/ann_a`), {
      title: 'إعلان أ', body: '...', authorUid: UIDS.adminA,
    });
    await setDoc(doc(db, `nurseries/${NID_A}/invites/CODEAA`), {
      nurseryId: NID_A, role: 'teacher', used: false,
    });

    // Tenant B (mirror)
    await setDoc(doc(db, `users/${UIDS.adminB}`), {
      name: 'Admin B', role: 'admin', nurseryId: NID_B, childIds: [],
    });
    await setDoc(doc(db, `users/${UIDS.teacherB}`), {
      name: 'Teacher B', role: 'teacher', nurseryId: NID_B,
      classroomId: UIDS.classroomB, childIds: [],
    });
    await setDoc(doc(db, `users/${UIDS.parentB}`), {
      name: 'Parent B', role: 'parent', nurseryId: NID_B,
      childIds: [UIDS.childB],
    });
    await setDoc(doc(db, `nurseries/${NID_B}`), {
      name: 'حضانة ب', ownerUid: UIDS.adminB, plan: 'بريميوم',
      subscriptionStatus: 'active', trialActive: false, childrenCount: 1,
    });
    await setDoc(doc(db, `nurseries/${NID_B}/classrooms/${UIDS.classroomB}`), {
      name: 'فصل ب', capacity: 25,
    });
    await setDoc(doc(db, `nurseries/${NID_B}/children/${UIDS.childB}`), {
      name: 'طفل ب', classroomId: UIDS.classroomB, parentIds: [UIDS.parentB],
    });
    await setDoc(doc(db, `nurseries/${NID_B}/invoices/inv_b`), {
      childId: UIDS.childB, amount: 1000, status: 'unpaid',
    });
    await setDoc(doc(db, `nurseries/${NID_B}/media/m_b`), {
      classroomId: UIDS.classroomB, url: 'https://example.com/b.jpg',
      type: 'photo', uploadedByUid: UIDS.teacherB, childIds: [UIDS.childB],
    });
    await setDoc(doc(db, `nurseries/${NID_B}/announcements/ann_b`), {
      title: 'إعلان ب', body: '...', authorUid: UIDS.adminB,
    });
  });
}

function dbAs(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

const tests = [];
function test(name, fn) { tests.push({ name, fn }); }

// ===== Cross-tenant ATTACKS — should all be rejected =====

test('parent A cannot read nursery B doc', async () => {
  await assertFails(getDoc(doc(dbAs(UIDS.parentA), `nurseries/${NID_B}`)));
});

test('parent A cannot read nursery B child', async () => {
  await assertFails(getDoc(
    doc(dbAs(UIDS.parentA), `nurseries/${NID_B}/children/${UIDS.childB}`),
  ));
});

test('parent A cannot read nursery B classroom', async () => {
  await assertFails(getDoc(
    doc(dbAs(UIDS.parentA), `nurseries/${NID_B}/classrooms/${UIDS.classroomB}`),
  ));
});

test('parent A cannot read nursery B media', async () => {
  await assertFails(getDoc(
    doc(dbAs(UIDS.parentA), `nurseries/${NID_B}/media/m_b`),
  ));
});

test('parent A cannot read nursery B invoice', async () => {
  await assertFails(getDoc(
    doc(dbAs(UIDS.parentA), `nurseries/${NID_B}/invoices/inv_b`),
  ));
});

test('parent A cannot read nursery B announcement', async () => {
  await assertFails(getDoc(
    doc(dbAs(UIDS.parentA), `nurseries/${NID_B}/announcements/ann_b`),
  ));
});

test('teacher A cannot read nursery B child', async () => {
  await assertFails(getDoc(
    doc(dbAs(UIDS.teacherA), `nurseries/${NID_B}/children/${UIDS.childB}`),
  ));
});

test('teacher A cannot write to nursery B daily log', async () => {
  await assertFails(setDoc(
    doc(dbAs(UIDS.teacherA),
      `nurseries/${NID_B}/children/${UIDS.childB}/dailyLogs/today`),
    { mood: 'happy' },
  ));
});

test('admin A cannot edit nursery B', async () => {
  await assertFails(updateDoc(
    doc(dbAs(UIDS.adminA), `nurseries/${NID_B}`),
    { name: 'hijacked' },
  ));
});

test('admin A cannot delete nursery B child', async () => {
  await assertFails(deleteDoc(
    doc(dbAs(UIDS.adminA), `nurseries/${NID_B}/children/${UIDS.childB}`),
  ));
});

test('admin A cannot create child in nursery B', async () => {
  await assertFails(addDoc(
    collection(dbAs(UIDS.adminA), `nurseries/${NID_B}/children`),
    { name: 'intruder', classroomId: 'x' },
  ));
});

test('admin A cannot issue invites in nursery B', async () => {
  await assertFails(setDoc(
    doc(dbAs(UIDS.adminA), `nurseries/${NID_B}/invites/HACK01`),
    { nurseryId: NID_B, role: 'teacher', used: false },
  ));
});

test('admin A cannot mint a top-level invite code for nursery B', async () => {
  await assertFails(setDoc(
    doc(dbAs(UIDS.adminA), `inviteCodes/HACK02`),
    { nurseryId: NID_B },
  ));
});

test('parent A cannot read nursery A invoice for child they do not own',
  async () => {
    // First add an invoice for a child the parent does not own.
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), `nurseries/${NID_A}/invoices/inv_other`),
        { childId: 'other_child', amount: 50, status: 'unpaid' },
      );
    });
    await assertFails(getDoc(
      doc(dbAs(UIDS.parentA), `nurseries/${NID_A}/invoices/inv_other`),
    ));
  });

test('parent cannot escalate to admin role via /users self-update',
  async () => {
    await assertFails(updateDoc(
      doc(dbAs(UIDS.parentA), `users/${UIDS.parentA}`),
      { role: 'admin' },
    ));
  });

test('parent cannot move themselves to a different nursery', async () => {
  await assertFails(updateDoc(
    doc(dbAs(UIDS.parentA), `users/${UIDS.parentA}`),
    { nurseryId: NID_B },
  ));
});

test('parent cannot add a child to their own childIds', async () => {
  await assertFails(updateDoc(
    doc(dbAs(UIDS.parentA), `users/${UIDS.parentA}`),
    { childIds: [UIDS.childA, UIDS.childB] },
  ));
});

test('HP: parent can self-edit their phone + emergency contact',
  async () => {
    await assertSucceeds(updateDoc(
      doc(dbAs(UIDS.parentA), `users/${UIDS.parentA}`),
      {
        phone: '+966500000000',
        emergencyContactName: 'أم',
        emergencyContactPhone: '+966500000001',
        preferHijri: true,
      },
    ));
  });

test('signed-out user cannot read any nursery', async () => {
  await assertFails(getDoc(
    doc(testEnv.unauthenticatedContext().firestore(), `nurseries/${NID_A}`),
  ));
});

test('signed-out user cannot read a child', async () => {
  await assertFails(getDoc(
    doc(testEnv.unauthenticatedContext().firestore(),
      `nurseries/${NID_A}/children/${UIDS.childA}`),
  ));
});

// ===== HAPPY PATH — should succeed =====

test('HP: parent A reads their own child', async () => {
  await assertSucceeds(getDoc(
    doc(dbAs(UIDS.parentA), `nurseries/${NID_A}/children/${UIDS.childA}`),
  ));
});

test('HP: parent A reads their own invoice', async () => {
  await assertSucceeds(getDoc(
    doc(dbAs(UIDS.parentA), `nurseries/${NID_A}/invoices/inv_a`),
  ));
});

test('HP: parent A reads tenant A nursery doc', async () => {
  await assertSucceeds(getDoc(
    doc(dbAs(UIDS.parentA), `nurseries/${NID_A}`),
  ));
});

test('HP: parent A reads tenant A announcement', async () => {
  await assertSucceeds(getDoc(
    doc(dbAs(UIDS.parentA), `nurseries/${NID_A}/announcements/ann_a`),
  ));
});

test('HP: teacher A reads their classroom child', async () => {
  await assertSucceeds(getDoc(
    doc(dbAs(UIDS.teacherA), `nurseries/${NID_A}/children/${UIDS.childA}`),
  ));
});

test('HP: teacher A writes a daily log', async () => {
  await assertSucceeds(setDoc(
    doc(dbAs(UIDS.teacherA),
      `nurseries/${NID_A}/children/${UIDS.childA}/dailyLogs/2025-01-01`),
    { mood: 'happy', activities: [] },
  ));
});

test('HP: admin A edits their own nursery', async () => {
  await assertSucceeds(updateDoc(
    doc(dbAs(UIDS.adminA), `nurseries/${NID_A}`),
    { name: 'حضانة أ المعدّلة' },
  ));
});

test('HP: admin A issues an invite for their nursery', async () => {
  await assertSucceeds(setDoc(
    doc(dbAs(UIDS.adminA), `nurseries/${NID_A}/invites/NEWCD1`),
    { nurseryId: NID_A, role: 'teacher', used: false },
  ));
});

test('HP: admin A mints matching top-level invite code', async () => {
  await assertSucceeds(setDoc(
    doc(dbAs(UIDS.adminA), `inviteCodes/NEWCD1`),
    { nurseryId: NID_A },
  ));
});

test('HP: public enrollment write is allowed unauthenticated', async () => {
  await assertSucceeds(addDoc(
    collection(testEnv.unauthenticatedContext().firestore(),
      `nurseries/${NID_A}/enrollments`),
    {
      childName: 'طفل جديد', parentName: 'ولي أمر',
      parentPhone: '+9665', status: 'pending',
      submittedAt: new Date(),
    },
  ));
});

test('HP: super-admin reads any tenant', async () => {
  await assertSucceeds(getDoc(
    doc(dbAs(UIDS.superAdmin), `nurseries/${NID_B}`),
  ));
});

(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: RULES, host: '127.0.0.1', port: 8080 },
  });

  await seed();

  let passed = 0, failed = 0;
  const failures = [];
  for (const t of tests) {
    try {
      await t.fn();
      console.log(`  ✓ ${t.name}`);
      passed++;
    } catch (e) {
      console.log(`  ✗ ${t.name}\n      ${e.message.split('\n')[0]}`);
      failures.push(t.name);
      failed++;
    }
    await testEnv.clearFirestore();
    await seed();
  }

  await testEnv.cleanup();

  console.log(`\n${passed} passed, ${failed} failed (of ${tests.length})`);
  if (failed > 0) {
    console.log('\nFailures:');
    failures.forEach((f) => console.log(`  - ${f}`));
    process.exit(1);
  }
})().catch((e) => { console.error(e); process.exit(1); });
