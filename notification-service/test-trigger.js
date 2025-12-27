const admin = require('firebase-admin');

// 1. Initialize Firebase (Start same as index.js)
try {
    const serviceAccount = require('./assignmates-app-firebase-adminsdk-fbsvc-6ec1bc98a3.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log("Firebase Initialized for Test Script");
} catch (e) {
    console.error("Error initializing:", e);
    process.exit(1);
}

const db = admin.firestore();

async function triggerTest() {
    try {
        console.log("Creating test notification...");

        // 2. Add a dummy notification
        const res = await db.collection('notifications').add({
            targetUserId: 'admin', // Targeting admin role to be safe, or use a specific UID if you have one
            title: 'Test Notification 🔔',
            body: 'This is a test from your local Node.js bridge!',
            status: 'pending',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`✅ Test Notification Added! ID: ${res.id}`);
        console.log("👉 CHECK YOUR 'node index' TERMINAL NOW to see if it picked it up.");

    } catch (error) {
        console.error("Error creating document:", error);
    }
}

triggerTest();
