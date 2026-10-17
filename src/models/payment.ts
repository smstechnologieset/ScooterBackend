export type PaymentProvider = "mtn_momo" | "airtel_money" | "wallet" | "card";

export type PaymentStatus = "pending" | "completed" | "failed" | "cancelled";

export type WalletTransactionType = "credit" | "debit";

export type WalletTransactionReason = "topup" | "ride_fare" | "refund" | "promo";

export interface PaymentRecord {
  id: string;
  riderId: string;
  rideId: string | null;
  amount: number;
  currency: string;
  provider: string;
  phoneNumber: string | null;
  status: PaymentStatus;
  transactionRef: string | null;
  idempotencyKey: string | null;
  failureReason: string | null;
  metadata: Record<string, unknown> | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface WalletRecord {
  id: string;
  riderId: string;
  balance: number;
  currency: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface WalletTransactionRecord {
  id: string;
  walletId: string;
  amount: number;
  type: WalletTransactionType;
  reason: WalletTransactionReason;
  paymentId: string | null;
  balanceAfter: number;
  reference: string | null;
  createdAt: Date;
}
