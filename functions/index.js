const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

exports.listAuthUsers = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in is required.");
  }

  const callerEmail = (request.auth.token.email || "").toLowerCase();
  const isAdmin = request.auth.token.admin === true || callerEmail === "admin@twezimbe.co.ug";
  if (!isAdmin) {
    throw new HttpsError("permission-denied", "Admin access required.");
  }

  const users = [];
  let pageToken;

  do {
    const page = await admin.auth().listUsers(1000, pageToken);
    for (const user of page.users) {
      users.push({
        uid: user.uid,
        email: user.email || "",
        displayName: user.displayName || "",
        phoneNumber: user.phoneNumber || "",
        photoURL: user.photoURL || "",
        disabled: user.disabled === true,
        creationTime: user.metadata.creationTime || "",
        lastSignInTime: user.metadata.lastSignInTime || "",
      });
    }
    pageToken = page.pageToken;
  } while (pageToken);

  return { users };
});

exports.onLoanApplicationCreated = onDocumentCreated(
  { document: "loan_applications/{applicationId}", region: "us-central1" },
  async (event) => {
    const data = event.data && event.data.data ? event.data.data() : null;
    if (!data) {
      return;
    }

    const applicantName = (data.userName || "Client").toString();
    const amount = Number(data.amount || 0);
    const applicationId = (data.applicationId || event.params.applicationId || "").toString();

    const admins = await admin
      .firestore()
      .collection("users")
      .where("role", "==", "admin")
      .get();

    const batch = admin.firestore().batch();
    admins.docs.forEach((adminDoc) => {
      const notifRef = admin.firestore().collection("notifications").doc();
      batch.set(notifRef, {
        id: notifRef.id,
        userId: adminDoc.id,
        title: "New Loan Application",
        message: `${applicantName} submitted ${applicationId} for UGX ${amount}.`,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    if (!admins.empty) {
      await batch.commit();
    }
  },
);

exports.onLoanDecisionUpdated = onDocumentUpdated(
  { document: "loan_applications/{applicationId}", region: "us-central1" },
  async (event) => {
    const before = event.data && event.data.before && event.data.before.data
      ? event.data.before.data()
      : null;
    const after = event.data && event.data.after && event.data.after.data
      ? event.data.after.data()
      : null;

    if (!after) {
      return;
    }

    const beforeStatus = ((before && before.status) || "").toString().toLowerCase();
    const afterStatus = (after.status || "").toString().toLowerCase();
    if (beforeStatus === afterStatus) {
      return;
    }

    if (afterStatus !== "approved" && afterStatus !== "rejected") {
      return;
    }

    const userId = (after.userId || "").toString();
    if (!userId) {
      return;
    }

    const notifRef = admin.firestore().collection("notifications").doc();
    await notifRef.set({
      id: notifRef.id,
      userId,
      title: afterStatus === "approved" ? "Loan Approved" : "Loan Rejected",
      message: afterStatus === "approved"
        ? "Your loan application was approved."
        : "Your loan application was rejected.",
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  },
);

exports.onNotificationCreatedSendPush = onDocumentCreated(
  { document: "notifications/{notificationId}", region: "us-central1" },
  async (event) => {
    const data = event.data && event.data.data ? event.data.data() : null;
    if (!data) {
      return;
    }

    const userId = (data.userId || "").toString();
    if (!userId) {
      return;
    }

    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    if (!userDoc.exists) {
      return;
    }

    const token = ((userDoc.data() || {}).fcmToken || "").toString();
    if (!token) {
      return;
    }

    await admin.messaging().send({
      token,
      notification: {
        title: (data.title || "Twezimbe").toString(),
        body: (data.message || "").toString(),
      },
      data: {
        type: "in_app_notification",
        notificationId: (data.id || event.params.notificationId || "").toString(),
      },
    });
  },
);
