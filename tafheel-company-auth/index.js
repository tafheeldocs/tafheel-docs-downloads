const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();

// ============================================================
// CREATE COMPANY ACCOUNT
// ============================================================

exports.createCompanyAccount = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    // ==========================================================
    // 1. USER MUST BE LOGGED IN
    // ==========================================================

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in."
      );
    }

    // ==========================================================
    // 2. CHECK ADMIN
    // ==========================================================

    const callerUid = request.auth.uid;
    const callerEmail =
      request.auth.token.email?.toString().trim().toLowerCase() || "";

    let isAdmin = false;

    // ----------------------------------------------------------
    // Temporary support for your existing admin account
    // ----------------------------------------------------------

    if (callerEmail === "tafheel@gmail.com") {
      isAdmin = true;
    }

    // ----------------------------------------------------------
    // Also check users/{uid} role
    // ----------------------------------------------------------

    const adminUserDoc = await db
      .collection("users")
      .doc(callerUid)
      .get();

    if (adminUserDoc.exists) {
      const adminData = adminUserDoc.data();

      const role =
        adminData?.role?.toString().trim().toLowerCase() || "";

      if (role === "admin") {
        isAdmin = true;
      }
    }

    if (!isAdmin) {
      throw new HttpsError(
        "permission-denied",
        "Only an administrator can create company accounts."
      );
    }

    // ==========================================================
    // 3. RECEIVE DATA FROM FLUTTER
    // ==========================================================

    const data = request.data || {};

    const companyName =
      data.companyName?.toString().trim() || "";

    const loginEmail =
      data.loginEmail?.toString().trim().toLowerCase() || "";

    const password =
      data.password?.toString() || "";

    const tradeLicense =
      data.tradeLicense?.toString().trim() || "";

    const tradeExpiry =
      data.tradeExpiry?.toString().trim() || "";

    const tenancy =
      data.tenancy?.toString().trim() || "";

    const tenancyExpiry =
      data.tenancyExpiry?.toString().trim() || "";

    const establishmentCard =
      data.establishmentCard?.toString().trim() || "";

    const establishmentExpiry =
      data.establishmentExpiry?.toString().trim() || "";

    const authorizedPerson =
      data.authorizedPerson?.toString().trim() || "";

    const mobile =
      data.mobile?.toString().trim() || "";

    const email =
      data.email?.toString().trim().toLowerCase() || "";

    // ==========================================================
    // 4. VALIDATION
    // ==========================================================

    if (companyName.isEmpty) {
      throw new HttpsError(
        "invalid-argument",
        "Company Name is required."
      );
    }

    if (loginEmail.isEmpty) {
      throw new HttpsError(
        "invalid-argument",
        "Login Email is required."
      );
    }

    if (!loginEmail.includes("@")) {
      throw new HttpsError(
        "invalid-argument",
        "Please enter a valid Login Email."
      );
    }

    if (password.length < 6) {
      throw new HttpsError(
        "invalid-argument",
        "Password must contain at least 6 characters."
      );
    }

    // ==========================================================
    // 5. CREATE FIREBASE AUTH USER
    // ==========================================================

    let newUser = null;
    let companyRef = null;

    try {
      newUser = await getAuth().createUser({
        email: loginEmail,
        password: password,
        displayName: companyName,
        disabled: false,
      });

      // ========================================================
      // 6. CREATE COMPANY DOCUMENT
      // ========================================================

      companyRef = db.collection("companies").doc();

      await companyRef.set({
        companyName: companyName,

        tradeLicense: tradeLicense,
        tradeExpiry: tradeExpiry,

        tenancy: tenancy,
        tenancyExpiry: tenancyExpiry,

        establishmentCard: establishmentCard,
        establishmentExpiry: establishmentExpiry,

        authorizedPerson: authorizedPerson,

        mobile: mobile,

        email: email,

        // Login information - NO PASSWORD stored
        loginEmail: loginEmail,

        // Link Firebase Authentication user
        authUid: newUser.uid,

        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // ========================================================
      // 7. CREATE ROLE DOCUMENT
      // ========================================================

      await db
        .collection("users")
        .doc(newUser.uid)
        .set({
          role: "company",

          companyId: companyRef.id,

          companyName: companyName,

          email: loginEmail,

          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });

      // ========================================================
      // 8. RETURN SUCCESS
      // ========================================================

      return {
        success: true,

        message: "Company account created successfully.",

        companyId: companyRef.id,

        uid: newUser.uid,

        loginEmail: loginEmail,
      };
    } catch (error) {
      console.error("CREATE COMPANY ERROR:", error);

      // ========================================================
      // CLEANUP IF SOMETHING FAILED
      // ========================================================

      if (companyRef !== null) {
        try {
          await companyRef.delete();
        } catch (deleteCompanyError) {
          console.error(
            "Company cleanup error:",
            deleteCompanyError
          );
        }
      }

      if (newUser !== null) {
        try {
          await getAuth().deleteUser(newUser.uid);
        } catch (deleteUserError) {
          console.error(
            "Auth cleanup error:",
            deleteUserError
          );
        }
      }

      // ========================================================
      // FRIENDLY FIREBASE AUTH ERRORS
      // ========================================================

      if (error.code === "auth/email-already-exists") {
        throw new HttpsError(
          "already-exists",
          "This login email is already registered."
        );
      }

      if (error.code === "auth/invalid-email") {
        throw new HttpsError(
          "invalid-argument",
          "The login email is invalid."
        );
      }

      if (error.code === "auth/invalid-password") {
        throw new HttpsError(
          "invalid-argument",
          "The password is invalid. Use at least 6 characters."
        );
      }

      // Keep callable errors
      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        error.message || "Unable to create company account."
      );
    }
  }
);