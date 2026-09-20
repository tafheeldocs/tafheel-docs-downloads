const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();

// ============================================================
// AUTOMATIC EXPIRY REMINDER
// Runs every day at 9:00 AM Dubai time
// Reminders: 30 days, 7 days, 1 day
// ============================================================

exports.checkExpiryReminders = onSchedule(
  {
    schedule: "0 9 * * *",
    timeZone: "Asia/Dubai",
  },
  async () => {
    console.log("Starting TAFHEEL DOCS expiry check...");

    const today = new Date();

    // ----------------------------------------------------------
    // Helper: calculate days remaining
    // ----------------------------------------------------------
    function daysUntilExpiry(expiryString) {
      if (!expiryString) return null;

      const expiry = new Date(`${expiryString}T00:00:00`);

      if (isNaN(expiry.getTime())) {
        return null;
      }

      const todayOnly = new Date(
        today.getFullYear(),
        today.getMonth(),
        today.getDate()
      );

      const expiryOnly = new Date(
        expiry.getFullYear(),
        expiry.getMonth(),
        expiry.getDate()
      );

      return Math.round(
        (expiryOnly - todayOnly) / (1000 * 60 * 60 * 24)
      );
    }

    // ----------------------------------------------------------
    // Send notification
    // ----------------------------------------------------------
    async function sendNotification({
      userId,
      title,
      body,
      documentType,
      expiryDate,
      daysLeft,
    }) {
      try {
        const userDoc = await db
          .collection("users")
          .doc(userId)
          .get();

        if (!userDoc.exists) {
          console.log(`User not found: ${userId}`);
          return;
        }

        const userData = userDoc.data();

        const fcmToken = userData.fcmToken;

        if (!fcmToken) {
          console.log(`No FCM token for user: ${userId}`);
          return;
        }

        // ------------------------------------------------------
        // Duplicate prevention
        // ------------------------------------------------------

        const notificationId =
          `${documentType}_${expiryDate}_${daysLeft}`;

        const logRef = db
          .collection("users")
          .doc(userId)
          .collection("notificationLogs")
          .doc(notificationId);

        const existingLog = await logRef.get();

        if (existingLog.exists) {
          console.log(
            `Already sent: ${notificationId}`
          );
          return;
        }

        // ------------------------------------------------------
        // Send FCM notification
        // ------------------------------------------------------

        const admin = require("firebase-admin");

        await admin.messaging().send({
          token: fcmToken,

          notification: {
            title: title,
            body: body,
          },

          data: {
            documentType: documentType,
            expiryDate: expiryDate,
            daysLeft: String(daysLeft),
          },

          android: {
            notification: {
              channelId: "tafheel_expiry",
              sound: "default",
            },
          },
        });

        // ------------------------------------------------------
        // Save notification log
        // ------------------------------------------------------

        await logRef.set({
          documentType: documentType,
          expiryDate: expiryDate,
          daysLeft: daysLeft,
          sentAt: FieldValue.serverTimestamp(),
        });

        console.log(
          `Notification sent: ${documentType} - ${daysLeft} days`
        );
      } catch (error) {
        console.error(
          `Notification error: ${documentType}`,
          error
        );
      }
    }

    // ==========================================================
    // COMPANY DOCUMENTS
    // ==========================================================

    const companiesSnapshot = await db
      .collection("companies")
      .get();

    for (const companyDoc of companiesSnapshot.docs) {
      const company = companyDoc.data();

      const companyName =
        company.companyName || "Company";

      const userId = company.userId;

      if (!userId) {
        console.log(
          `No userId in company: ${companyDoc.id}`
        );
        continue;
      }

      const companyDocuments = [
        {
          type: "Trade License",
          expiry: company.tradeExpiry,
        },
        {
          type: "Tenancy Contract",
          expiry: company.tenancyExpiry,
        },
        {
          type: "Establishment Card",
          expiry: company.establishmentExpiry,
        },
      ];

      for (const document of companyDocuments) {
        const daysLeft =
          daysUntilExpiry(document.expiry);

        if ([30, 7, 1].includes(daysLeft)) {
          await sendNotification({
            userId: userId,

            title:
              `⚠️ ${document.type} Expiry Reminder`,

            body:
              `${companyName}'s ${document.type} expires in ${daysLeft} day(s).`,

            documentType:
              `${companyDoc.id}_${document.type}`,

            expiryDate:
              document.expiry,

            daysLeft:
              daysLeft,
          });
        }
      }
    }

    // ==========================================================
    // EMPLOYEE DOCUMENTS
    // ==========================================================

    const usersSnapshot = await db
      .collection("users")
      .get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;

      const employeesSnapshot = await db
        .collection("users")
        .doc(userId)
        .collection("employees")
        .get();

      for (const employeeDoc of employeesSnapshot.docs) {
        const employee = employeeDoc.data();

        const employeeName =
          employee.employeeName || "Employee";

        const employeeDocuments = [
          {
            type: "Employee Visa",
            expiry: employee.visaExpiry,
          },
          {
            type: "Labour Card",
            expiry: employee.laborExpiry,
          },
          {
            type: "OHC Card",
            expiry: employee.ohcExpiry,
          },
        ];

        for (const document of employeeDocuments) {
          const daysLeft =
            daysUntilExpiry(document.expiry);

          if ([30, 7, 1].includes(daysLeft)) {
            await sendNotification({
              userId: userId,

              title:
                `⚠️ ${document.type} Expiry Reminder`,

              body:
                `${employeeName}'s ${document.type} expires in ${daysLeft} day(s).`,

              documentType:
                `${employeeDoc.id}_${document.type}`,

              expiryDate:
                document.expiry,

              daysLeft:
                daysLeft,
            });
          }
        }
      }
    }

    console.log(
      "TAFHEEL DOCS expiry check completed."
    );

    return null;
  }
);