const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Email configuration - Use Firebase Functions config
const emailConfig = {
  service: "gmail",
  auth: {
    user: functions.config().email?.user || "connectngo.notifications@gmail.com",
    pass: functions.config().email?.password || "your-app-password",
  },
};

const transporter = nodemailer.createTransport(emailConfig);

/**
 * Helper function to create FCM message with proper background notification support
 * This ensures notifications are shown even when app is closed/terminated
 */
function createFCMMessage(token, title, body, data, channelId = "general_channel") {
  return {
    token: token,
    notification: {
      title: title,
      body: body,
    },
    data: {
      ...data,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      title: title,  // Duplicate for background handler access
      body: body,    // Duplicate for background handler access
    },
    android: {
      priority: "high",
      ttl: 86400000, // 24 hours in milliseconds
      notification: {
        channelId: channelId,
        priority: "high",
        defaultSound: true,
        defaultVibrateTimings: true,
        visibility: "public",
        icon: "@mipmap/ic_launcher",
      },
    },
    apns: {
      headers: {
        "apns-priority": "10",
        "apns-push-type": "alert",
      },
      payload: {
        aps: {
          alert: {
            title: title,
            body: body,
          },
          sound: "default",
          badge: 1,
          "content-available": 1,
          "mutable-content": 1,
        },
      },
    },
    webpush: {
      headers: {
        Urgency: "high",
      },
      notification: {
        title: title,
        body: body,
        icon: "/icons/icon-192x192.png",
        requireInteraction: true,
      },
    },
  };
}

/**
 * Helper to send push notification with retry logic
 */
async function sendPushNotification(token, title, body, data, channelId = "general_channel") {
  try {
    const message = createFCMMessage(token, title, body, data, channelId);
    await messaging.send(message);
    return { success: true };
  } catch (error) {
    console.log("Failed to send push notification:", error.message);
    return { success: false, error: error.message };
  }
}

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

        // Send BOTH notification and data for background delivery
        // The notification part ensures delivery when app is killed
        // The data part carries the extra information for handling
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
            title: "🚨 EMERGENCY SOS ALERT",
            body: `${volunteerName} needs help! ${emergencyType} at ${address}`,
            fullScreenIntent: "true",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high",
            ttl: 60000, // 1 minute
            notification: {
              channelId: "sos_alerts_channel",
              priority: "max",
              sound: "emergency_alert",
              defaultVibrateTimings: false,
              vibrateTimingsMillis: [0, 500, 200, 500, 200, 500, 200, 500, 200, 500],
              visibility: "public",
              icon: "@mipmap/ic_launcher",
              color: "#E53935",
              tag: "sos_emergency",
              sticky: false,
              localOnly: false,
              defaultSound: false,
            },
          },
          apns: {
            headers: {
              "apns-priority": "10",
            },
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

// ==================== CAMPAIGN NOTIFICATIONS ====================

/**
 * Notify volunteers when a new campaign is created
 */
exports.onCampaignCreated = functions.firestore
    .document("campaigns/{campaignId}")
    .onCreate(async (snap, context) => {
      const campaignData = snap.data();
      const campaignId = context.params.campaignId;

      console.log("New campaign created:", campaignId);

      try {
        // Get NGO details
        const ngoId = campaignData.ngoId;
        const ngoName = campaignData.ngoName || "An NGO";
        const campaignName = campaignData.name || campaignData.title || "New Campaign";

        // Get all volunteers with campaign updates enabled
        const volunteersSnapshot = await db.collection("volunteers").get();

        for (const volunteerDoc of volunteersSnapshot.docs) {
          const volunteerId = volunteerDoc.id;
          const volunteerData = volunteerDoc.data();
          const fcmToken = volunteerData.fcmToken;
          const email = volunteerData.email;

          // Check settings
          const settingsDoc = await db.collection("volunteer_settings").doc(volunteerId).get();
          const settings = settingsDoc.exists ? settingsDoc.data() : {};

          if (settings.campaignUpdates === false) continue;

          // Create notification in database
          await db.collection("notifications").add({
            userId: volunteerId,
            recipientId: volunteerId,
            userType: "volunteer",
            title: `New Campaign: ${campaignName}`,
            message: `${ngoName} has started a new campaign. Join now to make an impact!`,
            body: `${ngoName} has started a new campaign. Join now to make an impact!`,
            type: "campaignCreated",
            data: { campaignId, ngoId, ngoName },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Send push notification if token exists
          if (fcmToken && (settings.pushNotifications !== false)) {
            await sendPushNotification(
              fcmToken,
              `🎯 New Campaign: ${campaignName}`,
              `${ngoName} has started a new campaign. Join now!`,
              {
                type: "campaign_created",
                campaignId: campaignId,
                ngoId: ngoId || "",
              },
              "general_channel"
            );
          }

          // Queue email if enabled
          if (email && (settings.emailNotifications !== false)) {
            await db.collection("email_queue").add({
              to: email,
              subject: `New Campaign: ${campaignName}`,
              body: `Hello,\n\n${ngoName} has launched a new campaign: "${campaignName}"\n\nJoin this campaign to make a positive impact!\n\nBest regards,\nConnect NGO Team`,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              sent: false,
            });
          }
        }

        console.log("Campaign notifications sent for:", campaignId);
        return { success: true };
      } catch (error) {
        console.error("Error in onCampaignCreated:", error);
        return { success: false, error: error.message };
      }
    });

// ==================== EVENT NOTIFICATIONS ====================

/**
 * Notify volunteers when a new event is created
 */
exports.onEventCreated = functions.firestore
    .document("events/{eventId}")
    .onCreate(async (snap, context) => {
      const eventData = snap.data();
      const eventId = context.params.eventId;

      console.log("New event created:", eventId);

      try {
        const ngoId = eventData.ngoId;
        const ngoName = eventData.ngoName || "An NGO";
        const eventName = eventData.name || eventData.title || "New Event";
        const eventDate = eventData.startDate || eventData.date;

        const volunteersSnapshot = await db.collection("volunteers").get();

        for (const volunteerDoc of volunteersSnapshot.docs) {
          const volunteerId = volunteerDoc.id;
          const volunteerData = volunteerDoc.data();
          const fcmToken = volunteerData.fcmToken;
          const email = volunteerData.email;

          const settingsDoc = await db.collection("volunteer_settings").doc(volunteerId).get();
          const settings = settingsDoc.exists ? settingsDoc.data() : {};

          if (settings.eventReminders === false) continue;

          // Create notification
          await db.collection("notifications").add({
            userId: volunteerId,
            recipientId: volunteerId,
            userType: "volunteer",
            title: `New Event: ${eventName}`,
            message: `${ngoName} is organizing an event. Register now!`,
            body: `${ngoName} is organizing an event. Register now!`,
            type: "eventCreated",
            data: { eventId, ngoId, ngoName },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Send push notification
          if (fcmToken && (settings.pushNotifications !== false)) {
            await sendPushNotification(
              fcmToken,
              `📅 New Event: ${eventName}`,
              `${ngoName} is organizing an event. Register now!`,
              {
                type: "event_created",
                eventId: eventId,
                ngoId: ngoId || "",
              },
              "general_channel"
            );
          }
        }

        // Mark for reminder notifications
        if (eventDate) {
          await snap.ref.update({
            reminder24hSent: false,
            reminder1hSent: false,
          });
        }

        console.log("Event notifications sent for:", eventId);
        return { success: true };
      } catch (error) {
        console.error("Error in onEventCreated:", error);
        return { success: false, error: error.message };
      }
    });

// ==================== DONATION NOTIFICATIONS ====================

/**
 * Notify on new donation
 */
exports.onDonationCreated = functions.firestore
    .document("donations/{donationId}")
    .onCreate(async (snap, context) => {
      const donationData = snap.data();
      const donationId = context.params.donationId;

      console.log("New donation:", donationId);

      try {
        const ngoId = donationData.ngoId;
        const donorId = donationData.userId || donationData.donorId;
        const amount = donationData.amount || 0;
        const ngoName = donationData.ngoName || "the NGO";
        const donorName = donationData.donorName || "A donor";
        const campaignName = donationData.campaignName;

        // Notify donor (volunteer)
        if (donorId) {
          const donorDoc = await db.collection("volunteers").doc(donorId).get();
          if (donorDoc.exists) {
            const donorData = donorDoc.data();
            const settingsDoc = await db.collection("volunteer_settings").doc(donorId).get();
            const settings = settingsDoc.exists ? settingsDoc.data() : {};

            // Create donation receipt notification
            await db.collection("notifications").add({
              userId: donorId,
              recipientId: donorId,
              userType: "volunteer",
              title: "Donation Successful!",
              message: `Your donation of ₹${amount} to ${ngoName} was successful.`,
              body: `Your donation of ₹${amount} to ${ngoName} was successful.`,
              type: "donationSuccess",
              data: { donationId, amount, ngoId, ngoName },
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Send push
            if (donorData.fcmToken && (settings.pushNotifications !== false)) {
              await sendPushNotification(
                donorData.fcmToken,
                "✅ Donation Successful!",
                `Thank you for donating ₹${amount} to ${ngoName}`,
                { type: "donation_success", donationId: donationId },
                "donations_channel"
              );
            }

            // Send email receipt
            if (donorData.email && (settings.emailNotifications !== false) && (settings.donationReceipts !== false)) {
              await db.collection("email_queue").add({
                to: donorData.email,
                subject: `Donation Receipt - ₹${amount} to ${ngoName}`,
                body: `Dear ${donorName},\n\nThank you for your generous donation!\n\nDONATION RECEIPT\n================\nAmount: ₹${amount}\nNGO: ${ngoName}\n${campaignName ? `Campaign: ${campaignName}\n` : ""}Transaction ID: ${donationId}\nDate: ${new Date().toLocaleString()}\n\nYour contribution will help make a positive impact.\n\nBest regards,\nConnect NGO Team`,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                sent: false,
              });
            }
          }
        }

        // Notify NGO
        if (ngoId) {
          const ngoDoc = await db.collection("ngo_registrations").doc(ngoId).get();
          if (ngoDoc.exists) {
            const ngoData = ngoDoc.data();
            const settingsDoc = await db.collection("ngo_settings").doc(ngoId).get();
            const settings = settingsDoc.exists ? settingsDoc.data() : {};

            if (settings.donationAlerts !== false) {
              // Create notification for NGO
              await db.collection("notifications").add({
                userId: ngoId,
                recipientId: ngoId,
                userType: "ngo",
                title: `Donation Received: ₹${amount}`,
                message: `${donorName} donated${campaignName ? ` to ${campaignName}` : ""}`,
                body: `${donorName} donated${campaignName ? ` to ${campaignName}` : ""}`,
                type: "donationReceived",
                data: { donationId, amount, donorId, donorName },
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
              });

              // Send push to all NGO tokens
              const ngoTokensSnapshot = await db.collection("ngo_fcm_tokens")
                  .where("ngoId", "==", ngoId)
                  .get();

              for (const tokenDoc of ngoTokensSnapshot.docs) {
                const token = tokenDoc.data().fcmToken;
                if (token && (settings.pushNotifications !== false)) {
                  await sendPushNotification(
                    token,
                    `💰 Donation Received: ₹${amount}`,
                    `${donorName} donated${campaignName ? ` to ${campaignName}` : ""}`,
                    { type: "donation_received", donationId: donationId },
                    "donations_channel"
                  );
                }
              }

              // Send email to NGO
              if (ngoData.email && (settings.emailNotifications !== false)) {
                await db.collection("email_queue").add({
                  to: ngoData.email,
                  subject: `New Donation Received - ₹${amount}`,
                  body: `Dear ${ngoData.ngoName || "Team"},\n\nGreat news! You've received a new donation.\n\nDONATION DETAILS\n================\nDonor: ${donorName}\nAmount: ₹${amount}\n${campaignName ? `Campaign: ${campaignName}\n` : ""}Date: ${new Date().toLocaleString()}\n\nThank you for your work!\n\nBest regards,\nConnect NGO Team`,
                  createdAt: admin.firestore.FieldValue.serverTimestamp(),
                  sent: false,
                });
              }
            }
          }
        }

        return { success: true };
      } catch (error) {
        console.error("Error in onDonationCreated:", error);
        return { success: false, error: error.message };
      }
    });

// ==================== VOLUNTEER REGISTRATION NOTIFICATIONS ====================

/**
 * Notify NGO when volunteer applies
 */
exports.onVolunteerRegistrationCreated = functions.firestore
    .document("volunteer_registrations/{regId}")
    .onCreate(async (snap, context) => {
      const regData = snap.data();
      const regId = context.params.regId;

      console.log("New volunteer registration:", regId);

      try {
        const ngoId = regData.ngoId;
        const volunteerId = regData.volunteerId;
        const volunteerName = regData.volunteerName || "A volunteer";
        const volunteerEmail = regData.volunteerEmail || "";
        const role = regData.role;

        if (!ngoId) return { success: false, error: "No NGO ID" };

        const ngoDoc = await db.collection("ngo_registrations").doc(ngoId).get();
        if (!ngoDoc.exists) return { success: false, error: "NGO not found" };

        const ngoData = ngoDoc.data();
        const settingsDoc = await db.collection("ngo_settings").doc(ngoId).get();
        const settings = settingsDoc.exists ? settingsDoc.data() : {};

        if (settings.volunteerAlerts !== false) {
          // Create notification
          await db.collection("notifications").add({
            userId: ngoId,
            recipientId: ngoId,
            userType: "ngo",
            title: "New Volunteer Application",
            message: `${volunteerName} has applied to volunteer${role ? ` as ${role}` : ""}`,
            body: `${volunteerName} has applied to volunteer${role ? ` as ${role}` : ""}`,
            type: "volunteerApplication",
            data: { regId, volunteerId, volunteerName, volunteerEmail, role },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Send push
          const ngoTokensSnapshot = await db.collection("ngo_fcm_tokens")
              .where("ngoId", "==", ngoId)
              .get();

          for (const tokenDoc of ngoTokensSnapshot.docs) {
            const token = tokenDoc.data().fcmToken;
            if (token && (settings.pushNotifications !== false)) {
              await sendPushNotification(
                token,
                "👤 New Volunteer Application",
                `${volunteerName} wants to join your organization`,
                { type: "volunteer_application", regId: regId },
                "general_channel"
              );
            }
          }

          // Send email
          if (ngoData.email && (settings.emailNotifications !== false)) {
            await db.collection("email_queue").add({
              to: ngoData.email,
              subject: `New Volunteer Application - ${volunteerName}`,
              body: `Dear ${ngoData.ngoName || "Team"},\n\nYou have received a new volunteer application!\n\nAPPLICANT DETAILS\n=================\nName: ${volunteerName}\nEmail: ${volunteerEmail}\n${role ? `Role: ${role}\n` : ""}Date: ${new Date().toLocaleString()}\n\nPlease review this application in the Connect NGO app.\n\nBest regards,\nConnect NGO Team`,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              sent: false,
            });
          }
        }

        return { success: true };
      } catch (error) {
        console.error("Error in onVolunteerRegistrationCreated:", error);
        return { success: false, error: error.message };
      }
    });

/**
 * Notify volunteer when application status changes
 */
exports.onVolunteerRegistrationUpdated = functions.firestore
    .document("volunteer_registrations/{regId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      const regId = context.params.regId;

      // Check if status changed
      if (before.status === after.status) return null;

      const newStatus = after.status;
      if (newStatus !== "approved" && newStatus !== "rejected") return null;

      console.log("Volunteer registration status changed:", regId, newStatus);

      try {
        const volunteerId = after.volunteerId;
        const ngoName = after.ngoName || "the NGO";
        const ngoId = after.ngoId;
        const rejectionReason = after.rejectionReason;

        if (!volunteerId) return { success: false, error: "No volunteer ID" };

        const volunteerDoc = await db.collection("volunteers").doc(volunteerId).get();
        if (!volunteerDoc.exists) return { success: false, error: "Volunteer not found" };

        const volunteerData = volunteerDoc.data();
        const settingsDoc = await db.collection("volunteer_settings").doc(volunteerId).get();
        const settings = settingsDoc.exists ? settingsDoc.data() : {};

        const approved = newStatus === "approved";
        const title = approved ? "Application Approved!" : "Application Update";
        const message = approved
            ? `Congratulations! Your application to ${ngoName} has been approved.`
            : `Your application to ${ngoName} was not approved.${rejectionReason ? ` Reason: ${rejectionReason}` : ""}`;

        // Create notification
        await db.collection("notifications").add({
          userId: volunteerId,
          recipientId: volunteerId,
          userType: "volunteer",
          title: title,
          message: message,
          body: message,
          type: approved ? "volunteerApproved" : "volunteerRejected",
          data: { regId, ngoId, ngoName, approved, rejectionReason },
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Send push
        if (volunteerData.fcmToken && (settings.pushNotifications !== false)) {
          await sendPushNotification(
            volunteerData.fcmToken,
            approved ? "🎉 Application Approved!" : "📋 Application Update",
            approved ? `Welcome to ${ngoName}!` : `Your application to ${ngoName} was reviewed`,
            { type: "application_status", regId: regId, approved: String(approved) },
            "general_channel"
          );
        }

        // Send email
        if (volunteerData.email && (settings.emailNotifications !== false)) {
          const emailBody = approved
              ? `Dear ${volunteerData.name || "Volunteer"},\n\nCongratulations! 🎉\n\nYour volunteer application to ${ngoName} has been approved!\n\nYou can now:\n- Participate in campaigns\n- Join events\n- Contribute to the organization's mission\n\nLog in to the Connect NGO app to get started.\n\nWelcome aboard!\n\nBest regards,\nConnect NGO Team`
              : `Dear ${volunteerData.name || "Volunteer"},\n\nThank you for your interest in volunteering with ${ngoName}.\n\nUnfortunately, your application was not approved at this time.\n${rejectionReason ? `\nReason: ${rejectionReason}\n` : ""}\nWe encourage you to explore other opportunities on Connect NGO.\n\nBest regards,\nConnect NGO Team`;

          await db.collection("email_queue").add({
            to: volunteerData.email,
            subject: approved ? `Welcome to ${ngoName}!` : `Application Update from ${ngoName}`,
            body: emailBody,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            sent: false,
          });
        }

        return { success: true };
      } catch (error) {
        console.error("Error in onVolunteerRegistrationUpdated:", error);
        return { success: false, error: error.message };
      }
    });

// ==================== CAMPAIGN/EVENT PARTICIPATION NOTIFICATIONS ====================

/**
 * Notify NGO when volunteer joins campaign
 */
exports.onCampaignParticipantCreated = functions.firestore
    .document("campaign_participants/{participantId}")
    .onCreate(async (snap, context) => {
      const data = snap.data();

      try {
        const campaignId = data.campaignId;
        const volunteerId = data.userId || data.volunteerId;

        if (!campaignId || !volunteerId) return null;

        // Get campaign details
        const campaignDoc = await db.collection("campaigns").doc(campaignId).get();
        if (!campaignDoc.exists) return null;

        const campaignData = campaignDoc.data();
        const ngoId = campaignData.ngoId;
        const campaignName = campaignData.name || campaignData.title || "Campaign";

        // Get volunteer name
        const volunteerDoc = await db.collection("volunteers").doc(volunteerId).get();
        const volunteerName = volunteerDoc.exists ? (volunteerDoc.data().name || "A volunteer") : "A volunteer";

        if (!ngoId) return null;

        const settingsDoc = await db.collection("ngo_settings").doc(ngoId).get();
        const settings = settingsDoc.exists ? settingsDoc.data() : {};

        if (settings.campaignUpdates !== false) {
          // Create notification
          await db.collection("notifications").add({
            userId: ngoId,
            recipientId: ngoId,
            userType: "ngo",
            title: "Volunteer Joined Campaign",
            message: `${volunteerName} joined "${campaignName}"`,
            body: `${volunteerName} joined "${campaignName}"`,
            type: "volunteerJoinedCampaign",
            data: { campaignId, campaignName, volunteerId, volunteerName },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Send push
          const ngoTokensSnapshot = await db.collection("ngo_fcm_tokens")
              .where("ngoId", "==", ngoId)
              .get();

          for (const tokenDoc of ngoTokensSnapshot.docs) {
            const token = tokenDoc.data().fcmToken;
            if (token && (settings.pushNotifications !== false)) {
              await sendPushNotification(
                token,
                "🎉 Campaign Update",
                `${volunteerName} joined "${campaignName}"`,
                { type: "campaign_participant", campaignId: campaignId },
                "general_channel"
              );
            }
          }
        }

        return { success: true };
      } catch (error) {
        console.error("Error in onCampaignParticipantCreated:", error);
        return { success: false, error: error.message };
      }
    });

/**
 * Notify NGO when volunteer joins event
 */
exports.onEventParticipantCreated = functions.firestore
    .document("event_participants/{participantId}")
    .onCreate(async (snap, context) => {
      const data = snap.data();

      try {
        const eventId = data.eventId;
        const volunteerId = data.userId || data.volunteerId;

        if (!eventId || !volunteerId) return null;

        // Get event details
        const eventDoc = await db.collection("events").doc(eventId).get();
        if (!eventDoc.exists) return null;

        const eventData = eventDoc.data();
        const ngoId = eventData.ngoId;
        const eventName = eventData.name || eventData.title || "Event";

        // Get volunteer name
        const volunteerDoc = await db.collection("volunteers").doc(volunteerId).get();
        const volunteerName = volunteerDoc.exists ? (volunteerDoc.data().name || "A volunteer") : "A volunteer";

        if (!ngoId) return null;

        const settingsDoc = await db.collection("ngo_settings").doc(ngoId).get();
        const settings = settingsDoc.exists ? settingsDoc.data() : {};

        if (settings.eventReminders !== false) {
          // Create notification
          await db.collection("notifications").add({
            userId: ngoId,
            recipientId: ngoId,
            userType: "ngo",
            title: "Volunteer Registered for Event",
            message: `${volunteerName} registered for "${eventName}"`,
            body: `${volunteerName} registered for "${eventName}"`,
            type: "volunteerJoinedEvent",
            data: { eventId, eventName, volunteerId, volunteerName },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Send push
          const ngoTokensSnapshot = await db.collection("ngo_fcm_tokens")
              .where("ngoId", "==", ngoId)
              .get();

          for (const tokenDoc of ngoTokensSnapshot.docs) {
            const token = tokenDoc.data().fcmToken;
            if (token && (settings.pushNotifications !== false)) {
              await sendPushNotification(
                token,
                "📅 Event Registration",
                `${volunteerName} registered for "${eventName}"`,
                { type: "event_participant", eventId: eventId },
                "general_channel"
              );
            }
          }
        }

        return { success: true };
      } catch (error) {
        console.error("Error in onEventParticipantCreated:", error);
        return { success: false, error: error.message };
      }
    });

// ==================== EVENT REMINDERS ====================

/**
 * Scheduled function to send event reminders (runs every hour)
 */
exports.sendEventReminders = functions.pubsub
    .schedule("every 1 hours")
    .onRun(async (context) => {
      console.log("Running event reminder check...");

      try {
        const now = new Date();
        const in24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);
        const in1Hour = new Date(now.getTime() + 1 * 60 * 60 * 1000);

        // Get events starting in ~24 hours (not yet reminded)
        const events24h = await db.collection("events")
            .where("startDate", ">", admin.firestore.Timestamp.fromDate(now))
            .where("startDate", "<=", admin.firestore.Timestamp.fromDate(in24Hours))
            .where("reminder24hSent", "==", false)
            .get();

        for (const eventDoc of events24h.docs) {
          const eventData = eventDoc.data();
          await sendEventReminderToParticipants(eventDoc.id, eventData, 24);
          await eventDoc.ref.update({ reminder24hSent: true });
        }

        // Get events starting in ~1 hour (not yet reminded)
        const events1h = await db.collection("events")
            .where("startDate", ">", admin.firestore.Timestamp.fromDate(now))
            .where("startDate", "<=", admin.firestore.Timestamp.fromDate(in1Hour))
            .where("reminder1hSent", "==", false)
            .get();

        for (const eventDoc of events1h.docs) {
          const eventData = eventDoc.data();
          await sendEventReminderToParticipants(eventDoc.id, eventData, 1);
          await eventDoc.ref.update({ reminder1hSent: true });
        }

        console.log(`Event reminders sent: ${events24h.size} (24h), ${events1h.size} (1h)`);
        return { success: true };
      } catch (error) {
        console.error("Error in sendEventReminders:", error);
        return { success: false, error: error.message };
      }
    });

async function sendEventReminderToParticipants(eventId, eventData, hoursUntil) {
  const eventName = eventData.name || eventData.title || "Event";
  const ngoName = eventData.ngoName || "NGO";

  // Get all participants
  const participantsSnapshot = await db.collection("event_participants")
      .where("eventId", "==", eventId)
      .get();

  for (const participantDoc of participantsSnapshot.docs) {
    const volunteerId = participantDoc.data().userId || participantDoc.data().volunteerId;
    if (!volunteerId) continue;

    const settingsDoc = await db.collection("volunteer_settings").doc(volunteerId).get();
    const settings = settingsDoc.exists ? settingsDoc.data() : {};

    if (settings.eventReminders === false) continue;

    const volunteerDoc = await db.collection("volunteers").doc(volunteerId).get();
    if (!volunteerDoc.exists) continue;

    const volunteerData = volunteerDoc.data();

    // Create notification
    await db.collection("notifications").add({
      userId: volunteerId,
      recipientId: volunteerId,
      userType: "volunteer",
      title: `⏰ Event Reminder: ${eventName}`,
      message: `Your event starts in ${hoursUntil} hour${hoursUntil > 1 ? "s" : ""}. Don't forget to attend!`,
      body: `Your event starts in ${hoursUntil} hour${hoursUntil > 1 ? "s" : ""}. Don't forget to attend!`,
      type: "eventReminder",
      data: { eventId, hoursUntil },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send push
    if (volunteerData.fcmToken && (settings.pushNotifications !== false)) {
      await sendPushNotification(
        volunteerData.fcmToken,
        `⏰ Event Reminder`,
        `${eventName} starts in ${hoursUntil} hour${hoursUntil > 1 ? "s" : ""}!`,
        { type: "event_reminder", eventId: eventId },
        "reminders_channel"
      );
    }

    // Send email reminder
    if (volunteerData.email && (settings.emailNotifications !== false)) {
      await db.collection("email_queue").add({
        to: volunteerData.email,
        subject: `Reminder: ${eventName} starts in ${hoursUntil} hour${hoursUntil > 1 ? "s" : ""}`,
        body: `Hello,\n\nThis is a reminder that the event "${eventName}" by ${ngoName} starts in ${hoursUntil} hour${hoursUntil > 1 ? "s" : ""}.\n\nDon't forget to attend!\n\nBest regards,\nConnect NGO Team`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        sent: false,
      });
    }
  }
}

// ==================== EMAIL QUEUE PROCESSOR ====================

/**
 * Process email queue (runs every 5 minutes)
 */
exports.processEmailQueue = functions.pubsub
    .schedule("every 5 minutes")
    .onRun(async (context) => {
      console.log("Processing email queue...");

      try {
        const emailsSnapshot = await db.collection("email_queue")
            .where("sent", "==", false)
            .limit(50)
            .get();

        let sentCount = 0;

        for (const emailDoc of emailsSnapshot.docs) {
          const emailData = emailDoc.data();

          try {
            const mailOptions = {
              from: `"Connect & Contribute" <${emailConfig.auth.user}>`,
              to: emailData.to,
              subject: emailData.subject,
            };

            // Support both HTML and plain text emails
            if (emailData.html) {
              mailOptions.html = emailData.html;
            }
            if (emailData.body) {
              mailOptions.text = emailData.body;
            }

            await transporter.sendMail(mailOptions);

            await emailDoc.ref.update({
              sent: true,
              sentAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            sentCount++;
            console.log(`Email sent to: ${emailData.to}`);
          } catch (e) {
            console.error("Failed to send email to:", emailData.to, e.message);
            await emailDoc.ref.update({
              error: e.message,
              lastAttempt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        }

        console.log(`Emails processed: ${sentCount}/${emailsSnapshot.size}`);
        return { success: true, sent: sentCount };
      } catch (error) {
        console.error("Error in processEmailQueue:", error);
        return { success: false, error: error.message };
      }
    });

// ==================== PUSH NOTIFICATION QUEUE PROCESSOR ====================

/**
 * Process push notification queue
 */
exports.processPushQueue = functions.firestore
    .document("push_notifications/{pushId}")
    .onCreate(async (snap, context) => {
      const pushData = snap.data();

      if (pushData.sent) return null;

      try {
        const { token, title, body, data, channelId } = pushData;

        if (!token || !title) {
          await snap.ref.update({ sent: true, error: "Missing token or title" });
          return null;
        }

        const result = await sendPushNotification(
          token,
          title,
          body || "",
          data || {},
          channelId || "general_channel"
        );

        await snap.ref.update({
          sent: true,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          ...(result.error ? { error: result.error } : {}),
        });

        return result;
      } catch (error) {
        console.error("Error sending push:", error.message);
        await snap.ref.update({
          sent: true,
          error: error.message,
        });
        return { success: false, error: error.message };
      }
    });

// ==================== WEEKLY DIGEST ====================

/**
 * Send weekly digest to NGOs (runs every Monday at 9 AM)
 */
exports.sendWeeklyDigest = functions.pubsub
    .schedule("every monday 09:00")
    .timeZone("Asia/Kolkata")
    .onRun(async (context) => {
      console.log("Sending weekly digest...");

      try {
        const settingsSnapshot = await db.collection("ngo_settings")
            .where("weeklyDigest", "==", true)
            .get();

        const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

        for (const settingsDoc of settingsSnapshot.docs) {
          const ngoId = settingsDoc.id;

          const ngoDoc = await db.collection("ngo_registrations").doc(ngoId).get();
          if (!ngoDoc.exists) continue;

          const ngoData = ngoDoc.data();
          const ngoName = ngoData.ngoName || "NGO";

          // Calculate stats
          const donationsSnapshot = await db.collection("donations")
              .where("ngoId", "==", ngoId)
              .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(weekAgo))
              .get();

          let totalDonations = 0;
          donationsSnapshot.forEach(doc => {
            totalDonations += doc.data().amount || 0;
          });

          const newVolunteersSnapshot = await db.collection("volunteer_registrations")
              .where("ngoId", "==", ngoId)
              .where("status", "==", "approved")
              .where("approvedAt", ">=", admin.firestore.Timestamp.fromDate(weekAgo))
              .get();

          // Create notification
          await db.collection("notifications").add({
            userId: ngoId,
            recipientId: ngoId,
            userType: "ngo",
            title: "📊 Weekly Digest",
            message: `This week: ${donationsSnapshot.size} donations (₹${totalDonations}), ${newVolunteersSnapshot.size} new volunteers`,
            body: `This week: ${donationsSnapshot.size} donations (₹${totalDonations}), ${newVolunteersSnapshot.size} new volunteers`,
            type: "weeklyDigest",
            data: {
              donationCount: donationsSnapshot.size,
              totalDonations,
              newVolunteers: newVolunteersSnapshot.size,
            },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Send email
          if (ngoData.email) {
            await db.collection("email_queue").add({
              to: ngoData.email,
              subject: `Weekly Digest - ${ngoName}`,
              body: `Dear ${ngoName} Team,\n\nHere's your weekly summary:\n\nDONATIONS\n=========\nTotal Donations: ${donationsSnapshot.size}\nTotal Amount: ₹${totalDonations.toFixed(2)}\n\nVOLUNTEERS\n==========\nNew Volunteers: ${newVolunteersSnapshot.size}\n\nKeep up the great work!\n\nBest regards,\nConnect NGO Team`,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              sent: false,
            });
          }
        }

        console.log(`Weekly digest sent to ${settingsSnapshot.size} NGOs`);
        return { success: true };
      } catch (error) {
        console.error("Error in sendWeeklyDigest:", error);
        return { success: false, error: error.message };
      }
    });

/**
 * Cloud Function to export user data as PDF and send via email
 */
exports.exportUserData = functions.https.onCall(async (data, context) => {
  try {
    // Check authentication
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }

    const userId = context.auth.uid;
    const PDFDocument = require("pdfkit");
    const fs = require("fs");
    const path = require("path");
    const os = require("os");

    console.log(`Exporting data for user: ${userId}`);

    // Fetch user profile data
    const volunteerDoc = await db.collection("volunteers").doc(userId).get();
    if (!volunteerDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Volunteer profile not found");
    }

    const volunteerData = volunteerDoc.data();
    const userEmail = volunteerData.email || context.auth.token.email;
    const userName = volunteerData.name || "User";

    // Fetch all user-related data
    const [
      campaignsSnapshot,
      donationsSnapshot,
      eventsSnapshot,
      csrApplicationsSnapshot,
      settingsSnapshot,
      sosAlertsSnapshot,
    ] = await Promise.all([
      db.collection("campaign_participants").where("volunteerId", "==", userId).get(),
      db.collection("donations").where("donorId", "==", userId).get(),
      db.collection("event_participants").where("userId", "==", userId).get(),
      db.collection("csr_volunteer_applications").where("volunteerId", "==", userId).get(),
      db.collection("volunteer_settings").doc(userId).get(),
      db.collection("sos_alerts").where("volunteerId", "==", userId).get(),
    ]);

    // Create PDF
    const tempDir = os.tmpdir();
    const pdfPath = path.join(tempDir, `user_data_${userId}.pdf`);
    const doc = new PDFDocument({ margin: 50 });
    const stream = fs.createWriteStream(pdfPath);
    doc.pipe(stream);

    // Helper function to add section title
    function addSectionTitle(title) {
      doc.moveDown(1);
      doc.fontSize(16).fillColor("#0099B8").text(title, { underline: true });
      doc.moveDown(0.5);
      doc.fontSize(10).fillColor("#000000");
    }

    // Helper function to add key-value pair
    function addField(key, value) {
      doc.fontSize(10).fillColor("#333333").text(`${key}: `, { continued: true })
          .fillColor("#000000").text(value || "N/A");
    }

    // PDF Header
    doc.fontSize(20).fillColor("#0099B8").text("User Data Export", { align: "center" });
    doc.moveDown(0.5);
    doc.fontSize(12).fillColor("#666666").text(`Generated on: ${new Date().toLocaleDateString("en-IN", { year: "numeric", month: "long", day: "numeric" })}`, { align: "center" });
    doc.moveDown(1);
    doc.strokeColor("#0099B8").lineWidth(2).moveTo(50, doc.y).lineTo(550, doc.y).stroke();

    // 1. Personal Information
    addSectionTitle("1. Personal Information");
    addField("Name", volunteerData.name);
    addField("Email", volunteerData.email);
    addField("Phone", volunteerData.phone);
    addField("Date of Birth", volunteerData.dateOfBirth);
    addField("Gender", volunteerData.gender);
    addField("Address", volunteerData.address);
    addField("City", volunteerData.city);
    addField("State", volunteerData.state);
    addField("PIN Code", volunteerData.pinCode);
    addField("Occupation", volunteerData.occupation);
    addField("Skills", volunteerData.skills?.join(", "));
    addField("Areas of Interest", volunteerData.interests?.join(", "));
    addField("Languages Known", volunteerData.languages?.join(", "));
    addField("Bio", volunteerData.bio);
    addField("Registration Date", volunteerData.createdAt?.toDate().toLocaleDateString());
    addField("Profile Visibility", volunteerData.isProfilePublic ? "Public" : "Private");

    // 2. Campaign Participation
    addSectionTitle("2. Campaign Participation");
    if (campaignsSnapshot.empty) {
      doc.text("No campaigns participated in.");
    } else {
      doc.text(`Total Campaigns: ${campaignsSnapshot.size}`);
      doc.moveDown(0.5);
      let campaignIndex = 1;
      for (const campDoc of campaignsSnapshot.docs) {
        const campData = campDoc.data();
        doc.fontSize(10).fillColor("#0099B8").text(`Campaign ${campaignIndex++}:`, { underline: true });
        addField("  Campaign ID", campData.campaignId);
        addField("  Status", campData.status);
        addField("  Role", campData.role);
        addField("  Joined Date", campData.joinedAt?.toDate().toLocaleDateString());
        addField("  Hours Contributed", campData.hoursContributed);
        doc.moveDown(0.3);
      }
    }

    // 3. Donations
    addSectionTitle("3. Donation History");
    if (donationsSnapshot.empty) {
      doc.text("No donations made.");
    } else {
      const totalDonations = donationsSnapshot.docs.reduce((sum, d) => sum + (d.data().amount || 0), 0);
      doc.text(`Total Donations: ${donationsSnapshot.size}`);
      addField("Total Amount", `₹${totalDonations.toFixed(2)}`);
      doc.moveDown(0.5);
      let donationIndex = 1;
      for (const donDoc of donationsSnapshot.docs) {
        const donData = donDoc.data();
        doc.fontSize(10).fillColor("#0099B8").text(`Donation ${donationIndex++}:`, { underline: true });
        addField("  Amount", `₹${donData.amount}`);
        addField("  NGO", donData.ngoName);
        addField("  Campaign", donData.campaignName);
        addField("  Payment Method", donData.paymentMethod);
        addField("  Transaction ID", donData.transactionId);
        addField("  Date", donData.createdAt?.toDate().toLocaleDateString());
        addField("  Status", donData.status);
        doc.moveDown(0.3);
      }
    }

    // 4. Event Participation
    addSectionTitle("4. Event Participation");
    if (eventsSnapshot.empty) {
      doc.text("No events participated in.");
    } else {
      doc.text(`Total Events: ${eventsSnapshot.size}`);
      doc.moveDown(0.5);
      let eventIndex = 1;
      for (const eventDoc of eventsSnapshot.docs) {
        const eventData = eventDoc.data();
        doc.fontSize(10).fillColor("#0099B8").text(`Event ${eventIndex++}:`, { underline: true });
        addField("  Event ID", eventData.eventId);
        addField("  Status", eventData.status);
        addField("  Registered Date", eventData.registeredAt?.toDate().toLocaleDateString());
        addField("  Attended", eventData.attended ? "Yes" : "No");
        doc.moveDown(0.3);
      }
    }

    // 5. CSR Opportunities
    addSectionTitle("5. CSR Opportunities");
    if (csrApplicationsSnapshot.empty) {
      doc.text("No CSR opportunity applications.");
    } else {
      doc.text(`Total Applications: ${csrApplicationsSnapshot.size}`);
      doc.moveDown(0.5);
      let csrIndex = 1;
      for (const csrDoc of csrApplicationsSnapshot.docs) {
        const csrData = csrDoc.data();
        doc.fontSize(10).fillColor("#0099B8").text(`Application ${csrIndex++}:`, { underline: true });
        addField("  Opportunity ID", csrData.opportunityId);
        addField("  Company", csrData.companyName);
        addField("  Status", csrData.status);
        addField("  Applied Date", csrData.appliedAt?.toDate().toLocaleDateString());
        addField("  Skills Offered", csrData.skillsOffered?.join(", "));
        doc.moveDown(0.3);
      }
    }

    // 6. SOS Alerts
    addSectionTitle("6. SOS Alerts");
    if (sosAlertsSnapshot.empty) {
      doc.text("No SOS alerts created.");
    } else {
      doc.text(`Total SOS Alerts: ${sosAlertsSnapshot.size}`);
      doc.moveDown(0.5);
      let sosIndex = 1;
      for (const sosDoc of sosAlertsSnapshot.docs) {
        const sosData = sosDoc.data();
        doc.fontSize(10).fillColor("#0099B8").text(`Alert ${sosIndex++}:`, { underline: true });
        addField("  Type", sosData.type);
        addField("  Description", sosData.description);
        addField("  Location", sosData.location);
        addField("  Date", sosData.createdAt?.toDate().toLocaleDateString());
        addField("  Status", sosData.status);
        doc.moveDown(0.3);
      }
    }

    // 7. Settings & Preferences
    addSectionTitle("7. Settings & Preferences");
    if (settingsSnapshot.exists) {
      const settings = settingsSnapshot.data();
      doc.fontSize(11).fillColor("#0099B8").text("Notification Settings:", { underline: true });
      addField("  Push Notifications", settings.pushNotifications ? "Enabled" : "Disabled");
      addField("  Email Notifications", settings.emailNotifications ? "Enabled" : "Disabled");
      addField("  Campaign Updates", settings.campaignUpdates ? "Enabled" : "Disabled");
      addField("  Event Reminders", settings.eventReminders ? "Enabled" : "Disabled");
      addField("  Donation Receipts", settings.donationReceipts ? "Enabled" : "Disabled");
      addField("  SOS Alerts", settings.sosAlerts ? "Enabled" : "Disabled");
      doc.moveDown(0.5);
      doc.fontSize(11).fillColor("#0099B8").text("Privacy Settings:", { underline: true });
      addField("  Show Profile", settings.showProfile ? "Yes" : "No");
      addField("  Show Activity", settings.showActivity ? "Yes" : "No");
      addField("  Allow Messages", settings.allowMessages ? "Yes" : "No");
    } else {
      doc.text("No custom settings configured.");
    }

    // Footer
    doc.moveDown(2);
    doc.fontSize(8).fillColor("#999999").text(
        "This document contains your personal data from Connect NGO platform. Please keep it secure.",
        { align: "center" },
    );
    doc.text(
        "For any queries, contact support@connectngo.com",
        { align: "center" },
    );

    // Finalize PDF
    doc.end();

    // Wait for PDF to be written
    await new Promise((resolve, reject) => {
      stream.on("finish", resolve);
      stream.on("error", reject);
    });

    // Read PDF as base64 for storage
    const pdfBuffer = fs.readFileSync(pdfPath);
    const pdfBase64 = pdfBuffer.toString("base64");

    // Store PDF temporarily in Firestore with the email details
    // This approach doesn't require SMTP credentials
    const exportRef = await db.collection("data_exports").add({
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      pdfData: pdfBase64,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      sent: false,
      fileName: `ConnectNGO_UserData_${new Date().toISOString().split("T")[0]}.pdf`,
    });

    // Try to send email using nodemailer if configured, otherwise just store it
    try {
      const mailOptions = {
        from: emailConfig.auth.user || "noreply@connectngo.com",
        to: userEmail,
        subject: "Your Data Export - Connect NGO",
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <div style="background: linear-gradient(135deg, #0099B8 0%, #006B8F 100%); padding: 30px; text-align: center;">
              <h1 style="color: white; margin: 0;">Data Export Ready</h1>
            </div>
            
            <div style="background: #f9f9f9; padding: 30px;">
              <p>Dear ${userName},</p>
              
              <p>Your data export request has been completed successfully. Please find attached a PDF document containing all your information from the Connect NGO platform.</p>
              
              <div style="background: white; border-left: 4px solid #0099B8; padding: 15px; margin: 20px 0;">
                <h3 style="color: #0099B8; margin-top: 0;">What's Included:</h3>
                <ul style="color: #666;">
                  <li>Personal Information & Profile</li>
                  <li>Campaign Participation History</li>
                  <li>Donation Records</li>
                  <li>Event Participation</li>
                  <li>CSR Opportunity Applications</li>
                  <li>SOS Alerts</li>
                  <li>Settings & Preferences</li>
                </ul>
              </div>
              
              <p style="color: #666; font-size: 14px; margin-top: 20px;">
                <strong>Note:</strong> This document contains sensitive personal information. Please store it securely and do not share it with unauthorized persons.
              </p>
              
              <p>If you have any questions or did not request this export, please contact us immediately.</p>
              
              <p>Best regards,<br>
              <strong>Connect NGO Team</strong></p>
            </div>
            
            <div style="background: #333; color: #999; padding: 20px; text-align: center; font-size: 12px;">
              <p>Connect NGO - Connecting Hearts, Changing Lives</p>
              <p>support@connectngo.com</p>
            </div>
          </div>
        `,
        attachments: [
          {
            filename: `ConnectNGO_UserData_${new Date().toISOString().split("T")[0]}.pdf`,
            path: pdfPath,
            contentType: "application/pdf",
          },
        ],
      };

      // Only send email if credentials are properly configured
      if (emailConfig.auth.user && emailConfig.auth.user !== "connectngo.notifications@gmail.com") {
        await transporter.sendMail(mailOptions);
        await exportRef.update({ sent: true });
        console.log(`Data export email sent to ${userEmail}`);
      } else {
        console.log(`Email credentials not configured. Export stored in Firestore for user: ${userId}`);
      }
    } catch (emailError) {
      console.error("Email sending failed, but export is stored:", emailError.message);
      // Don't throw error, the data is still accessible in Firestore
    }

    // Clean up temporary file
    fs.unlinkSync(pdfPath);

    // Create a notification for the user
    await db.collection("notifications").add({
      recipientId: userId,
      userType: "volunteer",
      title: "📄 Data Export Ready",
      message: "Your data export has been generated. Check your email or download from app.",
      body: "Your data export PDF is ready for download",
      type: "dataExport",
      data: {
        exportId: exportRef.id,
      },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Data export completed for ${userEmail}`);
    return { 
      success: true, 
      message: "Data export completed! Check your email or download from the app.",
      exportId: exportRef.id,
    };
  } catch (error) {
    console.error("Error in exportUserData:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
