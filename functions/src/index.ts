import { initializeApp } from "firebase-admin/app";
import { getDatabase } from "firebase-admin/database";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import {
  applyMinorUnitDebit,
  requireIso4217Currency,
  requirePositiveMinorUnits,
} from "./money";

initializeApp();

type DebitRequest = {
  amountMinor?: unknown;
  currencyCode?: unknown;
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

export const debitWallet = onCall({enforceAppCheck: true}, async (request) => {
  const uid = requireUser(request);
  const data = request.data as DebitRequest;
  const currencyCode = requireIso4217Currency(data.currencyCode);
  const amountMinor = requirePositiveMinorUnits(data.amountMinor);
  const title = typeof data.title === "string" ? data.title.trim() : "";
  const idempotencyKey =
    typeof data.idempotencyKey === "string" ? data.idempotencyKey.trim() : "";

  if (
    !title ||
    title.length > 120 ||
    !/^[A-Za-z0-9_-]{16,128}$/.test(idempotencyKey)
  ) {
    throw new HttpsError("invalid-argument", "Invalid transaction metadata.");
  }

  const walletRef = getDatabase().ref(
    `users/${uid}/wallets/${currencyCode}`,
  );
  const result = await walletRef.transaction((current) => {
    return applyMinorUnitDebit(current, {
      amountMinor,
      currencyCode,
      title,
      idempotencyKey,
    });
  });

  if (!result.committed) {
    throw new HttpsError(
      "failed-precondition",
      "Insufficient balance or duplicate transaction.",
    );
  }
  return {ok: true, idempotencyKey, currencyCode, amountMinor};
});
