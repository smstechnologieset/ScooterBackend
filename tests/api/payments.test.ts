import { describe, expect, it, vi } from "vitest";
import { normalizeRwandanPhone } from "../../src/services/paymentGateway";
import { PaymentService } from "../../src/services/paymentService";
import { PaymentRepository } from "../../src/repositories/paymentRepository";
import { PaymentGateway } from "../../src/services/paymentGateway";
import { PaymentRecord, WalletRecord, WalletTransactionRecord } from "../../src/models/payment";

describe("Payment and Rwandan Mobile Money", () => {
  describe("Rwandan Phone Normalization", () => {
    it("normalizes MTN phone starting with 078", () => {
      const res = normalizeRwandanPhone("078 812 3456");
      expect(res.local).toBe("0788123456");
      expect(res.e164).toBe("+250788123456");
      expect(res.detectedProvider).toBe("mtn_momo");
    });

    it("normalizes MTN phone starting with 079", () => {
      const res = normalizeRwandanPhone("+250 79 123 4567");
      expect(res.local).toBe("0791234567");
      expect(res.e164).toBe("+250791234567");
      expect(res.detectedProvider).toBe("mtn_momo");
    });

    it("normalizes Airtel phone starting with 072 / 073", () => {
      const res = normalizeRwandanPhone("0722345678");
      expect(res.local).toBe("0722345678");
      expect(res.e164).toBe("+250722345678");
      expect(res.detectedProvider).toBe("airtel_money");
    });

    it("throws on invalid phone numbers", () => {
      expect(() => normalizeRwandanPhone("123")).toThrow();
    });
  });

  describe("PaymentService Logic", () => {
    function makeMockRepo(): PaymentRepository {
      let balance = 3000;
      const payments: PaymentRecord[] = [];

      return {
        createPayment: vi.fn().mockImplementation(async (input) => {
          const rec: PaymentRecord = {
            id: "pay-uuid-1",
            riderId: input.riderId,
            rideId: input.rideId ?? null,
            amount: input.amount,
            currency: input.currency ?? "RWF",
            provider: input.provider,
            phoneNumber: input.phoneNumber ?? null,
            status: input.status ?? "pending",
            transactionRef: input.transactionRef ?? null,
            idempotencyKey: input.idempotencyKey ?? null,
            failureReason: null,
            metadata: input.metadata ?? null,
            createdAt: new Date(),
            updatedAt: new Date()
          };
          payments.push(rec);
          return rec;
        }),
        findPaymentById: vi.fn().mockImplementation(async (id) => {
          return payments.find((p) => p.id === id) ?? null;
        }),
        findPaymentByTransactionRef: vi.fn().mockImplementation(async (ref) => {
          return payments.find((p) => p.transactionRef === ref) ?? null;
        }),
        updatePaymentStatus: vi.fn().mockImplementation(async (id, status, extra) => {
          const p = payments.find((item) => item.id === id);
          if (p) {
            p.status = status;
            if (extra?.transactionRef) p.transactionRef = extra.transactionRef;
          }
          return p!;
        }),
        listPaymentsByRider: vi.fn().mockResolvedValue([]),
        getOrCreateWallet: vi.fn().mockResolvedValue({
          id: "w-1",
          riderId: "rider-1",
          balance,
          currency: "RWF",
          createdAt: new Date(),
          updatedAt: new Date()
        }),
        getWallet: vi.fn().mockResolvedValue({
          id: "w-1",
          riderId: "rider-1",
          balance,
          currency: "RWF",
          createdAt: new Date(),
          updatedAt: new Date()
        }),
        getWalletWithTransactions: vi.fn().mockResolvedValue({
          wallet: { id: "w-1", riderId: "rider-1", balance, currency: "RWF", createdAt: new Date(), updatedAt: new Date() },
          transactions: []
        }),
        creditWallet: vi.fn().mockImplementation(async (riderId, amount, reason, paymentId, ref) => {
          balance += amount;
          return {
            wallet: { id: "w-1", riderId, balance, currency: "RWF", createdAt: new Date(), updatedAt: new Date() },
            transaction: {
              id: "tx-1",
              walletId: "w-1",
              amount,
              type: "credit",
              reason,
              paymentId: paymentId ?? null,
              balanceAfter: balance,
              reference: ref ?? null,
              createdAt: new Date()
            }
          };
        }),
        debitWallet: vi.fn().mockImplementation(async (riderId, amount, reason, paymentId, ref) => {
          if (balance < amount) {
            throw new Error(`Insufficient wallet balance.`);
          }
          balance -= amount;
          return {
            wallet: { id: "w-1", riderId, balance, currency: "RWF", createdAt: new Date(), updatedAt: new Date() },
            transaction: {
              id: "tx-2",
              walletId: "w-1",
              amount: -amount,
              type: "debit",
              reason,
              paymentId: paymentId ?? null,
              balanceAfter: balance,
              reference: ref ?? null,
              createdAt: new Date()
            }
          };
        })
      };
    }

    const mockGateway: PaymentGateway = {
      initiateUssdPush: vi.fn().mockResolvedValue({
        success: true,
        providerRef: "RW-MOMO-TEST-1234",
        status: "pending",
        message: "Prompt sent."
      }),
      checkStatus: vi.fn().mockResolvedValue({
        status: "completed",
        providerRef: "RW-MOMO-TEST-1234"
      })
    };

    it("initiates MTN MoMo payment and attaches provider reference", async () => {
      const repo = makeMockRepo();
      const service = new PaymentService(repo, mockGateway);

      const result = await service.initiatePayment({
        riderId: "rider-1",
        amount: 1010,
        provider: "mtn_momo",
        phoneNumber: "0788123456"
      });

      expect(result.status).toBe("pending");
      expect(result.providerRef).toBe("RW-MOMO-TEST-1234");
      expect(repo.createPayment).toHaveBeenCalled();
    });

    it("processes instant wallet payment when balance is sufficient", async () => {
      const repo = makeMockRepo();
      const service = new PaymentService(repo, mockGateway);

      const result = await service.initiatePayment({
        riderId: "rider-1",
        amount: 1010,
        provider: "wallet"
      });

      expect(result.status).toBe("completed");
      expect(result.walletBalance).toBe(1990); // 3000 - 1010
      expect(repo.debitWallet).toHaveBeenCalled();
    });

    it("top up wallet initiates payment and confirmation credits wallet", async () => {
      const repo = makeMockRepo();
      const service = new PaymentService(repo, mockGateway);

      const initResult = await service.topUpWallet({
        riderId: "rider-1",
        amount: 2000,
        provider: "mtn_momo",
        phoneNumber: "0788123456"
      });

      expect(initResult.status).toBe("pending");

      // Confirm USSD push approval
      const confirmResult = await service.confirmUssdPayment(initResult.payment.id, "rider-1");
      expect(confirmResult.status).toBe("completed");
      expect(confirmResult.walletBalance).toBe(5000); // 3000 + 2000
    });
  });
});
