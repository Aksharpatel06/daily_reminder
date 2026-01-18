importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

const firebaseConfig = {
  apiKey: "AIzaSyAvs0Zckq5gJe_Fmbt7G6zzEssn4LZr4Io",
  authDomain: "daily-vachan-62464.firebaseapp.com",
  projectId: "daily-vachan-62464",
  storageBucket: "daily-vachan-62464.firebasestorage.app",
  messagingSenderId: "612109757208",
  appId: "1:612109757208:web:8f5cda756779f02a290c6d",
  measurementId: "G-662FQC960Z"
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

messaging.onBackgroundMessage((message) => {
  console.log("onBackgroundMessage", message);
});
