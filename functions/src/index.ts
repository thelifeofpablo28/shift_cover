import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

interface TimeOffRequest {
  startDate: admin.firestore.Timestamp;
  endDate: admin.firestore.Timestamp;
  roles?: string[];
  status?: string;
  userId?: string;
  [key: string]: unknown;
}

interface StaffingRequirements {
  [day: string]: { [role: string]: number } | undefined;
  totalStaffPerRole?: { [role: string]: number };
}

// ===== Manager Promotion/Demotion Callable Function =====

export const updateUserRole = functions.https.onCall(
  async (req) => {
    const data = req.data;
    const organisationId: string = data.organisationId;
    const employeeId: string = data.employeeId;
    const newRole: string = data.newRole;

    if (!organisationId || !employeeId || !newRole) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required parameters: organisationId, employeeId, newRole"
      );
    }

    try {
      const userRef = db
        .collection("organisations")
        .doc(organisationId)
        .collection("users")
        .doc(employeeId);

      await userRef.update({role: newRole});

      return {success: true, message: `Role updated to ${newRole}`};
    } catch (error: unknown) {
      if (error instanceof Error) {
        throw new functions.https.HttpsError("unknown", error.message, error);
      } else {
        throw new functions.https.HttpsError(
          "unknown", "An unknown error occurred"
        );
      }
    }
  }
);

// ===== Time-Off Request Processing & Enforcement =====
/**
 * Processes a time-off request by checking staffing requirements and
 * organisation settings, then updates the request status accordingly.
 * @param {string} organisationId - The ID of the organisation.
 * @param {string} requestId - The ID of the time-off request.
 * @return {Promise<void>} Resolves when processing is complete.
 */
async function processTimeOffRequest(
  organisationId: string,
  requestId: string
): Promise<void> {
  const requestRef = db
    .collection("organisations")
    .doc(organisationId)
    .collection("timeOffRequests")
    .doc(requestId);
  const requestSnap = await requestRef.get();

  if (!requestSnap.exists) return;
  const request = requestSnap.data() as TimeOffRequest;

  if (!request.startDate || !request.endDate) return;

  const orgRef = db.collection("organisations").doc(organisationId);
  const orgSnap = await orgRef.get();
  if (!orgSnap.exists) return;

  const orgData = orgSnap.data() || {};
  const staffingRequirements: StaffingRequirements =
    orgData.staffingRequirements || {};
  const minStaffRequired: boolean = orgData.minStaffRequired || false;
  const autoApprove: boolean = orgData.autoApprove || false;
  const autoRejectIfBelowMin: boolean = orgData.autoRejectIfBelowMin || false;

  const start = request.startDate.toDate();
  const end = request.endDate.toDate();

  // Placeholder logic:
  let newStatus = "pending";

  if (autoApprove) {
    newStatus = "approved";
  } else if (autoRejectIfBelowMin) {
    const enoughStaff = true;
    newStatus = enoughStaff ? "approved" : "rejected";
  }

  if (request.status !== newStatus) {
    await requestRef.update({status: newStatus});
  }
}

// ===== Push Notifications for Time-Off Request Status =====

/**
 * Sends a Firebase Cloud Messaging notification to the user about the
 * status update of their time-off request.
 * @param {string} organisationId - The ID of the organisation.
 * @param {string} requestId - The ID of the time-off request.
 * @param {string} status - The new status of the time-off request.
 * @return {Promise<void>} Resolves when the notification is sent.
 */
async function sendTimeOffStatusNotification(
  organisationId: string,
  requestId: string,
  status: string
): Promise<void> {
  const requestRef = db
    .collection("organisations")
    .doc(organisationId)
    .collection("timeOffRequests")
    .doc(requestId);

  const requestSnap = await requestRef.get();
  if (!requestSnap.exists) return;

  const request = requestSnap.data() as TimeOffRequest;
  const userId = request.userId;
  if (!userId) return;

  const userRef = db
    .collection("organisations")
    .doc(organisationId)
    .collection("users")
    .doc(userId);

  const userSnap = await userRef.get();
  if (!userSnap.exists) return;

  const userData = userSnap.data();
  const tokens: string[] = userData?.fcmTokens || [];
  if (!tokens.length) return;

  const message = {
    notification: {
      title: "Time-Off Request Update",
      body: `Your time-off request has been ${status}.`,
    },
    tokens: tokens,
  };

  try {
    const response = await admin.messaging().sendMulticast(message);
    console.log(
      `Sent notification to user 
      ${userId}. Success: ${response.successCount}, ` +
      `Failure: ${response.failureCount}`
    );
  } catch (error) {
    console.error("Error sending FCM notification:", error);
  }
}

// ===== Onboarding Completion Callable =====

export const setOnboardingCompleted = functions.https.onCall(
  async (req) => {
    const data = req.data;

    const organisationId: string = data.organisationId;
    const userId: string = data.userId;

    if (!organisationId || !userId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required parameters: organisationId, userId"
      );
    }

    try {
      const userRef = db
        .collection("organisations")
        .doc(organisationId)
        .collection("users")
        .doc(userId);

      await userRef.update({onboardingCompleted: true});

      return {success: true, message: "Onboarding status updated"};
    } catch (error: unknown) {
      if (error instanceof Error) {
        throw new functions.https.HttpsError("unknown", error.message, error);
      } else {
        throw new functions.https.HttpsError(
          "unknown", "An unknown error occurred"
        );
      }
    }
  }
);

// ===== Theme Preference Callable =====

export const setThemePreference = functions.https.onCall(
  async (req) => {
    const data = req.data;

    const organisationId: string = data.organisationId;
    const userId: string = data.userId;
    const theme: string = data.theme;

    if (!organisationId || !userId || !theme) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required parameters: organisationId, userId, theme"
      );
    }

    try {
      const userRef = db
        .collection("organisations")
        .doc(organisationId)
        .collection("users")
        .doc(userId);

      await userRef.update({themePreference: theme});

      return {success: true, message: "Theme preference updated"};
    } catch (error: unknown) {
      if (error instanceof Error) {
        throw new functions.https.HttpsError("unknown", error.message, error);
      } else {
        throw new functions.https.HttpsError(
          "unknown", "An unknown error occurred"
        );
      }
    }
  }
);
