// Shows push notifications while the app's tab is closed or in the
// background. Firebase looks for this file at the site root by name.
//
// The version matches the Firebase JS SDK that firebase_core_web loads
// (firebase_sdk_version.dart). The values below are the web app's public
// Firebase config, the same as in lib/firebase_options.dart: not secrets.
importScripts('https://www.gstatic.com/firebasejs/12.18.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.18.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDWAl3Hk_uHb2HboCOxoVfhr_bJUTiGY0g',
  appId: '1:67344886415:web:3a274abf20fdb03760defa',
  messagingSenderId: '67344886415',
  projectId: 'genie-a0c66',
  authDomain: 'genie-a0c66.firebaseapp.com',
  storageBucket: 'genie-a0c66.firebasestorage.app',
});

// A push with a notification is shown by Firebase itself; clicking it opens
// or focuses the app. Silent pushes (Android-only call rings) never reach a
// browser, so nothing more is needed here.
firebase.messaging();
