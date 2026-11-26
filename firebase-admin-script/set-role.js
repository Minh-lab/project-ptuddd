const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const serviceAccount = require('./serviceAccountKey.json');
const expectedProjectId = 'notesmarts-f4b02';

if (serviceAccount.project_id !== expectedProjectId) {
  throw new Error(
    `Sai Firebase project trong serviceAccountKey.json. Mong đợi ${expectedProjectId}, nhận được ${serviceAccount.project_id}.`,
  );
}

// Khởi tạo Firebase Admin
initializeApp({
  credential: cert(serviceAccount),
});

async function main() {
  const auth = getAuth();
  const testAccounts = [
    { uid: 'NZ5xOJkqT0UyVWFdELQv0thji1I2' },
    { email: 'nlien2k5@gmail.com' },
  ];

  for (const account of testAccounts) {
    const user = account.uid
      ? await auth.getUser(account.uid)
      : await auth.getUserByEmail(account.email);
    const existingClaims = user.customClaims || {};

    await auth.setCustomUserClaims(user.uid, {
      ...existingClaims,
      role: 'authenticated',
    });

    const updatedUser = await auth.getUser(user.uid);
    if (updatedUser.customClaims?.role !== 'authenticated') {
      throw new Error(`Không xác minh được role cho UID ${user.uid}.`);
    }

    console.log(
      `Đã xác minh role cho ${updatedUser.email || updatedUser.uid}`,
    );
    console.log('UID:', updatedUser.uid);
    console.log('Role:', updatedUser.customClaims.role);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Lỗi:', error);
    process.exit(1);
  });