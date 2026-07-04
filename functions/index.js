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
    const userName = volunteerData.name || volunteerData.displayName || "User";
    const userPhoto = volunteerData.photoUrl || volunteerData.profilePhotoUrl || null;

    // Fetch all user-related data with correct field names
    const [
      campaignsSnapshot1,
      campaignsSnapshot2,
      donationsSnapshot,
      eventsSnapshot1,
      eventsSnapshot2,
      csrApplicationsSnapshot,
      settingsSnapshot,
      sosAlertsSnapshot,
      subscriptionsSnapshot,
    ] = await Promise.all([
      // Try both field names for campaign participants
      db.collection("campaign_participants").where("volunteerId", "==", userId).get(),
      db.collection("campaign_participants").where("odid", "==", userId).get(),
      db.collection("donations").where("donorId", "==", userId).get(),
      // Try both field names for event participants
      db.collection("event_participants").where("userId", "==", userId).get(),
      db.collection("event_participants").where("odid", "==", userId).get(),
      db.collection("csr_volunteer_applications").where("volunteerId", "==", userId).get(),
      db.collection("volunteer_settings").doc(userId).get(),
      db.collection("sos_alerts").where("volunteerId", "==", userId).get(),
      db.collection("monthly_subscriptions").where("userId", "==", userId).get(),
    ]);

    // Merge campaign results (dedupe by campaignId)
    const campaignIds = new Set();
    const allCampaigns = [];
    [...campaignsSnapshot1.docs, ...campaignsSnapshot2.docs].forEach((doc) => {
      const campaignId = doc.data().campaignId || doc.id;
      if (!campaignIds.has(campaignId)) {
        campaignIds.add(campaignId);
        allCampaigns.push(doc);
      }
    });

    // Merge event results (dedupe by eventId)
    const eventIds = new Set();
    const allEvents = [];
    [...eventsSnapshot1.docs, ...eventsSnapshot2.docs].forEach((doc) => {
      const eventId = doc.data().eventId || doc.id;
      if (!eventIds.has(eventId)) {
        eventIds.add(eventId);
        allEvents.push(doc);
      }
    });

    const campaignsCount = allCampaigns.length;
    const eventsCount = allEvents.length;

    // Create PDF
    const tempDir = os.tmpdir();
    const pdfPath = path.join(tempDir, `user_data_${userId}.pdf`);
    const doc = new PDFDocument({ 
      margin: 40, 
      size: "A4",
      bufferPages: true,
    });
    const stream = fs.createWriteStream(pdfPath);
    doc.pipe(stream);

    // Color scheme
    const colors = {
      primary: "#0099B8",
      primaryLight: "#E6F7FA",
      secondary: "#4CAF50",
      secondaryLight: "#E8F5E9",
      text: "#333333",
      textLight: "#666666",
      textMuted: "#999999",
      border: "#E0E0E0",
      success: "#4CAF50",
      warning: "#FF9800",
      danger: "#F44336",
      background: "#F5F9FA",
    };

    const currentDate = new Date();
    const formattedDate = currentDate.toLocaleDateString("en-IN", { 
      day: "numeric", month: "short", year: "numeric" 
    });
    const documentId = `UD-${userId.substring(0, 8).toUpperCase()}`;

    // Calculate donation statistics
    const totalDonations = donationsSnapshot.docs.reduce((sum, d) => sum + (d.data().amount || 0), 0);
    const donationCount = donationsSnapshot.size;
    const avgDonation = donationCount > 0 ? Math.round(totalDonations / donationCount) : 0;
    
    // Calculate months active
    let monthsActive = 0;
    if (volunteerData.createdAt) {
      const registrationDate = volunteerData.createdAt.toDate();
      monthsActive = Math.max(1, Math.ceil((currentDate - registrationDate) / (1000 * 60 * 60 * 24 * 30)));
    }

    // Category breakdown
    const categoryBreakdown = {};
    donationsSnapshot.docs.forEach((donDoc) => {
      const category = donDoc.data().category || "General";
      categoryBreakdown[category] = (categoryBreakdown[category] || 0) + (donDoc.data().amount || 0);
    });

    let pageNumber = 1;
    const totalPages = 4;

    // ========== HELPER FUNCTIONS ==========
    
    const drawHeader = () => {
      // Logo/Brand area
      doc.roundedRect(40, 30, 50, 50, 8)
         .fillAndStroke(colors.primary, colors.primary);
      doc.fontSize(24).fillColor("white").text("C", 52, 43, { width: 26, align: "center" });
      
      doc.fontSize(16).fillColor(colors.primary).text("Connect NGO", 100, 38);
      doc.fontSize(8).fillColor(colors.textMuted).text("Together, Making a Difference", 100, 56);

      // Date and Document ID on right
      doc.fontSize(8).fillColor(colors.textLight).text(`Date: ${formattedDate}`, 400, 38, { align: "right", width: 150 });
      doc.fontSize(8).fillColor(colors.textLight).text(`Document ID: ${documentId}`, 400, 50, { align: "right", width: 150 });
    };

    const drawFooter = (pageNum) => {
      const footerY = 780;
      doc.strokeColor(colors.border).lineWidth(0.5).moveTo(40, footerY).lineTo(555, footerY).stroke();
      doc.fontSize(7).fillColor(colors.textMuted)
         .text("Connect NGO • support@connectngo.com • www.connectngo.com", 40, footerY + 10);
      doc.fontSize(7).fillColor(colors.textMuted)
         .text(`Page ${pageNum} of ${totalPages}`, 500, footerY + 10);
    };

    const drawSectionHeader = (title, iconSymbol, y) => {
      // Draw icon box with a simple shape instead of emoji
      doc.roundedRect(40, y, 24, 24, 4).fillAndStroke(colors.primaryLight, colors.primary);
      doc.fontSize(14).fillColor(colors.primary).text(iconSymbol, 46, y + 5);
      doc.fontSize(12).fillColor(colors.text).text(title, 72, y + 6);
      return y + 35;
    };

    const drawCard = (x, y, width, height, options = {}) => {
      const { 
        borderColor = colors.border, 
        fillColor = "white", 
        shadow = true,
        radius = 8 
      } = options;
      
      if (shadow) {
        doc.roundedRect(x + 2, y + 2, width, height, radius).fill("#F0F0F0");
      }
      doc.roundedRect(x, y, width, height, radius)
         .fillAndStroke(fillColor, borderColor);
    };

    const drawStatBox = (x, y, width, height, label, value, subLabel = "") => {
      drawCard(x, y, width, height, { fillColor: colors.background, shadow: false });
      doc.fontSize(16).fillColor(colors.primary).text(value, x + 10, y + 12, { width: width - 20 });
      doc.fontSize(8).fillColor(colors.textMuted).text(label, x + 10, y + 32, { width: width - 20 });
      if (subLabel) {
        doc.fontSize(7).fillColor(colors.textLight).text(subLabel, x + 10, y + 44, { width: width - 20 });
      }
    };

    const drawBadge = (x, y, text, color) => {
      const badgeWidth = doc.widthOfString(text) + 12;
      doc.roundedRect(x, y, badgeWidth, 16, 8).fillAndStroke(color + "20", color);
      doc.fontSize(7).fillColor(color).text(text, x + 6, y + 4);
      return badgeWidth;
    };

    // ========== PAGE 1: USER PROFILE & ACCOUNT DETAILS ==========
    
    drawHeader();
    
    // Title
    doc.fontSize(18).fillColor(colors.primary).text("Monthly Donation Statement", 40, 95);
    doc.roundedRect(450, 90, 100, 24, 4).fillAndStroke(colors.secondaryLight, colors.secondary);
    doc.fontSize(9).fillColor(colors.secondary).text(`${currentDate.toLocaleString("default", { month: "short" })} ${currentDate.getFullYear()}`, 460, 97);
    doc.fontSize(8).fillColor(colors.textMuted).text(`Page 1 of ${totalPages}`, 500, 115);

    let currentY = 130;

    // User Profile Section
    currentY = drawSectionHeader("User Profile", "[P]", currentY);
    
    drawCard(40, currentY, 515, 100);
    
    // Avatar circle with person icon (no profile photo support in pdfkit without external images)
    doc.circle(85, currentY + 40, 28).fillAndStroke(colors.primaryLight, colors.primary);
    const initials = userName.split(" ").map((n) => n[0]).join("").substring(0, 2).toUpperCase() || "U";
    doc.fontSize(18).fillColor(colors.primary).text(initials, 67, currentY + 32);
    
    // User details - show actual user data
    doc.fontSize(14).fillColor(colors.text).text(userName || "N/A", 125, currentY + 12);
    doc.fontSize(9).fillColor(colors.textLight).text(`Date of Birth: ${volunteerData.dateOfBirth || volunteerData.dob || "N/A"}`, 125, currentY + 32);
    doc.fontSize(9).fillColor(colors.textLight).text(`Gender: ${volunteerData.gender || "N/A"}`, 125, currentY + 47);
    doc.fontSize(9).fillColor(colors.textLight).text(`Email: ${volunteerData.email || "N/A"}`, 125, currentY + 62);
    doc.fontSize(9).fillColor(colors.textLight).text(`Mobile: ${volunteerData.phone || "N/A"}`, 125, currentY + 77);
    
    // Account Details box (moved inside card to prevent overflow)
    drawCard(340, currentY + 8, 205, 84, { fillColor: colors.background, shadow: false, borderColor: colors.border });
    doc.fontSize(8).fillColor(colors.primary).text("Account Details", 350, currentY + 15);
    doc.fontSize(7).fillColor(colors.textMuted).text("User ID:", 350, currentY + 30);
    doc.fontSize(7).fillColor(colors.text).text(userId.substring(0, 10) + "...", 400, currentY + 30);
    doc.fontSize(7).fillColor(colors.textMuted).text("Registered:", 350, currentY + 44);
    doc.fontSize(7).fillColor(colors.text).text(volunteerData.createdAt?.toDate().toLocaleDateString() || "N/A", 400, currentY + 44);
    doc.fontSize(7).fillColor(colors.textMuted).text("Language:", 350, currentY + 58);
    doc.fontSize(7).fillColor(colors.text).text(volunteerData.preferredLanguage || "English", 400, currentY + 58);
    doc.fontSize(7).fillColor(colors.textMuted).text("Status:", 350, currentY + 72);
    // Draw Active badge properly inside the box
    doc.roundedRect(400, currentY + 69, 40, 14, 4).fillAndStroke(colors.success + "30", colors.success);
    doc.fontSize(7).fillColor(colors.success).text("Active", 407, currentY + 71);
    
    currentY += 115;

    // Account Details Section
    currentY = drawSectionHeader("Account Details", "[A]", currentY);
    
    drawCard(40, currentY, 250, 90);
    drawCard(305, currentY, 250, 90);
    
    // Left card
    let leftY = currentY + 12;
    doc.fontSize(8).fillColor(colors.textMuted).text("User ID", 55, leftY);
    doc.fontSize(9).fillColor(colors.text).text(userId.substring(0, 16), 55, leftY + 12);
    doc.fontSize(8).fillColor(colors.textMuted).text("App Registration Date", 55, leftY + 32);
    doc.fontSize(9).fillColor(colors.text).text(volunteerData.createdAt?.toDate().toLocaleDateString() || "N/A", 55, leftY + 44);
    doc.fontSize(8).fillColor(colors.textMuted).text("Account Status", 55, leftY + 62);
    drawBadge(55, leftY + 74, "Active", colors.success);
    
    doc.fontSize(8).fillColor(colors.textMuted).text("Preferred Language", 160, leftY);
    doc.fontSize(9).fillColor(colors.text).text(volunteerData.preferredLanguage || "English", 160, leftY + 12);
    
    // Right card
    let rightY = currentY + 12;
    doc.fontSize(8).fillColor(colors.textMuted).text("User ID", 320, rightY);
    doc.fontSize(9).fillColor(colors.text).text(`NGR-${userId.substring(0, 8).toUpperCase()}`, 320, rightY + 12);
    doc.fontSize(8).fillColor(colors.textMuted).text("App Account Date", 320, rightY + 32);
    doc.fontSize(9).fillColor(colors.text).text(volunteerData.createdAt?.toDate().toLocaleDateString() || "N/A", 320, rightY + 44);
    doc.fontSize(8).fillColor(colors.textMuted).text("Account Type", 320, rightY + 62);
    doc.fontSize(9).fillColor(colors.text).text(volunteerData.accountType || "Standard", 320, rightY + 74);
    
    doc.fontSize(8).fillColor(colors.textMuted).text("Preferred Language", 430, rightY);
    doc.fontSize(9).fillColor(colors.text).text("Monthly", 430, rightY + 12);
    
    currentY += 105;

    // Lifetime Contribution Snapshot
    currentY = drawSectionHeader("Lifetime Contribution Snapshot", "[$]", currentY);
    
    drawCard(40, currentY, 515, 100);
    
    // Stats row
    drawStatBox(55, currentY + 10, 110, 55, "Total Amount Donated", `₹${totalDonations.toLocaleString()}`);
    drawStatBox(175, currentY + 10, 90, 55, "Months Active", `${monthsActive}`, "months");
    
    // P&R info
    doc.fontSize(8).fillColor(colors.textMuted).text("P&R: SC3480", 285, currentY + 20);
    
    drawStatBox(55, currentY + 70, 110, 25, "Average Monthly", `₹${avgDonation}`);
    
    // Impact Categories
    doc.fontSize(8).fillColor(colors.textMuted).text("Impact Category Supports:", 175, currentY + 75);
    const categories = Object.keys(categoryBreakdown).slice(0, 3).join(", ") || "General";
    doc.fontSize(9).fillColor(colors.text).text(categories, 175, currentY + 87);
    
    // Main category highlight
    const mainCategory = Object.keys(categoryBreakdown)[0] || "Education";
    doc.roundedRect(350, currentY + 15, 190, 75, 8).fillAndStroke(colors.secondaryLight, colors.secondary);
    doc.fontSize(10).fillColor(colors.secondary).text(mainCategory, 365, currentY + 45);

    drawFooter(pageNumber++);
    doc.addPage();

    // ========== PAGE 2: IMPACT & UTILIZATION DETAILS ==========
    
    drawHeader();
    doc.fontSize(18).fillColor(colors.primary).text("Monthly Donation Statement", 40, 95);
    doc.fontSize(8).fillColor(colors.textMuted).text(`Page 2 of ${totalPages}`, 500, 97);

    currentY = 125;

    // Impact Breakdown Section
    currentY = drawSectionHeader("Impact & Utilization Details", "[I]", currentY);
    
    doc.fontSize(11).fillColor(colors.text).text("Impact Breakdown", 50, currentY);
    currentY += 20;
    
    drawCard(40, currentY, 515, 120);
    
    // Impact stats grid - use correct count variables
    const impactStats = [
      { label: "Campaigns", count: campaignsCount, icon: "[C]" },
      { label: "Events", count: eventsCount, icon: "[E]" },
      { label: "Donations", count: donationsSnapshot.size, icon: "[$]" },
      { label: "Subscriptions", count: subscriptionsSnapshot.size, icon: "[S]" },
    ];
    
    let impactX = 55;
    const cardWidth = 115;
    impactStats.forEach((item, i) => {
      // Draw mini card for each stat
      drawCard(impactX - 5, currentY + 10, cardWidth, 70, { fillColor: colors.background, shadow: false, borderColor: colors.border });
      
      // Icon and count
      doc.fontSize(8).fillColor(colors.primary).text(item.icon, impactX + 5, currentY + 20);
      doc.fontSize(22).fillColor(colors.primary).text(item.count.toString(), impactX + 35, currentY + 20);
      
      // Label
      doc.fontSize(9).fillColor(colors.text).text(item.label, impactX + 5, currentY + 55);
      doc.fontSize(7).fillColor(colors.textMuted).text("Lifetime", impactX + 70, currentY + 57);
      
      impactX += cardWidth + 10;
    });
    
    currentY += 135;

    // Fund Utilization Summary
    currentY = drawSectionHeader("Fund Utilization Summary", "[F]", currentY);
    
    drawCard(40, currentY, 515, 140);
    
    // Category percentages and colors
    const totalForPercent = Object.values(categoryBreakdown).reduce((a, b) => a + b, 0) || 1;
    const categoryColors = {
      "Education": "#0099B8",
      "Healthcare": "#FF6B6B",
      "Food & Shelter": "#FF9800",
      "Operations": "#9C27B0",
      "Emergency Relief": "#F44336",
      "General": "#607D8B",
      "Community Development": "#4CAF50",
      "Environment": "#8BC34A",
      "Women Empowerment": "#E91E63",
      "Child Welfare": "#03A9F4",
    };
    
    // Get categories with data
    const categoriesWithData = Object.entries(categoryBreakdown).filter(([_, amount]) => amount > 0);
    if (categoriesWithData.length === 0) {
      categoriesWithData.push(["No Data", 1]);
    }
    
    // Legend on left side
    let catY = currentY + 15;
    categoriesWithData.slice(0, 5).forEach(([category, amount], i) => {
      const percent = Math.round((amount / totalForPercent) * 100);
      const catColor = categoryColors[category] || colors.textMuted;
      doc.circle(55, catY + 5, 5).fillAndStroke(catColor, catColor);
      doc.fontSize(9).fillColor(colors.text).text(category, 68, catY);
      doc.fontSize(9).fillColor(catColor).text(`${percent}%`, 180, catY);
      doc.fontSize(7).fillColor(colors.textMuted).text(`Rs. ${amount.toLocaleString()}`, 210, catY);
      catY += 22;
    });
    
    // Draw actual pie chart with colored segments
    const chartX = 380;
    const chartY = currentY + 70;
    const radius = 45;
    
    if (categoriesWithData.length > 0 && totalForPercent > 0) {
      let startAngle = -Math.PI / 2; // Start from top
      categoriesWithData.forEach(([category, amount]) => {
        const sweepAngle = (amount / totalForPercent) * 2 * Math.PI;
        const endAngle = startAngle + sweepAngle;
        const catColor = categoryColors[category] || colors.textMuted;
        
        // Draw pie segment using path
        doc.save();
        doc.path(`M ${chartX} ${chartY} L ${chartX + radius * Math.cos(startAngle)} ${chartY + radius * Math.sin(startAngle)} A ${radius} ${radius} 0 ${sweepAngle > Math.PI ? 1 : 0} 1 ${chartX + radius * Math.cos(endAngle)} ${chartY + radius * Math.sin(endAngle)} Z`)
          .fill(catColor);
        doc.restore();
        
        startAngle = endAngle;
      });
      
      // Center white circle for donut effect
      doc.circle(chartX, chartY, 25).fill("white");
      
      // Total in center
      doc.fontSize(8).fillColor(colors.textMuted).text("Total", chartX - 15, chartY - 10);
      doc.fontSize(10).fillColor(colors.primary).text(`Rs. ${totalForPercent.toLocaleString()}`, chartX - 25, chartY + 3);
    } else {
      // Empty state
      doc.circle(chartX, chartY, radius).fillAndStroke(colors.background, colors.border);
      doc.fontSize(9).fillColor(colors.textMuted).text("No Data", chartX - 20, chartY - 5);
    }
    
    // Key Programs
    doc.fontSize(8).fillColor(colors.textMuted).text("Key Programs Supported:", 55, currentY + 120);
    const programs = Object.keys(categoryBreakdown).filter((k) => categoryBreakdown[k] > 0).slice(0, 3).join(" - ") || "N/A";
    doc.fontSize(8).fillColor(colors.text).text(programs, 160, currentY + 120);
    
    currentY += 155;

    // Personal Info continued
    currentY = drawSectionHeader("Additional Information", "[+]", currentY);
    
    drawCard(40, currentY, 515, 130);
    
    let infoY = currentY + 15;
    const leftColX = 55;
    const midColX = 200;
    const rightColX = 370;
    
    // Row 1: Address details
    doc.fontSize(8).fillColor(colors.textMuted).text("Address", leftColX, infoY);
    doc.fontSize(9).fillColor(colors.text).text(volunteerData.address || volunteerData.location || "Not provided", leftColX, infoY + 12, { width: 130 });
    
    doc.fontSize(8).fillColor(colors.textMuted).text("City", midColX, infoY);
    doc.fontSize(9).fillColor(colors.text).text(volunteerData.city || "Not provided", midColX, infoY + 12);
    
    doc.fontSize(8).fillColor(colors.textMuted).text("State", rightColX, infoY);
    doc.fontSize(9).fillColor(colors.text).text(volunteerData.state || "Not provided", rightColX, infoY + 12);
    
    // Row 2: PIN, Occupation, Languages
    doc.fontSize(8).fillColor(colors.textMuted).text("PIN Code", leftColX, infoY + 35);
    doc.fontSize(9).fillColor(colors.text).text(volunteerData.pinCode || volunteerData.postalCode || "Not provided", leftColX, infoY + 47);
    
    doc.fontSize(8).fillColor(colors.textMuted).text("Occupation", midColX, infoY + 35);
    doc.fontSize(9).fillColor(colors.text).text(volunteerData.occupation || volunteerData.profession || "Not provided", midColX, infoY + 47);
    
    doc.fontSize(8).fillColor(colors.textMuted).text("Languages", rightColX, infoY + 35);
    const languages = Array.isArray(volunteerData.languages) ? volunteerData.languages.join(", ") : (volunteerData.languages || volunteerData.preferredLanguage || "Not provided");
    doc.fontSize(9).fillColor(colors.text).text(languages, rightColX, infoY + 47);
    
    // Row 3: Skills
    doc.fontSize(8).fillColor(colors.textMuted).text("Skills", leftColX, infoY + 70);
    const skills = Array.isArray(volunteerData.skills) ? volunteerData.skills.join(", ") : (volunteerData.skills || "Not provided");
    doc.fontSize(9).fillColor(colors.text).text(skills, leftColX, infoY + 82, { width: 480 });
    
    // Row 4: Interests/Bio
    doc.fontSize(8).fillColor(colors.textMuted).text("Interests/Bio", leftColX, infoY + 100);
    const bio = volunteerData.bio || volunteerData.interests || volunteerData.about || "Not provided";
    doc.fontSize(9).fillColor(colors.text).text(bio.substring(0, 100) + (bio.length > 100 ? "..." : ""), leftColX, infoY + 112, { width: 480 });

    drawFooter(pageNumber++);
    doc.addPage();

    // ========== PAGE 3: TRANSACTION HISTORY ==========
    
    drawHeader();
    doc.fontSize(18).fillColor(colors.primary).text("Transaction History", 40, 95);
    doc.fontSize(8).fillColor(colors.textMuted).text(`Page 3 of ${totalPages}`, 500, 97);

    currentY = 125;

    // Transaction History Table
    currentY = drawSectionHeader("Transaction History", "[T]", currentY);
    
    // Table header
    drawCard(40, currentY, 515, 25, { fillColor: colors.primaryLight, shadow: false });
    doc.fontSize(8).fillColor(colors.primary)
       .text("Date", 55, currentY + 8)
       .text("Transaction ID", 130, currentY + 8)
       .text("Amount", 250, currentY + 8)
       .text("Mode", 320, currentY + 8)
       .text("Status", 400, currentY + 8)
       .text("NGO", 460, currentY + 8);
    
    currentY += 25;
    
    // Table rows
    const donations = donationsSnapshot.docs.slice(0, 10);
    donations.forEach((donDoc, index) => {
      const donData = donDoc.data();
      const rowY = currentY + (index * 25);
      
      if (index % 2 === 0) {
        doc.rect(40, rowY, 515, 25).fill("#FAFAFA");
      }
      
      const txDate = donData.createdAt?.toDate().toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" }) || "N/A";
      const txId = `TXN${donDoc.id.substring(0, 5).toUpperCase()}`;
      
      doc.fontSize(8).fillColor(colors.text)
         .text(txDate, 55, rowY + 8)
         .text(txId, 130, rowY + 8)
         .text(`₹${donData.amount || 0}`, 250, rowY + 8)
         .text(donData.paymentMethod || "Card", 320, rowY + 8);
      
      drawBadge(400, rowY + 5, donData.status || "Success", colors.success);
      
      const ngoName = (donData.ngoName || "NGO").substring(0, 10);
      doc.fontSize(8).fillColor(colors.text).text(ngoName, 460, rowY + 8);
    });
    
    currentY += Math.max(donations.length * 25, 50) + 15;
    
    if (donations.length === 0) {
      doc.fontSize(10).fillColor(colors.textMuted).text("No donation transactions found.", 55, currentY - 30);
    }
    
    doc.fontSize(7).fillColor(colors.textMuted).text(`Last updated: ${formattedDate} • Contact support for any discrepancies`, 55, currentY);
    
    currentY += 25;

    // Receipt Summary
    currentY = drawSectionHeader("Receipt Summary", "[R]", currentY);
    
    // Receipt table header
    drawCard(40, currentY, 515, 25, { fillColor: colors.primaryLight, shadow: false });
    doc.fontSize(8).fillColor(colors.primary)
       .text("Receipt Months", 55, currentY + 8)
       .text("Receipt ID", 180, currentY + 8)
       .text("Issue Date", 320, currentY + 8)
       .text("Document", 430, currentY + 8);
    
    currentY += 25;
    
    // Generate receipt entries from donations
    const receipts = donations.slice(0, 5);
    receipts.forEach((donDoc, index) => {
      const donData = donDoc.data();
      const rowY = currentY + (index * 22);
      
      if (index % 2 === 0) {
        doc.rect(40, rowY, 515, 22).fill("#FAFAFA");
      }
      
      const receiptDate = donData.createdAt?.toDate();
      const monthName = receiptDate ? receiptDate.toLocaleString("default", { month: "short", year: "numeric" }) : "N/A";
      const receiptId = `EM-REC-${(1001 + index).toString()}`;
      const issueDate = receiptDate ? receiptDate.toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" }) : "N/A";
      
      doc.fontSize(8).fillColor(colors.text)
         .text(monthName, 55, rowY + 6)
         .text(receiptId, 180, rowY + 6)
         .text(issueDate, 320, rowY + 6);
      
      doc.fontSize(8).fillColor(colors.primary).text("PDF", 430, rowY + 6);
    });
    
    currentY += Math.max(receipts.length * 22, 30) + 10;
    
    doc.fontSize(7).fillColor(colors.textMuted).text("Tip: Download & save receipts instantly. Contact support for reissues.", 55, currentY);

    drawFooter(pageNumber++);
    doc.addPage();

    // ========== PAGE 4: SETTINGS & PREFERENCES ==========
    
    drawHeader();
    doc.fontSize(18).fillColor(colors.primary).text("Tax & Settings Information", 40, 95);
    doc.fontSize(8).fillColor(colors.textMuted).text(`Page 4 of ${totalPages}`, 500, 97);

    currentY = 125;

    // Tax Benefit Information
    currentY = drawSectionHeader("Tax Benefit Information", "[X]", currentY);
    
    drawCard(40, currentY, 515, 90);
    
    const settings = settingsSnapshot.exists ? settingsSnapshot.data() : {};
    
    // Settings checkboxes
    const taxSettings = [
      { label: "Email Updates", value: settings.emailNotifications !== false },
      { label: "SMS Notifications", value: settings.pushNotifications !== false },
      { label: "Monthly Impact Reports", value: true },
      { label: "Newsletter Subscription", value: settings.campaignUpdates !== false },
    ];
    
    let taxY = currentY + 15;
    taxSettings.forEach((setting, i) => {
      const x = i < 2 ? 55 : 300;
      const y = taxY + (i % 2) * 30;
      
      doc.roundedRect(x, y, 16, 16, 3).stroke(setting.value ? colors.success : colors.border);
      if (setting.value) {
        doc.fontSize(10).fillColor(colors.success).text("v", x + 4, y + 2);
      }
      doc.fontSize(9).fillColor(colors.text).text(setting.label, x + 24, y + 3);
      doc.fontSize(8).fillColor(setting.value ? colors.success : colors.textMuted).text(setting.value ? "Yes" : "No", x + 180, y + 3);
    });
    
    currentY += 105;

    // Subscription Controls
    currentY = drawSectionHeader("Subscription Controls", "[S]", currentY);
    
    drawCard(40, currentY, 515, 80);
    
    const subControls = [
      { label: "Pause Subscription Allowed", value: true },
      { label: "Cancel Anytime Policy", value: true },
      { label: "Refund Policy Summary", value: true },
    ];
    
    let subY = currentY + 15;
    subControls.forEach((control, i) => {
      doc.roundedRect(55, subY, 16, 16, 3).stroke(colors.success);
      doc.fontSize(10).fillColor(colors.success).text("v", 59, subY + 2);
      doc.fontSize(9).fillColor(colors.text).text(control.label, 80, subY + 3);
      subY += 22;
    });
    
    currentY += 95;

    // Campaign & Event Participation
    currentY = drawSectionHeader("Participation Summary", "[#]", currentY);
    
    drawCard(40, currentY, 250, 80);
    drawCard(305, currentY, 250, 80);
    
    // Campaigns - use correct count variable
    doc.fontSize(10).fillColor(colors.primary).text("[C] Campaigns", 55, currentY + 15);
    doc.fontSize(24).fillColor(colors.text).text(campaignsCount.toString(), 55, currentY + 35);
    doc.fontSize(8).fillColor(colors.textMuted).text("Total Participated", 55, currentY + 58);
    
    // Events - use correct count variable
    doc.fontSize(10).fillColor(colors.primary).text("[E] Events", 320, currentY + 15);
    doc.fontSize(24).fillColor(colors.text).text(eventsCount.toString(), 320, currentY + 35);
    doc.fontSize(8).fillColor(colors.textMuted).text("Total Attended", 320, currentY + 58);
    
    currentY += 95;

    // Declaration
    currentY = drawSectionHeader("Declaration", "[D]", currentY);
    
    drawCard(40, currentY, 515, 60);
    doc.fontSize(8).fillColor(colors.textLight)
       .text("This is a system-generated document and requires no physical signature.", 55, currentY + 15, { width: 490 })
       .text("All information presented is accurate as of the generation date. For corrections or disputes,", 55, currentY + 30, { width: 490 })
       .text("please contact support@connectngo.com within 30 days.", 55, currentY + 45, { width: 490 });
    
    currentY += 75;

    // Final footer
    drawCard(40, currentY, 515, 50, { fillColor: colors.background, shadow: false });
    doc.fontSize(8).fillColor(colors.textMuted).text("Thank you for being a valued member of Connect NGO!", 200, currentY + 12);
    doc.fontSize(8).fillColor(colors.textMuted).text("Together, we are making a difference in communities.", 200, currentY + 27);

    drawFooter(pageNumber);

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
    const exportRef = await db.collection("data_exports").add({
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      pdfData: pdfBase64,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      sent: false,
      fileName: `ConnectNGO_Statement_${new Date().toISOString().split("T")[0]}.pdf`,
    });

    // Try to send email using nodemailer if configured
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
                  <li>Lifetime Contribution Snapshot</li>
                  <li>Impact & Utilization Details</li>
                  <li>Transaction History</li>
                  <li>Receipt Summary</li>
                  <li>Settings & Preferences</li>
                </ul>
              </div>
              
              <p style="color: #666; font-size: 14px; margin-top: 20px;">
                <strong>Note:</strong> This document contains sensitive personal information. Please store it securely.
              </p>
              
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
            filename: `ConnectNGO_Statement_${new Date().toISOString().split("T")[0]}.pdf`,
            path: pdfPath,
            contentType: "application/pdf",
          },
        ],
      };

      if (emailConfig.auth.user && emailConfig.auth.user !== "connectngo.notifications@gmail.com") {
        await transporter.sendMail(mailOptions);
        await exportRef.update({ sent: true });
        console.log(`Data export email sent to ${userEmail}`);
      } else {
        console.log(`Email credentials not configured. Export stored in Firestore for user: ${userId}`);
      }
    } catch (emailError) {
      console.error("Email sending failed, but export is stored:", emailError.message);
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

/**
 * HTTPS Callable function to verify Razorpay checkout signature and save donations
 */
exports.verifyAndSaveDonation = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required");
  }

  const { 
    paymentId, 
    orderId, 
    signature, 
    amount, 
    donorName, 
    donorEmail, 
    donorPhone, 
    campaignId, 
    campaignTitle, 
    campaignType, 
    isAnonymous, 
    ngoId, 
    message 
  } = data;

  if (!paymentId || !signature || !amount || !campaignId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing payment verification parameters");
  }

  // Retrieve Razorpay config key secret dynamically from database
  let keySecret = "your-app-password";
  try {
    const configDoc = await db.collection("app_config").doc("razorpay").get();
    if (configDoc.exists) {
      keySecret = configDoc.data().keySecret || keySecret;
    }
  } catch (err) {
    console.error("Failed to read Razorpay secret:", err);
  }

  const crypto = require("crypto");
  const body = orderId + "|" + paymentId;
  const expectedSignature = crypto
    .createHmac("sha256", keySecret)
    .update(body.toString())
    .digest("hex");

  if (expectedSignature !== signature) {
    throw new functions.https.HttpsError("permission-denied", "Razorpay payment verification signature mismatch");
  }

  const donationRef = db.collection("donations").doc();
  const donationData = {
    id: donationRef.id,
    paymentId,
    orderId,
    signature,
    amount: Number(amount),
    status: "success",
    paymentMethod: "razorpay",
    donorName: isAnonymous ? "Anonymous" : donorName,
    donorEmail: isAnonymous ? "" : donorEmail,
    donorPhone: isAnonymous ? "" : donorPhone,
    donorId: context.auth.uid,
    isAnonymous: Boolean(isAnonymous),
    campaignId,
    campaignTitle,
    campaignType,
    ngoId: ngoId || "",
    message: message || "",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await donationRef.set(donationData);
  console.log(`Donation verified and saved: ${donationRef.id}`);

  return { success: true, donationId: donationRef.id };
});

