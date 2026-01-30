// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyDbtmGqg5yxs3l7S03RaikYK0Zq1y1ySaI",
  authDomain: "rivl-3bf21.firebaseapp.com",
  projectId: "rivl-3bf21",
  storageBucket: "rivl-3bf21.firebasestorage.app",
  messagingSenderId: "868172313930",
  appId: "1:868172313930:web:893cf08d511b7c9ec23db3",
  measurementId: "G-LGD052GJ5K"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);

export { app, analytics, firebaseConfig };
