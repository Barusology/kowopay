import { initializeApp } from "firebase-admin/app";
import { getDatabase } from "firebase-admin/database";
import { HttpsError, onCall } from "firebase-functions/v2/https";

initializeApp();

type DebitRequest = {
  amount?: unknown;
  title?: unknown;
  idempotencyKey?: unknown;
};

function requireUser(request: { auth?: { uid: string } | null }): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  return uid;
}

function requirePositiveAmount(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) {
    throw new HttpsError("invalid-argument", "Amount must be positive.");
  }
  return Math.round(value * 100) / 100;
}

export const debitWallet = onCall(async (request) => {
  const uid = requireUser(request);
  const data = request.data as DebitRequest;
  const amount = requirePositiveAmount(data.amount);
  const title = typeof data.title === "string" ? data.title.trim() : "";
  const idempotencyKey =
    typeof data.idempotencyKey === "string" ? data.idempotencyKey.trim() : "";

  if (!title || title.length > 120 || !idempotencyKey || idempotencyKey.length > 128) {
    throw new HttpsError("invalid-argument", "Invalid transaction metadata.");
  }

  const userRef = getDatabase().ref(`users/${uid}`);
  const result = await userRef.transaction((current) => {
    const user = (current ?? {}) as Record<string, unknown>;
    const balance = typeof user.balance === "number" ? user.balance : 0;
    const transactions =
      user.transactions && typeof user.transactions === "object"
        ? {...(user.transactions as Record<string, unknown>)}
        : {};

    if (transactions[idempotencyKey]) return;
    if (balance < amount) return;

    transactions[idempotencyKey] = {
      title,
      amount,
      isCredit: false,
      createdAt: Date.now(),
    };
    return {...user, balance: balance - amount, transactions};
  });

  if (!result.committed) {
    throw new HttpsError("failed-precondition", "Insufficient balance or duplicate transaction.");
  }
  return {ok: true, idempotencyKey};
});
