const admin = require('firebase-admin');
const express = require('express');

// Initialize Express (required for Render/Fly health checks and port binding)
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.send('Notification Bridge is Running 🚀');
});

// Initialize Firebase Admin
// Checks for Environment Variable first (Production), then local key (Development)
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const serviceAccount = JSON.parse(Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT, 'base64').toString('ascii'));
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log("Firebase Initialized with ENV variable");
} else {
    try {
        const serviceAccount = require('./assignmates-app-firebase-adminsdk-fbsvc-6ec1bc98a3.json');
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log("Firebase Initialized with local file");
    } catch (e) {
        console.error("FATAL: No Firebase Service Account found. Set FIREBASE_SERVICE_ACCOUNT env var or add service-account.json");
        process.exit(1);
    }
}

const db = admin.firestore();

// --- Notification Listener ---
console.log("Starting Firestore Listener...");

// Listen to 'notifications' collection
// We assume documents have { targetUserId, title, body, status }
// We only process if status is NOT 'sent'
const unsubscribe = db.collection('notifications')
    .where('status', '!=', 'sent')
    .onSnapshot(async (snapshot) => {
        if (snapshot.empty) {
            return;
        }

        // Process each change
        for (const change of snapshot.docChanges()) {
            if (change.type === 'added' || change.type === 'modified') {
                const doc = change.doc;
                const data = doc.data();

                // Double check status to be safe
                if (data.status === 'sent') continue;

                const notificationId = doc.id;
                console.log(`Processing notification: ${notificationId} for user: ${data.targetUserId}`);

                await sendPushNotification(notificationId, data);
            }
        }
    }, (error) => {
        console.error("Firestore Listener Error:", error);
    });

// Core Logic (adapted from original Cloud Function)
async function sendPushNotification(docId, data) {
    const targetUserId = data.targetUserId;
    const title = data.title;
    const body = data.body;
    let tokens = [];

    try {
        if (targetUserId === 'admin') {
            // Fetch all admin tokens
            const adminsSnapshot = await db.collection('users')
                .where('role', '==', 'admin')
                .get();

            adminsSnapshot.forEach(doc => {
                const userData = doc.data();
                if (userData.fcmToken) {
                    tokens.push(userData.fcmToken);
                }
            });
        } else {
            // Fetch specific user token
            const userDoc = await db.collection('users')
                .doc(targetUserId)
                .get();

            if (userDoc.exists && userDoc.data().fcmToken) {
                tokens.push(userDoc.data().fcmToken);
            }
        }

        if (tokens.length === 0) {
            console.log(`No tokens found for user ${targetUserId}. Marking as failed.`);
            // Mark as 'failed' so we don't retry forever, or just 'sent' to ignore it. 
            // Let's mark as 'sent' (or 'no_token') to stop processing.
            await db.collection('notifications').doc(docId).update({ status: 'sent', sentAt: admin.firestore.FieldValue.serverTimestamp(), note: 'No tokens found' });
            return;
        }

        // Construct FCM message
        const message = {
            notification: {
                title: title || 'New Notification',
                body: body || '',
            },
            data: {
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                notificationId: docId,
                ...data.payload // Include any extra payload if present
            },
            android: {
                notification: {
                    channelId: 'order_updates_channel',
                    priority: 'high',
                    defaultSound: true,
                }
            },
            tokens: tokens,
        };

        // Send via FCM
        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(`Successfully sent ${response.successCount} messages for notification ${docId}`);

        // Mark as SENT to prevent re-processing
        await db.collection('notifications').doc(docId).update({
            status: 'sent',
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            successCount: response.successCount,
            failureCount: response.failureCount
        });

    } catch (error) {
        console.error(`Error sending notification ${docId}:`, error);
        // Optional: Implement retry logic or dead-letter queue here if needed.
        // For now, we won't mark as 'sent' so it might retry on restart, OR we could mark 'error'.
        // To be safe and avoid infinite loops on bad data, maybe mark error?
        // Let's leave it unprocessed for retry, but log heavily.
    }
}

// Start Server
app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
});
