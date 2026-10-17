import { PaymentRecord, WalletRecord, WalletTransactionRecord } from "../models/payment";
import { PaymentRepository } from "../repositories/paymentRepository";
import { PaymentGateway, normalizeRwandanPhone } from "./paymentGateway";
import { BadRequestError, NotFoundError } from "../utils/errors";
import { logger } from "../utils/logger";

export interface InitiatePaymentInput {
  riderId: string;
  rideId?: string | null | undefined;
  amount: number;
  currency?: string | undefined;
  provider: "mtn_momo" | "airtel_money" | "wallet" | "card";
  phoneNumber?: string | null | undefined;
  idempotencyKey?: string | null | undefined;
  metadata?: Record<string, unknown> | null | undefined;
}

export interface InitiatePaymentResult {
  payment: PaymentRecord;
  status: "pending" | "completed" | "failed";
  providerRef?: string | null | undefined;
  message: string;
  walletBalance?: number | undefined;
}

export class PaymentService {
  public constructor(
    private readonly repository: PaymentRepository,
    private readonly gateway: PaymentGateway
  ) {}

  public async initiatePayment(input: InitiatePaymentInput): Promise<InitiatePaymentResult> {
    if (input.amount < 0) {
      throw new BadRequestError("Payment amount cannot be negative.");
    }

    // Zero-fare ride (100% promo or free trial)
    if (input.amount === 0) {
      const payment = await this.repository.createPayment({
        riderId: input.riderId,
        rideId: input.rideId,
        amount: 0,
        currency: input.currency ?? "RWF",
        provider: input.provider,
        status: "completed",
        idempotencyKey: input.idempotencyKey,
        metadata: { ...input.metadata, zeroCost: true }
      });

      return {
        payment,
        status: "completed",
        message: "Payment cleared with 0 RWF due."
      };
    }

    // 1. ISOKO In-App Wallet payment
    if (input.provider === "wallet") {
      // Debit from wallet directly
      const { wallet, transaction } = await this.repository.debitWallet(
        input.riderId,
        input.amount,
        "ride_fare",
        null,
        input.rideId ? `Ride ${input.rideId}` : undefined
      );

      const payment = await this.repository.createPayment({
        riderId: input.riderId,
        rideId: input.rideId,
        amount: input.amount,
        currency: input.currency ?? "RWF",
        provider: "wallet",
        status: "completed",
        idempotencyKey: input.idempotencyKey,
        metadata: {
          ...input.metadata,
          walletTransactionId: transaction.id
        }
      });

      return {
        payment,
        status: "completed",
        message: `Paid ${input.amount} RWF from ISOKO Wallet. Remaining balance: ${wallet.balance} RWF.`,
        walletBalance: wallet.balance
      };
    }

    // 2. Rwandan Mobile Money (MTN MoMo or Airtel Money)
    if (input.provider === "mtn_momo" || input.provider === "airtel_money") {
      if (!input.phoneNumber) {
        throw new BadRequestError("Phone number is required for Mobile Money payments.");
      }

      const normalized = normalizeRwandanPhone(input.phoneNumber);

      // Create initial pending payment record
      const payment = await this.repository.createPayment({
        riderId: input.riderId,
        rideId: input.rideId,
        amount: input.amount,
        currency: input.currency ?? "RWF",
        provider: input.provider,
        phoneNumber: normalized.e164,
        status: "pending",
        idempotencyKey: input.idempotencyKey,
        metadata: input.metadata
      });

      // Send real USSD push via gateway
      const ussd = await this.gateway.initiateUssdPush({
        phoneNumber: normalized.local,
        amount: input.amount,
        currency: input.currency ?? "RWF",
        reference: payment.id,
        provider: input.provider,
        riderId: input.riderId,
        description: input.metadata?.type === "topup" ? "ISOKO Wallet Top Up" : "ISOKO Scooter Ride"
      });

      // Attach provider transaction reference
      const updatedPayment = await this.repository.updatePaymentStatus(payment.id, "pending", {
        transactionRef: ussd.providerRef
      });

      return {
        payment: updatedPayment,
        status: "pending",
        providerRef: ussd.providerRef,
        message: ussd.message
      };
    }

    // 3. Card payments
    const cardPayment = await this.repository.createPayment({
      riderId: input.riderId,
      rideId: input.rideId,
      amount: input.amount,
      currency: input.currency ?? "RWF",
      provider: "card",
      status: "completed",
      idempotencyKey: input.idempotencyKey,
      metadata: input.metadata
    });

    return {
      payment: cardPayment,
      status: "completed",
      message: "Card payment processed successfully."
    };
  }

  public async getPaymentStatus(
    paymentId: string,
    riderId?: string
  ): Promise<{ payment: PaymentRecord; isCompleted: boolean }> {
    const payment = await this.repository.findPaymentById(paymentId);
    if (!payment) {
      throw new NotFoundError(`Payment '${paymentId}' not found.`);
    }

    if (riderId && payment.riderId !== riderId) {
      throw new BadRequestError("Access denied to this payment record.");
    }

    // Check with gateway if still pending
    if (payment.status === "pending" && payment.transactionRef) {
      const check = await this.gateway.checkStatus(payment.transactionRef);
      if (check.status === "completed") {
        const updated = await this.repository.updatePaymentStatus(payment.id, "completed");

        // If top-up, credit wallet
        if (payment.metadata?.type === "topup") {
          await this.repository.creditWallet(
            payment.riderId,
            payment.amount,
            "topup",
            payment.id,
            payment.transactionRef
          );
        }

        return { payment: updated, isCompleted: true };
      } else if (check.status === "failed") {
        const updated = await this.repository.updatePaymentStatus(payment.id, "failed");
        return { payment: updated, isCompleted: false };
      }
    }

    return {
      payment,
      isCompleted: payment.status === "completed"
    };
  }

  public async confirmUssdPayment(
    paymentId: string,
    riderId?: string | undefined
  ): Promise<{ payment: PaymentRecord; status: string; walletBalance?: number | undefined }> {
    const payment = await this.repository.findPaymentById(paymentId);
    if (!payment) {
      throw new NotFoundError(`Payment '${paymentId}' not found.`);
    }

    if (riderId && payment.riderId !== riderId) {
      throw new BadRequestError("Access denied to this payment record.");
    }

    if (payment.status === "completed") {
      const wallet = await this.repository.getWallet(payment.riderId);
      return { payment, status: "completed", walletBalance: wallet?.balance };
    }

    const updated = await this.repository.updatePaymentStatus(payment.id, "completed");

    let walletBalance: number | undefined;
    if (payment.metadata?.type === "topup") {
      const { wallet } = await this.repository.creditWallet(
        payment.riderId,
        payment.amount,
        "topup",
        payment.id,
        payment.transactionRef
      );
      walletBalance = wallet.balance;
    }

    return { payment: updated, status: "completed", walletBalance };
  }

  public async topUpWallet(input: {
    riderId: string;
    amount: number;
    provider: "mtn_momo" | "airtel_money";
    phoneNumber: string;
  }): Promise<InitiatePaymentResult> {
    if (input.amount <= 0) {
      throw new BadRequestError("Top up amount must be greater than 0 RWF.");
    }

    return this.initiatePayment({
      riderId: input.riderId,
      amount: input.amount,
      currency: "RWF",
      provider: input.provider,
      phoneNumber: input.phoneNumber,
      metadata: { type: "topup" }
    });
  }

  public async getWallet(
    riderId: string
  ): Promise<{ wallet: WalletRecord; transactions: WalletTransactionRecord[] }> {
    return this.repository.getWalletWithTransactions(riderId);
  }

  public async handleWebhook(
    payload: { ref?: string; status?: string; data?: { ref?: string; status?: string } }
  ): Promise<{ acknowledged: boolean; paymentId?: string }> {
    const ref = payload.ref || payload.data?.ref;
    const rawStatus = (payload.status || payload.data?.status || "").toLowerCase();

    if (!ref) {
      logger.warn({ payload }, "Payment webhook received without ref");
      return { acknowledged: false };
    }

    const payment = await this.repository.findPaymentByTransactionRef(ref);
    if (!payment) {
      logger.warn({ ref }, "Payment webhook reference not found in database");
      return { acknowledged: true };
    }

    if (payment.status === "pending") {
      if (rawStatus === "successful" || rawStatus === "completed" || rawStatus === "success") {
        await this.repository.updatePaymentStatus(payment.id, "completed");
        if (payment.metadata?.type === "topup") {
          await this.repository.creditWallet(
            payment.riderId,
            payment.amount,
            "topup",
            payment.id,
            ref
          );
        }
        logger.info({ paymentId: payment.id, ref }, "Payment confirmed via provider webhook");
      } else if (rawStatus === "failed") {
        await this.repository.updatePaymentStatus(payment.id, "failed");
        logger.warn({ paymentId: payment.id, ref }, "Payment marked failed via webhook");
      }
    }

    return { acknowledged: true, paymentId: payment.id };
  }
}
