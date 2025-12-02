const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function triggered when a new SOS alert is created
 * Sends push notifications to all NGO members
 */
exports.onSOSCreated = functions.firestore
    .document("sos_alerts/{sosId}")
    .onCreate(async (snap, context) => {
      const sosData = snap.data();
      const sosId = context.params.sosId;

      console.log("New SOS Alert created:", sosId, sosData);

      try {
        // Get all NGO FCM tokens
        const tokensSnapshot = await db.collection("ngo_fcm_tokens").get();

        if (tokensSnapshot.empty) {
          console.log("No NGO tokens found");
          return null;
        }

        const tokens = [];
        tokensSnapshot.forEach((doc) => {
          const token = doc.data().fcmToken;
          if (token) {
            tokens.push(token);
          }
        });

        if (tokens.length === 0) {
          console.log("No valid tokens found");
          return null;
        }

        console.log(`Sending notification to ${tokens.length} devices`);

        // Build notification payload
        const volunteerName = sosData.odname || "Unknown";
        const emergencyType = sosData.emergencyType || "Emergency";
        const address = sosData.address || "Unknown location";
        const volunteerPhone = sosData.volunteerPhone || "";

        const message = {
          notification: {
            title: "🚨 EMERGENCY SOS ALERT",
            body: `${volunteerName} needs help! ${emergencyType} at ${address}`,
          },
          data: {
            sosId: sosId,
            volunteerId: sosData.odid || "",
            volunteerName: volunteerName,
            volunteerPhone: volunteerPhone,
            emergencyType: emergencyType,
            address: address,
            latitude: String(sosData.latitude || ""),
            longitude: String(sosData.longitude || ""),
            type: "sos_alert",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high",
            notification: {
              channelId: "sos_alerts_channel",
              priority: "max",
              defaultSound: true,
              defaultVibrateTimings: true,
              visibility: "public",
              icon: "@mipmap/ic_launcher",
              color: "#E53935",
              sound: "default",
            },
          },
          apns: {
            payload: {
              aps: {
                alert: {
                  title: "🚨 EMERGENCY SOS ALERT",
                  body: `${volunteerName} needs help! ${emergencyType}`,
                },
                sound: "default",
                badge: 1,
                "content-available": 1,
                "mutable-content": 1,
                "interruption-level": "critical",
              },
            },
          },
        };

        // Send to all tokens
        const response = await messaging.sendEachForMulticast({
          tokens: tokens,
          ...message,
        });

        console.log(`Successfully sent: ${response.successCount}`);
        console.log(`Failed: ${response.failureCount}`);

        // Remove invalid tokens
        if (response.failureCount > 0) {
          const failedTokens = [];
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              failedTokens.push(tokens[idx]);
              console.log(`Failed token: ${tokens[idx]}, Error: ${resp.error}`);
            }
          });

          // Delete failed tokens from database
          const batch = db.batch();
          const tokenDocs = await db.collection("ngo_fcm_tokens")
              .where("fcmToken", "in", failedTokens)
              .get();

          tokenDocs.forEach((doc) => {
            batch.delete(doc.ref);
          });

          await batch.commit();
          console.log(`Removed ${failedTokens.length} invalid tokens`);
        }

        return {success: true, sent: response.successCount};
      } catch (error) {
        console.error("Error sending notifications:", error);
        return {success: false, error: error.message};
      }
    });

/**
 * Cloud Function to send notification when SOS status changes
 */
exports.onSOSStatusChanged = functions.firestore
    .document("sos_alerts/{sosId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      const sosId = context.params.sosId;

      // Check if status changed to "responding"
      if (before.status !== "responding" && after.status === "responding") {
        console.log("SOS status changed to responding:", sosId);

        // Get volunteer FCM token
        const volunteerId = after.odid;
        if (!volunteerId) return null;

        try {
          const volunteerDoc = await db.collection("volunteers")
              .doc(volunteerId).get();

          if (!volunteerDoc.exists) {
            console.log("Volunteer not found:", volunteerId);
            return null;
          }

          const volunteerData = volunteerDoc.data();
          const fcmToken = volunteerData.fcmToken;

          if (!fcmToken) {
            console.log("No FCM token for volunteer:", volunteerId);
            return null;
          }

          const ngoName = after.respondingNgoName || "An NGO";
          const eta = after.estimatedArrival || 15;

          const message = {
            token: fcmToken,
            notification: {
              title: "✅ Help is on the way!",
              body: `${ngoName} is responding. ETA: ${eta} minutes`,
            },
            data: {
              sosId: sosId,
              type: "sos_response",
              ngoName: ngoName,
              eta: String(eta),
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
              priority: "high",
              notification: {
                channelId: "sos_alerts_channel",
                priority: "max",
                color: "#4CAF50",
              },
            },
          };

          await messaging.send(message);
          console.log("Notification sent to volunteer:", volunteerId);

          return {success: true};
        } catch (error) {
          console.error("Error sending volunteer notification:", error);
          return {success: false, error: error.message};
        }
      }

      return null;
    });
