// Background push runs here, not in Dart; the SDK version below is pinned by hand.
// After a flutter pub upgrade, check it against firebase_core_web's supportedFirebaseJsSdkVersion.
importScripts("https://www.gstatic.com/firebasejs/12.17.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/12.17.0/firebase-messaging-compat.js");

// Duplicated from lib/firebase_options.dart, since this file cannot import it; values here are public.
// TODO(vikas): replace the API key placeholder here and in firebase_options.dart.
firebase.initializeApp({
  apiKey: "PASTE_FULL_API_KEY",
  authDomain: "client-website-test-prod.firebaseapp.com",
  projectId: "client-website-test-prod",
  storageBucket: "client-website-test-prod.firebasestorage.app",
  messagingSenderId: "15198833110",
  appId: "1:15198833110:web:a4192fa474e8f235aac3a7",
});

// The worker only has to expose messaging; the SDK draws notification payloads itself.
firebase.messaging();
