const assert = require("node:assert/strict");
const test = require("node:test");
const {
  applyMinorUnitDebit,
  requireIso4217Currency,
  requirePositiveMinorUnits,
} = require("../lib/money.js");

test("accepts ISO currency codes and normalizes their case", () => {
  assert.equal(requireIso4217Currency("ngn"), "NGN");
  assert.equal(requireIso4217Currency("KWD"), "KWD");
  assert.equal(requireIso4217Currency("xAD"), "XAD");
  assert.equal(requireIso4217Currency("ZWG"), "ZWG");
  assert.throws(() => requireIso4217Currency("ZZZ"), /Unsupported ISO 4217/);
  assert.throws(() => requireIso4217Currency("XXX"), /Unsupported ISO 4217/);
  assert.throws(() => requireIso4217Currency("ANG"), /Unsupported ISO 4217/);
  assert.throws(() => requireIso4217Currency("XAG"), /Unsupported ISO 4217/);
});

test("requires positive safe integer minor units", () => {
  assert.equal(requirePositiveMinorUnits(1234), 1234);
  for (const amount of [0, -1, 1.25, Number.MAX_SAFE_INTEGER + 1, "100"]) {
    assert.throws(() => requirePositiveMinorUnits(amount));
  }
});

test("debits integer minor units atomically with an idempotent ledger entry", () => {
  const debit = {
    amountMinor: 1250,
    currencyCode: "USD",
    title: "Wallet purchase",
    idempotencyKey: "1234567890abcdef",
  };
  const updated = applyMinorUnitDebit(
    {
      currencyCode: "USD",
      balanceMinor: 5000,
      transactions: {previous: {amountMinor: 100}},
    },
    debit,
  );

  assert.equal(updated.balanceMinor, 3750);
  assert.equal(updated.currencyCode, "USD");
  assert.deepEqual(updated.transactions.previous, {amountMinor: 100});
  const ledgerEntry = updated.transactions[debit.idempotencyKey];
  assert.deepEqual(ledgerEntry, {
    amountMinor: 1250,
    currencyCode: "USD",
    title: "Wallet purchase",
    isCredit: false,
    createdAt: ledgerEntry.createdAt,
  });
  assert.equal(Number.isSafeInteger(ledgerEntry.createdAt), true);
  assert.ok(ledgerEntry.createdAt > 0);
});

test("does not mutate a wallet for insufficient balance or duplicate idempotency key", () => {
  const debit = {
    amountMinor: 1250,
    currencyCode: "NGN",
    title: "Wallet purchase",
    idempotencyKey: "1234567890abcdef",
  };
  assert.equal(applyMinorUnitDebit({balanceMinor: 1000}, debit), undefined);
  assert.equal(
    applyMinorUnitDebit(
      {
        balanceMinor: 5000,
        transactions: {[debit.idempotencyKey]: {amountMinor: 1250}},
      },
      debit,
    ),
    undefined,
  );
});
