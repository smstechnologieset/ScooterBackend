import {
  PaymentRecord,
  PaymentStatus,
  WalletRecord,
  WalletTransactionRecord,
  WalletTransactionReason
} from "../models/payment";

export interface CreatePaymentInput {
  riderId: string;
  rideId?: string | null | undefined;
  amount: number;
  currency?: string | undefined;
  provider: string;
  phoneNumber?: string | null | undefined;
  status?: PaymentStatus | undefined;
  transactionRef?: string | null | undefined;
  idempotencyKey?: string | null | undefined;
  metadata?: Record<string, unknown> | null | undefined;
}

export interface PaymentRepository {
  createPayment(input: CreatePaymentInput): Promise<PaymentRecord>;
  findPaymentById(id: string): Promise<PaymentRecord | null>;
  findPaymentByTransactionRef(ref: string): Promise<PaymentRecord | null>;
  updatePaymentStatus(
    id: string,
    status: PaymentStatus,
    extra?: {
      transactionRef?: string | null | undefined;
      failureReason?: string | null | undefined;
      metadata?: Record<string, unknown> | null | undefined;
    } | undefined
  ): Promise<PaymentRecord>;
  listPaymentsByRider(riderId: string, limit?: number | undefined): Promise<PaymentRecord[]>;

  getOrCreateWallet(riderId: string): Promise<WalletRecord>;
  getWallet(riderId: string): Promise<WalletRecord | null>;
  getWalletWithTransactions(
    riderId: string,
    limit?: number | undefined
  ): Promise<{ wallet: WalletRecord; transactions: WalletTransactionRecord[] }>;
  creditWallet(
    riderId: string,
    amount: number,
    reason: WalletTransactionReason,
    paymentId?: string | null | undefined,
    reference?: string | null | undefined
  ): Promise<{ wallet: WalletRecord; transaction: WalletTransactionRecord }>;
  debitWallet(
    riderId: string,
    amount: number,
    reason: WalletTransactionReason,
    paymentId?: string | null | undefined,
    reference?: string | null | undefined
  ): Promise<{ wallet: WalletRecord; transaction: WalletTransactionRecord }>;
}

