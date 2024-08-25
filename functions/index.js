const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendImmediateAlarmNotification = functions.firestore
    .document('Alarm/{alarmId}')
    .onCreate(async (snap, context) => {
        const alarm = snap.data();

        console.log(`Alarm created with ID: ${context.params.alarmId}`);
        console.log(`Alarm data: ${JSON.stringify(alarm)}`);
        
        try {
            // Fetch participants and their FCM tokens
            const tokens = [];
            for (const [participantId, participantInfo] of Object.entries(alarm.participants)) {
   		console.log(`Participant ID: ${participantId}`);
		if (alarm.creatorID != participantId) {
		    const participantSnap = await admin.firestore().collection('UserData').doc(participantId).get();
                    const participantData = participantSnap.data();
                    if (participantData && participantData.fcmToken) {
                        tokens.push(participantData.fcmToken);
                        console.log(`Token found for participant ID: ${participantId}`);
                    } else {
                        console.log(`No token found for participant ID: ${participantId}`);
                    }
		}
	    }
            if (tokens.length > 0) {
                // Send the notification with custom sound and data
		const message = {
                    notification: {
                        title: 'Alarm Notification',
                        body: `You have an alarm for activity: ${alarm.activityName}`,
                    },
                    data: {
			id: `${context.params.alarmId}`,
			title: 'Alarm Notification',
			body: `You have an alarm for activity: ${alarm.activityName}`,
                        activityId: `${alarm.activityId}`,
			activityName: `${alarm.activityName}`,
			alarmTime: new Date(alarm.time._seconds * 1000).toISOString(),
                        sound: `${alarm.sound}`,
			repeat: `${alarm.repeatInterval}`,
                        showAlert: "false" // Custom flag to distinguish data-only messages
                    },
		    apns: {
                        payload: {
                            aps: {
                                category: 'alarm', // Category for iOS
                                'content-available': 1, // Correctly use quotes around keys with hyphens
                                'mutable-content': 1 // Allow modification of content on client-side
                            },
                        },
                    },
                    tokens: tokens,
                };
                const response = await admin.messaging().sendMulticast(message);
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        console.error(`Failed to send to ${tokens[idx]}: ${resp.error}`);
                    }
                });
                console.log('Successfully sent message:', response);
            } else {
                console.log('No tokens found');
            }
        } catch (error) {
            console.error('Error sending notification:', error);
        }
    });

