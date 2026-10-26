const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc } = require('firebase/firestore');
const fs = require('fs');
const path = require('path');
const test = require('node:test');
const assert = require('node:assert');

let testEnv;

test.before(async () => {
  const rulesPath = path.resolve(__dirname, '../firestore.rules');
  const rules = fs.readFileSync(rulesPath, 'utf8');

  testEnv = await initializeTestEnvironment({
    projectId: 'demo-cilalutask-test',
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: rules,
    },
  });

  // Seed initial test data with security rules disabled
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    // 1. Company CILALU-88
    await setDoc(doc(db, 'companies', 'CILALU-88'), {
      name: 'PT Cilalu Mandiri',
      code: 'CILALU-88',
      adminUid: 'admin_sarah',
      adminEmail: 'sarah@cilalu.id',
    });

    // 2. Member of CILALU-88
    await setDoc(doc(db, 'companies/CILALU-88/members', 'karyawan_budi'), {
      name: 'Budi Santoso',
      role: 'user',
      division: 'Operasional',
      email: 'budi@cilalu.id',
    });

    // 3. Existing Task in CILALU-88
    await setDoc(doc(db, 'companies/CILALU-88/tasks', 'task-1'), {
      title: 'Periksa Inverter Solar Panel',
      assigneeId: 'karyawan_budi',
      status: 'inProgress',
      progressPercent: 50,
    });

    // 4. Existing SOP in CILALU-88
    await setDoc(doc(db, 'companies/CILALU-88/sops', 'sop-1'), {
      title: 'SOP Keselamatan Kerja Listrik',
      division: 'Operasional',
    });

    // 5. Existing Join Request
    await setDoc(doc(db, 'companies/CILALU-88/join_requests', 'req-pending'), {
      userId: 'prospective_andi',
      userName: 'Andi Pratama',
      userEmail: 'andi@gmail.com',
      status: 'pending',
      division: 'Teknik',
      role: 'Teknisi',
    });
  });
});

test.after(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// 1. UNAUTHENTICATED TESTS
// ─────────────────────────────────────────────────────────────────────────────
test('1. Unauthenticated users cannot read or write private company data', async () => {
  const unauthed = testEnv.unauthenticatedContext().firestore();

  // Denied reading task
  await assertFails(getDoc(doc(unauthed, 'companies/CILALU-88/tasks', 'task-1')));

  // Denied reading SOP
  await assertFails(getDoc(doc(unauthed, 'companies/CILALU-88/sops', 'sop-1')));

  // Denied writing task
  await assertFails(
    setDoc(doc(unauthed, 'companies/CILALU-88/tasks', 'unauth-task'), {
      title: 'Hacked Task',
    })
  );

  // Denied creating company
  await assertFails(
    setDoc(doc(unauthed, 'companies', 'HACK-99'), {
      name: 'Hacked PT',
    })
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// 2. MULTI-TENANT ISOLATION TESTS
// ─────────────────────────────────────────────────────────────────────────────
test('2. Multi-tenant isolation: User from Company B cannot access Company A data', async () => {
  const outsider = testEnv.authenticatedContext('user_company_b').firestore();
  const member = testEnv.authenticatedContext('karyawan_budi').firestore();

  // Outsider cannot read CILALU-88 tasks or SOPs
  await assertFails(getDoc(doc(outsider, 'companies/CILALU-88/tasks', 'task-1')));
  await assertFails(getDoc(doc(outsider, 'companies/CILALU-88/sops', 'sop-1')));
  await assertFails(getDoc(doc(outsider, 'companies/CILALU-88/members', 'karyawan_budi')));

  // Legitimate member of CILALU-88 CAN read tasks and SOPs
  await assertSucceeds(getDoc(doc(member, 'companies/CILALU-88/tasks', 'task-1')));
  await assertSucceeds(getDoc(doc(member, 'companies/CILALU-88/sops', 'sop-1')));
  await assertSucceeds(getDoc(doc(member, 'companies/CILALU-88/members', 'karyawan_budi')));
});

// ─────────────────────────────────────────────────────────────────────────────
// 3. ROLE-BASED ACCESS CONTROL (RBAC) TESTS
// ─────────────────────────────────────────────────────────────────────────────
test('3. RBAC: Non-admin member cannot create tasks or modify SOPs', async () => {
  const member = testEnv.authenticatedContext('karyawan_budi').firestore();
  const admin = testEnv.authenticatedContext('admin_sarah').firestore();

  // Regular member CANNOT create task
  await assertFails(
    setDoc(doc(member, 'companies/CILALU-88/tasks', 'task-unauthorized'), {
      title: 'Unauthorized Task by User',
    })
  );

  // Admin CAN create task
  await assertSucceeds(
    setDoc(doc(admin, 'companies/CILALU-88/tasks', 'task-admin-created'), {
      title: 'Approved Task by Admin',
    })
  );

  // Regular member CANNOT create or update SOP
  await assertFails(
    setDoc(doc(member, 'companies/CILALU-88/sops', 'sop-unauthorized'), {
      title: 'Tampered SOP',
    })
  );

  // Regular member CAN update progress on existing task
  await assertSucceeds(
    updateDoc(doc(member, 'companies/CILALU-88/tasks', 'task-1'), {
      progressPercent: 75,
      status: 'inProgress',
    })
  );
});

test('4. Privilege escalation prevented: Member cannot change own role to admin', async () => {
  const member = testEnv.authenticatedContext('karyawan_budi').firestore();

  // Member attempts to elevate role from 'user' to 'admin'
  await assertFails(
    updateDoc(doc(member, 'companies/CILALU-88/members', 'karyawan_budi'), {
      role: 'admin',
    })
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// 4. ZERO-PASSWORD CONSTRAINT TESTS
// ─────────────────────────────────────────────────────────────────────────────
test('5. Zero-Password constraint: Payload containing password fields is rejected', async () => {
  const admin = testEnv.authenticatedContext('admin_sarah').firestore();
  const newUser = testEnv.authenticatedContext('new_user_uid').firestore();

  // Attempting to create company with adminPassword
  await assertFails(
    setDoc(doc(newUser, 'companies', 'TEST-01'), {
      name: 'Leaky PT',
      adminUid: 'new_user_uid',
      adminPassword: 'plaintext-secret',
    })
  );

  // Attempting to create member with password
  await assertFails(
    setDoc(doc(admin, 'companies/CILALU-88/members', 'new_emp'), {
      name: 'New Emp',
      role: 'user',
      password: 'password123',
    })
  );

  // Attempting to create join request with userPassword
  await assertFails(
    setDoc(doc(newUser, 'companies/CILALU-88/join_requests', 'req-bad'), {
      userId: 'new_user_uid',
      status: 'pending',
      userPassword: 'secret-password',
    })
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// 5. JOIN REQUEST LIFECYCLE TESTS
// ─────────────────────────────────────────────────────────────────────────────
test('6. Join request lifecycle: User submits pending, only admin can accept', async () => {
  const prospectiveUser = testEnv.authenticatedContext('prospective_andi').firestore();
  const attacker = testEnv.authenticatedContext('attacker_uid').firestore();
  const admin = testEnv.authenticatedContext('admin_sarah').firestore();

  // User submits their own pending request without password
  await assertSucceeds(
    setDoc(doc(prospectiveUser, 'companies/CILALU-88/join_requests', 'req-valid'), {
      userId: 'prospective_andi',
      status: 'pending',
      userName: 'Andi Pratama',
      division: 'Operasional',
    })
  );

  // Attacker tries to submit request impersonating another user
  await assertFails(
    setDoc(doc(attacker, 'companies/CILALU-88/join_requests', 'req-spoof'), {
      userId: 'prospective_andi',
      status: 'pending',
      userName: 'Fake Andi',
    })
  );

  // Attacker tries to directly accept a join request
  await assertFails(
    updateDoc(doc(attacker, 'companies/CILALU-88/join_requests', 'req-pending'), {
      status: 'accepted',
    })
  );

  // Admin approves join request
  await assertSucceeds(
    updateDoc(doc(admin, 'companies/CILALU-88/join_requests', 'req-pending'), {
      status: 'accepted',
    })
  );
});
