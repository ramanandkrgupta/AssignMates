const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Triggers a push notification whenever a new document is added to the 'notifications' collection.
 */
exports.sendPushNotification = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snapshot, context) => {
        const data = snapshot.data();
        const targetUserId = data.targetUserId;
        const title = data.title;
        const body = data.body;

        console.log(`Processing notification for: ${targetUserId}`);

        try {
            let tokens = [];

            if (targetUserId === 'admin') {
                // Fetch all admin tokens
                const adminsSnapshot = await admin.firestore()
                    .collection('users')
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
                const userDoc = await admin.firestore()
                    .collection('users')
                    .doc(targetUserId)
                    .get();

                if (userDoc.exists && userDoc.data().fcmToken) {
                    tokens.push(userDoc.data().fcmToken);
                }
            }

            if (tokens.length === 0) {
                console.log('No FCM tokens found for target.');
                return null;
            }

            // Construct FCM message
            const message = {
                notification: {
                    title: title,
                    body: body,
                },
                // Add data payload for background handling if needed
                data: {
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    notificationId: context.params.notificationId,
                },
                tokens: tokens,
            };

            // Send via FCM
            const response = await admin.messaging().sendEachForMulticast(message);
            console.log(`Successfully sent ${response.successCount} messages.`);
            return null;

        } catch (error) {
            console.error('Error sending push notification:', error);
            return null;
        }
    });
