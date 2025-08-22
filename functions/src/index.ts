/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";
// import {onRequest} from "firebase-functions/https";
// import * as logger from "firebase-functions/logger";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

import * as admin from "firebase-admin";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";

admin.initializeApp();
const db = admin.firestore();

interface FriendRequest {
  from: string;
  to: string;
  uLow: string;
  uHigh: string;
  status: "pending" | "accepted" | "declined" | "canceled";
  uid: string;
}

export const onFriendRequestAccepted = onDocumentUpdated(
  {
    document: "friend_requests/{pairId}",
  },
  async (event) => {
    const before = event.data?.before.data() as FriendRequest | undefined;
    const after = event.data?.after.data() as FriendRequest | undefined;
    if (!before || !after) return;

    if (before.status !== "pending") return;

    if (after.status === "declined") {
      await db.runTransaction(async (tx) => {
        if (event.data != null) {
          tx.delete(event.data.after.ref);
        }
      });
      return;
    }

    if (after.status !== "accepted") return;

    const fromUid = after.from;
    const toUid = after.to;

    const aFriendRef = db.doc(`users/${fromUid}/friends/${toUid}`);
    const bFriendRef = db.doc(`users/${toUid}/friends/${fromUid}`);

    await db.runTransaction(async (tx) => {
      const [aEdgeSnap, bEdgeSnap] = await Promise.all([
        tx.get(aFriendRef), tx.get(bFriendRef),
      ]);

      // Idempotency: if edges already exist, do nothing further
      if (aEdgeSnap.exists && bEdgeSnap.exists) {
        if (event.data != null) {
          tx.delete(event.data.after.ref);
        }
        return;
      }

      const now = admin.firestore.FieldValue.serverTimestamp();

      if (!aEdgeSnap.exists) {
        tx.set(aFriendRef, {createdAt: now});
      }
      if (!bEdgeSnap.exists) {
        tx.set(bFriendRef, {createdAt: now});
      }

      if (event.data != null) {
        tx.delete(event.data.after.ref);
      }
    });
  }
);
