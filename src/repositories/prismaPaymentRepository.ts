import { Prisma, PrismaClient } from "@prisma/client";
import {
  PaymentRecord,
  PaymentStatus,
  WalletRecord,
  WalletTransactionRecord,
  WalletTransactionReason
} from "../models/payment";
import { CreatePaymentInput, PaymentRepository } from "./paymentRepository";
import { logger } from "../utils/logger";

export class PrismaPaymentRepository implements PaymentRepository {
  public constructor(private readonly prisma: PrismaClient) {}

  public async createPayment(input: CreatePaymentInput): Promise<PaymentRecord> {
    const payment = await this.prisma.payment.create({
      data: {
        riderId: input.riderId,
        rideId: input.rideId ?? null,
        amount: input.amount,
        currency: input.currency ?? "RWF",
        provider: input.provider,
        phoneNumber: input.phoneNumber ?? null,
        status: input.status ?? "pending",
        transactionRef: input.transactionRef ?? null,
        idempotencyKey: input.idempotencyKey ?? null,
        metadata: input.metadata ? (input.metadata as Prisma.InputJsonValue) : Prisma.JsonNull
      }
    });

    return mapPayment(payment);
  }

  public async findPaymentById(id: string): Promise<PaymentRecord | null> {
    const payment = await this.prisma.payment.findUnique({ where: { id } });
    return payment ? mapPayment(payment) : null;
  }

  public async findPaymentByTransactionRef(ref: string): Promise<PaymentRecord | null> {
    const payment = await this.prisma.payment.findUnique({ where: { transactionRef: ref } });
    return payment ? mapPayment(payment) : null;
  }

  public async updatePaymentStatus(
    id: string,
    status: PaymentStatus,
    extra?: {
      transactionRef?: string | null;
      failureReason?: string | null;
      metadata?: Record<string, unknown> | null;
    }
  ): Promise<PaymentRecord> {
    const payment = await this.prisma.payment.update({
      where: { id },
      data: {
        status,
        ...(extra?.transactionRef ? { transactionRef: extra.transactionRef } : {}),
        ...(extra?.failureReason !== undefined ? { failureReason: extra.failureReason } : {}),
        ...(extra?.metadata ? { metadata: extra.metadata as Prisma.InputJsonValue } : {})
      }
    });

    return mapPayment(payment);
  }

  public async listPaymentsByRider(riderId: string, limit = 20): Promise<PaymentRecord[]> {
    const payments = await this.prisma.payment.findMany({
      where: { riderId },
      orderBy: { createdAt: "desc" },
      take: limit
    });

    return payments.map(mapPayment);
  }

  public async getOrCreateWallet(riderId: string): Promise<WalletRecord> {
    const wallet = await this.prisma.wallet.upsert({
      where: { riderId },
      create: { riderId, balance: 0, currency: "RWF" },
      update: {}
    });

    return mapWallet(wallet);
  }

  public async getWallet(riderId: string): Promise<WalletRecord | null> {
    const wallet = await this.prisma.wallet.findUnique({ where: { riderId } });
    return wallet ? mapWallet(wallet) : null;
  }

  public async getWalletWithTransactions(
    riderId: string,
    limit = 20
  ): Promise<{ wallet: WalletRecord; transactions: WalletTransactionRecord[] }> {
    const wallet = await this.getOrCreateWallet(riderId);
    const transactions = await this.prisma.walletTransaction.findMany({
      where: { walletId: wallet.id },
      orderBy: { createdAt: "desc" },
      take: limit
    });

    return {
      wallet,
      transactions: transactions.map(mapTransaction)
    };
  }

  public async creditWallet(
    riderId: string,
    amount: number,
    reason: WalletTransactionReason,
    paymentId?: string | null,
    reference?: string | null
  ): Promise<{ wallet: WalletRecord; transaction: WalletTransactionRecord }> {
    return this.prisma.$transaction(async (tx) => {
      const wallet = await tx.wallet.upsert({
        where: { riderId },
        create: { riderId, balance: amount, currency: "RWF" },
        update: { balance: { increment: amount } }
      });

      const transaction = await tx.walletTransaction.create({
        data: {
          walletId: wallet.id,
          amount,
          type: "credit",
          reason,
          paymentId: paymentId ?? null,
          balanceAfter: wallet.balance,
          reference: reference ?? null
        }
      });

      logger.info(
        { riderId, amount, newBalance: wallet.balance, reason },
        "Wallet credited successfully"
      );

      return {
        wallet: mapWallet(wallet),
        transaction: mapTransaction(transaction)
      };
    });
  }

  public async debitWallet(
    riderId: string,
    amount: number,
    reason: WalletTransactionReason,
    paymentId?: string | null,
    reference?: string | null
  ): Promise<{ wallet: WalletRecord; transaction: WalletTransactionRecord }> {
    return this.prisma.$transaction(async (tx) => {
      const current = await tx.wallet.findUnique({ where: { riderId } });

      if (!current || current.balance < amount) {
        throw new Error(
          `Insufficient wallet balance. Available: ${current?.balance ?? 0} RWF, Required: ${amount} RWF`
        );
      }

      const wallet = await tx.wallet.update({
        where: { riderId },
        data: { balance: { decrement: amount } }
      });

      const transaction = await tx.walletTransaction.create({
        data: {
          walletId: wallet.id,
          amount: -amount,
          type: "debit",
          reason,
          paymentId: paymentId ?? null,
          balanceAfter: wallet.balance,
          reference: reference ?? null
        }
      });

      logger.info(
        { riderId, amount, newBalance: wallet.balance, reason },
        "Wallet debited successfully"
      );

      return {
        wallet: mapWallet(wallet),
        transaction: mapTransaction(transaction)
      };
    });
  }
}

function mapPayment(p: {
  id: string;
  riderId: string;
  rideId: string | null;
  amount: number;
  currency: string;
  provider: string;
  phoneNumber: string | null;
  status: string;
  transactionRef: string | null;
  idempotencyKey: string | null;
  failureReason: string | null;
  metadata: Prisma.JsonValue | null;
  createdAt: Date;
  updatedAt: Date;
}): PaymentRecord {
  return {
    id: p.id,
    riderId: p.riderId,
    rideId: p.rideId,
    amount: p.amount,
    currency: p.currency,
    provider: p.provider,
    phoneNumber: p.phoneNumber,
    status: p.status as PaymentStatus,
    transactionRef: p.transactionRef,
    idempotencyKey: p.idempotencyKey,
    failureReason: p.failureReason,
    metadata: p.metadata as Record<string, unknown> | null,
    createdAt: p.createdAt,
    updatedAt: p.updatedAt
  };
}

function mapWallet(w: {
  id: string;
  riderId: string;
  balance: number;
  currency: string;
  createdAt: Date;
  updatedAt: Date;
}): WalletRecord {
  return {
    id: w.id,
    riderId: w.riderId,
    balance: w.balance,
    currency: w.currency,
    createdAt: w.createdAt,
    updatedAt: w.updatedAt
  };
}

function mapTransaction(t: {
  id: string;
  walletId: string;
  amount: number;
  type: string;
  reason: string;
  paymentId: string | null;
  balanceAfter: number;
  reference: string | null;
  createdAt: Date;
}): WalletTransactionRecord {
  return {
    id: t.id,
    walletId: t.walletId,
    amount: t.amount,
    type: t.type as "credit" | "debit",
    reason: t.reason as WalletTransactionReason,
    paymentId: t.paymentId,
    balanceAfter: t.balanceAfter,
    reference: t.reference,
    createdAt: t.createdAt
  };
}
