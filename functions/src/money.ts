import { HttpsError } from "firebase-functions/v2/https";

const ISO_4217_CODES = new Set(
  `AED AFN ALL AMD AOA ARS AUD AWG AZN BAM BBD BDT BHD BIF BMD BND
   BOB BOV BRL BSD BTN BWP BYN BZD CAD CDF CHE CHF CHW CLF CLP CNY COP COU
   CRC CUP CVE CZK DJF DKK DOP DZD EGP ERN ETB EUR FJD FKP GBP GEL GHS GIP
   GMD GNF GTQ GYD HKD HNL HTG HUF IDR ILS INR IQD IRR ISK JMD JOD JPY KES
   KGS KHR KMF KPW KRW KWD KYD KZT LAK LBP LKR LRD LSL LYD MAD MDL MGA MKD
   MMK MNT MOP MRU MUR MVR MWK MXN MXV MYR MZN NAD NGN NIO NOK NPR NZD OMR
   PAB PEN PGK PHP PKR PLN PYG QAR RON RSD RUB RWF SAR SBD SCR SDG SEK SGD
   SHP SLE SOS SRD SSP STN SVC SYP SZL THB TJS TMT TND TOP TRY TTD TWD TZS
   UAH UGX USD USN UYI UYU UYW UZS VED VES VND VUV WST XAD XAF XCD XCG XOF
   XPF YER ZAR ZMW ZWG`
    .trim()
    .split(/\s+/),
);

export type WalletDebit = {
  amountMinor: number;
  currencyCode: string;
  idempotencyKey: string;
  title: string;
};

export function requireIso4217Currency(value: unknown): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", "Currency code is required.");
  }
  const currencyCode = value.toUpperCase();
  if (!ISO_4217_CODES.has(currencyCode)) {
    throw new HttpsError("invalid-argument", "Unsupported ISO 4217 currency code.");
  }
  return currencyCode;
}

export function requirePositiveMinorUnits(value: unknown): number {
  if (
    typeof value !== "number" ||
    !Number.isSafeInteger(value) ||
    value <= 0
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Amount must be a positive integer in minor units.",
    );
  }
  return value;
}

export function applyMinorUnitDebit(
  current: unknown,
  debit: WalletDebit,
): Record<string, unknown> | undefined {
  const wallet =
    current !== null && typeof current === "object"
      ? (current as Record<string, unknown>)
      : {};
  const balanceMinor = wallet.balanceMinor ?? 0;
  if (
    typeof balanceMinor !== "number" ||
    !Number.isSafeInteger(balanceMinor) ||
    balanceMinor < 0
  ) {
    throw new HttpsError("failed-precondition", "Wallet balance is invalid.");
  }

  const transactions =
    wallet.transactions !== null &&
    typeof wallet.transactions === "object"
      ? {...(wallet.transactions as Record<string, unknown>)}
      : {};
  if (
    Object.prototype.hasOwnProperty.call(
      transactions,
      debit.idempotencyKey,
    ) ||
    balanceMinor < debit.amountMinor
  ) {
    return;
  }

  transactions[debit.idempotencyKey] = {
    amountMinor: debit.amountMinor,
    currencyCode: debit.currencyCode,
    title: debit.title,
    isCredit: false,
    createdAt: Date.now(),
  };
  return {
    ...wallet,
    currencyCode: debit.currencyCode,
    balanceMinor: balanceMinor - debit.amountMinor,
    transactions,
  };
}
