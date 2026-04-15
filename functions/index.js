const { onCall, HttpsError } = require("firebase-functions/v2/https");
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
