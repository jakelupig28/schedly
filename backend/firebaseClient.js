const { initializeApp } = require("firebase/app");

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyDyUpEJhmf-KjxiGI4j_AFQasJRrHxXKT8",
  authDomain: "schedly-751cb.firebaseapp.com",
  projectId: "schedly-751cb",
  storageBucket: "schedly-751cb.firebasestorage.app",
  messagingSenderId: "832199980646",
  appId: "1:832199980646:web:68addff71649ec141adfa7",
  measurementId: "G-RTDY3RRFYB"
};

// Initialize Firebase Client SDK
const app = initializeApp(firebaseConfig);
console.log("[Firebase Client] Client SDK initialized with project ID:", firebaseConfig.projectId);

// Initialize Analytics (guarded since Node.js is a non-browser environment)
let analytics;
if (typeof window !== 'undefined') {
  try {
    const { getAnalytics } = require("firebase/analytics");
    analytics = getAnalytics(app);
    console.log("[Firebase Client] Analytics initialized successfully!");
  } catch (error) {
    console.error("[Firebase Client] Failed to initialize analytics:", error);
  }
} else {
  console.log("[Firebase Client] Running in Node.js (Analytics initialization skipped).");
}

module.exports = {
  app,
  analytics,
  firebaseConfig
};
