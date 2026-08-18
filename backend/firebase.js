require('dotenv').config();
const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

/**
 * Initializes the Firebase Admin SDK.
 * Supports loading credentials from a service account JSON file,
 * falling back to application default credentials, or running in emulator mode.
 */
function initializeFirebase() {
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_KEY_PATH;
  const databaseUrl = process.env.FIREBASE_DATABASE_URL;
  const projectId = process.env.FIREBASE_PROJECT_ID;

  const options = {};

  if (databaseUrl) {
    options.databaseURL = databaseUrl;
  }

  // 1. Try to initialize using service account file if path is provided and file exists
  if (serviceAccountPath) {
    const resolvedPath = path.isAbsolute(serviceAccountPath)
      ? serviceAccountPath
      : path.join(__dirname, serviceAccountPath);

    if (fs.existsSync(resolvedPath)) {
      console.log(`[Firebase] Initializing with service account key from: ${resolvedPath}`);
      options.credential = admin.credential.cert(require(resolvedPath));
    } else {
      console.warn(`[Firebase] Service account file not found at ${resolvedPath}. Attempting default initialization.`);
    }
  }

  // 2. If no credentials specified yet, use application default credentials or project ID
  if (!options.credential) {
    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      console.log('[Firebase] Initializing using GOOGLE_APPLICATION_CREDENTIALS...');
      options.credential = admin.credential.applicationDefault();
    } else if (projectId) {
      console.log(`[Firebase] Initializing in project: ${projectId} (without explicit credentials)...`);
      options.projectId = projectId;
    } else {
      console.error(
        '[Firebase Error] Firebase Admin SDK could not be initialized.\n' +
        'Please download your service account key JSON from the Firebase Console,\n' +
        'place it in the backend folder, and configure FIREBASE_SERVICE_ACCOUNT_KEY_PATH in a .env file.'
      );
      process.exit(1);
    }
  }

  // Initialize the admin app
  admin.initializeApp(options);
  console.log('[Firebase] Admin SDK successfully initialized!');

  return {
    admin,
    auth: admin.auth(),
    db: admin.database(),
  };
}

const firebaseServices = initializeFirebase();

module.exports = firebaseServices;
