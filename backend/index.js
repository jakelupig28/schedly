require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { auth, db } = require('./firebase');

const app = express();
const PORT = process.env.PORT || 5000;

// Enable CORS so the Flutter app (and other clients) can access this server
app.use(cors());
// Parse incoming JSON requests
app.use(express.json());

/**
 * Express Middleware to authenticate incoming requests via Firebase Auth ID Tokens.
 * Expects header: "Authorization: Bearer <Firebase_ID_Token>"
 */
async function authenticateUser(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ 
      error: 'Unauthorized: Missing or malformed Authorization header' 
    });
  }

  const idToken = authHeader.split(' ')[1];

  try {
    // Verify the ID Token using Firebase Admin SDK
    const decodedToken = await auth.verifyIdToken(idToken);
    req.user = decodedToken; // Attach decoded token (contains uid, email, etc.) to request
    next();
  } catch (error) {
    console.error('Error verifying Firebase ID Token:', error);
    return res.status(401).json({ 
      error: 'Unauthorized: Invalid token',
      details: error.message 
    });
  }
}

// Public Endpoint: Health check / Welcome route
app.get('/', (req, res) => {
  res.json({
    message: '🚀 Schedly Backend is running!',
    firebaseConnected: !!db && !!auth,
    timestamp: new Date().toISOString()
  });
});

/**
 * Protected Endpoint: Save user schedule data to Firebase Realtime Database
 * POST /api/schedules
 */
app.post('/api/schedules', authenticateUser, async (req, res) => {
  const { schedule } = req.body;
  const uid = req.user.uid;

  if (!schedule) {
    return res.status(400).json({ error: 'Schedule data is required' });
  }

  try {
    // Save to Realtime Database at path: /users/<uid>/schedules
    const scheduleRef = db.ref(`users/${uid}/schedules`);
    await scheduleRef.set({
      ...schedule,
      updatedAt: new Date().toISOString()
    });

    res.json({
      success: true,
      message: 'Schedule successfully saved to Realtime Database.'
    });
  } catch (error) {
    console.error('Database write error:', error);
    res.status(500).json({ 
      error: 'Failed to save schedule data to database',
      details: error.message 
    });
  }
});

/**
 * Protected Endpoint: Retrieve user schedule data from Firebase Realtime Database
 * GET /api/schedules
 */
app.get('/api/schedules', authenticateUser, async (req, res) => {
  const uid = req.user.uid;

  try {
    // Fetch from Realtime Database at path: /users/<uid>/schedules
    const scheduleRef = db.ref(`users/${uid}/schedules`);
    const snapshot = await scheduleRef.once('value');
    const schedule = snapshot.val();

    if (!schedule) {
      return res.status(404).json({ message: 'No schedule found for this user' });
    }

    res.json({
      success: true,
      schedule
    });
  } catch (error) {
    console.error('Database read error:', error);
    res.status(500).json({ 
      error: 'Failed to retrieve schedule data from database',
      details: error.message 
    });
  }
});

/**
 * Protected Endpoint: Save/Update user profile data in Firebase Realtime Database
 * POST /api/profile
 */
app.post('/api/profile', authenticateUser, async (req, res) => {
  const { profile } = req.body;
  const uid = req.user.uid;

  if (!profile) {
    return res.status(400).json({ error: 'Profile data is required' });
  }

  try {
    // Save to Realtime Database at path: /users/<uid>
    const userRef = db.ref(`users/${uid}`);
    await userRef.update({
      ...profile,
      uid,
      updatedAt: new Date().toISOString()
    });

    res.json({
      success: true,
      message: 'Profile successfully saved to Firebase Realtime Database.'
    });
  } catch (error) {
    console.error('Database write error:', error);
    res.status(500).json({ 
      error: 'Failed to save profile data to database',
      details: error.message 
    });
  }
});

/**
 * Protected Endpoint: Retrieve user profile data from Firebase Realtime Database
 * GET /api/profile
 */
app.get('/api/profile', authenticateUser, async (req, res) => {
  const uid = req.user.uid;

  try {
    // Fetch from Realtime Database at path: /users/<uid>
    const userRef = db.ref(`users/${uid}`);
    const snapshot = await userRef.once('value');
    const profile = snapshot.val();

    if (!profile) {
      return res.status(404).json({ message: 'No profile found for this user' });
    }

    res.json({
      success: true,
      profile
    });
  } catch (error) {
    console.error('Database read error:', error);
    res.status(500).json({ 
      error: 'Failed to retrieve profile data from database',
      details: error.message 
    });
  }
});

app.listen(PORT, () => {
  console.log(`=================================================`);
  console.log(`🚀 Schedly Server running on port ${PORT}`);
  console.log(`👉 API endpoint: http://localhost:${PORT}/`);
  console.log(`=================================================`);
});
