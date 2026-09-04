import admin from 'firebase-admin';
import { readFileSync } from 'fs';

let firebaseApp = null;
try {
  const serviceAccount = JSON.parse(
    readFileSync('./firebase-service-account.json', 'utf8')
  );
  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log('Firebase Admin SDK initialized successfully!');
} catch (e) {
  console.log(
    'Firebase Admin SDK initialization skipped or failed (service account key missing).\n' +
    'Push notifications will log to the console for testing.'
  );
}

export async function sendMulticastNotification({ tokens, title, body, data }) {
  if (firebaseApp) {
    const messaging = admin.messaging();
    const result = await messaging.sendEachForMulticast({
      tokens,
      notification: { title, body },
      // Omitted when empty: FCM rejects a data block whose values are not
      // all strings, and an empty object is pointless anyway.
      ...(data && Object.keys(data).length ? { data } : {})
    });
    return {
      success: true,
      realFcm: true,
      message: `Sent to ${result.successCount} devices, failed for ${result.failureCount}`
    };
  } else {
    console.log('Firebase Mock Mode: Output logged to server console.');
    return {
      success: true,
      realFcm: false,
      message: `(Mock Mode) Simulated push logged to console for ${tokens.length} devices.`
    };
  }
}
