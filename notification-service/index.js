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


// --- Request Listener (Timeline Logic) ---
console.log("Starting Requests Listener...");

// Listen to 'requests' collection for timeline updates
const unsubscribeRequests = db.collection('requests')
    .onSnapshot(async (snapshot) => {
        for (const change of snapshot.docChanges()) {
            // Only care about Added or Modified
            if (change.type === 'added' || change.type === 'modified') {
                const doc = change.doc;
                const data = doc.data();
                const requestId = doc.id;
                const timeline = data.timeline || [];
                const studentId = data.studentId;

                let needsUpdate = false;
                const updatedTimeline = matchTimeline(timeline); // Create copy

                for (let i = 0; i < updatedTimeline.length; i++) {
                    const step = updatedTimeline[i];
                    // Ensure notificationsSent exists
                    if (!step.notificationsSent) step.notificationsSent = {};

                    // 1. Notify Admin
                    if (step.notificationsSent['admin'] === false) {
                        console.log(`[Request Watcher] New Step '${step.title}' in Request ${requestId} -> Notify Admin`);

                        await sendPushNotificationToTarget(
                            'admin',
                            `New Request Update: ${step.title}`,
                            `Request #${requestId}: ${step.description}`,
                            'request_update',
                            { requestId: requestId }
                        );

                        step.notificationsSent['admin'] = true;
                        needsUpdate = true;
                    }

                    // 2. Notify Student
                    if (step.notificationsSent['student'] === false) {
                        console.log(`[Request Watcher] New Step '${step.title}' in Request ${requestId} -> Notify Student ${studentId}`);

                        await sendPushNotificationToTarget(
                            studentId,
                            `Order Update: ${step.title}`,
                            step.description,
                            'request_update',
                            { requestId: requestId }
                        );

                        step.notificationsSent['student'] = true;
                        needsUpdate = true;
                    }

                    // 3. Notify Writer (if assigned)
                    if (step.notificationsSent['writer'] === false && data.assignedWriterId) {
                        console.log(`[Request Watcher] New Step '${step.title}' in Request ${requestId} -> Notify Writer ${data.assignedWriterId}`);

                        await sendPushNotificationToTarget(
                            data.assignedWriterId,
                            `Assignment Update: ${step.title}`,
                            step.description,
                            'request_update',
                            { requestId: requestId }
                        );

                        step.notificationsSent['writer'] = true;
                        needsUpdate = true;
                    }
                }

                if (needsUpdate) {
                    console.log(`[Request Watcher] Updating timeline for Request ${requestId} to mark notifications as sent.`);
                    await db.collection('requests').doc(requestId).update({
                        timeline: updatedTimeline
                    });
                }
            }
        }
    }, (error) => {
        console.error("Firestore Requests Listener Error:", error);
    });

// Helper for deep copy to avoid mutations issues
function matchTimeline(timeline) {
    return timeline.map(step => ({
        ...step,
        notificationsSent: { ...(step.notificationsSent || {}) }
    }));
}


// Refactored helper to send notification directly without creating a 'notification' doc first
// (or we can create one if we want audit trail, but user asked for logic here)
// Actually, creating a notification doc is good for history. Let's reuse existing flow or just send directly?
// User said "if notification not sent then sent to admin...".
// Existing flow creates a doc, then that doc triggers send. 
// If we send DIRECTLY here, we skip the 'notifications' collection doc creation (or create it as 'sent').
// Let's send DIRECTLY to be fast and simple, but creating a doc in 'notifications' collection is better for "History" screen.
// So let's create a notification doc as "sent" or "pending"?
// If we create it as "pending", the OTHER listener will pick it up and send it. DOUBLE SEND?
// NO.
// Option A: Create doc in 'notifications' keys status='pending'. Let the other listener handle it.
// Option B: Send directly.
// The user wants backend to handle it.
// I will reuse `sendPushNotification` logic but adapted.
// Actually, to show in "Notification History Screen" for the user, we MUST create a document in `notifications` collection.
// So:
// 1. Check logic.
// 2. Create `notifications` doc.
// 3. Mark timeline as sent.
// 4. The `notifications` listener will pick up the new doc and send the push.
// WAIT. If I create a notification doc, simply creating it is enough?
// Yes.
// BUT, the existing listener watches 'notifications'.
// So if I insert a doc into 'notifications', the existing listener will fire and send the push.
// So I just need to insert into `notifications`.

async function sendPushNotificationToTarget(targetUserId, title, body, type, payload) {
    // Just create the notification document. The existing listener will handle the actual FCM sending.
    // This ensures it appears in the User's notification history too!
    await db.collection('notifications').add({
        targetUserId: targetUserId,
        title: title,
        body: body,
        status: 'pending', // <--- This triggers the other listener!
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        type: type,
        payload: payload,
        isRead: false
    });
}

// Core Logic (adapted from original Cloud Function)
// Core Logic (adapted from original Cloud Function)
async function sendPushNotification(docId, data) {
    const targetUserId = data.targetUserId;
    const title = data.title;
    const body = data.body;
    let tokens = [];

    // NOTIFICATION STRATEGY:
    // 1. Admin: Send to ALL users with role='admin'
    // 2. Individual (Student/Writer): Send to specific fcmToken stored in user profile
    //
    // EVENTS HANDLED (Triggered by Frontend creating 'notifications' doc):
    // - New Order Request -> Notify Admin
    // - Writer Assigned -> Notify Student & Writer
    // - Status Change (e.g. 'Writing started') -> Notify Student
    // - Payment Required -> Notify Student
    // - Payment Received -> Notify Admin

    try {
        if (targetUserId === 'admin') {
            // Case 1: Notify All Admins (e.g. New Order Received, Payment Received)
            console.log(`[Notification] Broadcasting to ADMINS: ${title}`);
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
            // Case 2: Notify Specific User (Student or Writer)
            // e.g. "Writer Assigned", "Order Completed", "Please Pay"
            console.log(`[Notification] Sending to USER ${targetUserId}: ${title}`);
            const userDoc = await db.collection('users')
                .doc(targetUserId)
                .get();

            if (userDoc.exists && userDoc.data().fcmToken) {
                tokens.push(userDoc.data().fcmToken);
            }
        }

        if (tokens.length === 0) {
            console.log(`[Notification] No tokens found for user ${targetUserId}. Marking as failed/skipped.`);
            // Mark as 'sent' with note to stop retry loop
            await db.collection('notifications').doc(docId).update({
                status: 'sent',
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                note: 'No tokens found (User has not logged in or granted permission)'
            });
            return;
        }

        // Construct FCM message
        // This structure works for both Android and iOS via Flutter Local Notifications
        const message = {
            notification: {
                title: title || 'Update from AssignMates',
                body: body || 'You have a new update regarding your assignment.',
            },
            data: {
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                notificationId: docId,
                targetUserId: targetUserId,
                type: data.type || 'general', // e.g. 'order_update', 'payment'
                ...data.payload // specific IDs like requestId
            },
            android: {
                notification: {
                    channelId: 'order_updates_channel', // Must match Flutter channel ID
                    priority: 'high',
                    defaultSound: true,
                    visibility: 'public',
                }
            },
            tokens: tokens, // Multicast processing
        };

        // Send via FCM
        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(`[Notification] Success: ${response.successCount}, Failed: ${response.failureCount} for ID: ${docId}`);

        // Mark as SENT
        await db.collection('notifications').doc(docId).update({
            status: 'sent',
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            successCount: response.successCount,
            failureCount: response.failureCount
        });

    } catch (error) {
        console.error(`[Notification] FATAL ERROR for ${docId}:`, error);
        // Error handling: We leave status as != 'sent' so it might retry, 
        // OR we can mark as 'error' if we want to stop loops.
        // For now, logged error is enough.
    }
}

// Start Server
app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
});
