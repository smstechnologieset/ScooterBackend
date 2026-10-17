import { FastifyInstance } from "fastify";
import { z } from "zod";
import { PaymentService } from "../../services/paymentService";

const initiatePaymentSchema = z.object({
  riderId: z.string().optional(),
  rideId: z.string().optional().nullable(),
  amount: z.coerce.number().int().min(0),
  currency: z.string().default("RWF"),
  provider: z.enum(["mtn_momo", "airtel_money", "wallet", "card"]),
  phoneNumber: z.string().optional().nullable(),
  idempotencyKey: z.string().optional().nullable(),
  metadata: z.record(z.unknown()).optional().nullable()
});

const paymentIdParamsSchema = z.object({
  id: z.string().uuid()
});

const topUpSchema = z.object({
  riderId: z.string().optional(),
  amount: z.coerce.number().int().positive(),
  provider: z.enum(["mtn_momo", "airtel_money"]),
  phoneNumber: z.string().min(5)
});

const walletQuerySchema = z.object({
  riderId: z.string().optional()
});

export async function registerPaymentRoutes(
  app: FastifyInstance,
  services: {
    payments: PaymentService;
  }
): Promise<void> {
  // 1. Initiate Ride Payment or Top-up
  app.post(
    "/rider/payments/initiate",
    { preHandler: app.optionalAuthenticateRider },
    async (request, reply) => {
      const body = initiatePaymentSchema.parse(request.body);
      const riderId = request.rider?.id ?? body.riderId ?? "guest-rider-001";

      const result = await services.payments.initiatePayment({
        riderId,
        rideId: body.rideId ?? null,
        amount: body.amount,
        currency: body.currency,
        provider: body.provider,
        phoneNumber: body.phoneNumber ?? request.rider?.phone ?? null,
        idempotencyKey: body.idempotencyKey ?? null,
        metadata: (body.metadata as Record<string, unknown> | null | undefined) ?? null
      });

      await reply.send({
        ok: true,
        payment: result.payment,
        status: result.status,
        providerRef: result.providerRef,
        message: result.message,
        walletBalance: result.walletBalance
      });
    }
  );

  // 2. Poll / Check Payment Status
  app.get(
    "/rider/payments/:id/status",
    { preHandler: app.optionalAuthenticateRider },
    async (request, reply) => {
      const params = paymentIdParamsSchema.parse(request.params);
      const result = await services.payments.getPaymentStatus(
        params.id,
        request.rider?.id
      );

      await reply.send({
        ok: true,
        payment: result.payment,
        isCompleted: result.isCompleted
      });
    }
  );

  // 3. Confirm USSD Payment (Interactive / Direct User Approval)
  app.post(
    "/rider/payments/:id/confirm-ussd",
    { preHandler: app.optionalAuthenticateRider },
    async (request, reply) => {
      const params = paymentIdParamsSchema.parse(request.params);
      const result = await services.payments.confirmUssdPayment(
        params.id,
        request.rider?.id
      );

      await reply.send({
        ok: true,
        payment: result.payment,
        status: result.status,
        walletBalance: result.walletBalance
      });
    }
  );

  // 4. In-App Wallet Details and History
  app.get(
    "/rider/wallet",
    { preHandler: app.optionalAuthenticateRider },
    async (request, reply) => {
      const query = walletQuerySchema.parse(request.query);
      const riderId = request.rider?.id ?? query.riderId ?? "guest-rider-001";

      const result = await services.payments.getWallet(riderId);

      await reply.send({
        ok: true,
        wallet: result.wallet,
        transactions: result.transactions
      });
    }
  );

  // 5. Wallet Top Up via Mobile Money
  app.post(
    "/rider/wallet/topup",
    { preHandler: app.optionalAuthenticateRider },
    async (request, reply) => {
      const body = topUpSchema.parse(request.body);
      const riderId = request.rider?.id ?? body.riderId ?? "guest-rider-001";

      const result = await services.payments.topUpWallet({
        riderId,
        amount: body.amount,
        provider: body.provider,
        phoneNumber: body.phoneNumber
      });

      await reply.send({
        ok: true,
        payment: result.payment,
        status: result.status,
        providerRef: result.providerRef,
        message: result.message
      });
    }
  );

  // 6. Provider Webhook Callback (Paypack / MTN MoMo)
  app.post("/rider/payments/webhook", async (request, reply) => {
    const payload = (request.body ?? {}) as Record<string, unknown>;
    const result = await services.payments.handleWebhook(payload);
    await reply.send({ ok: true, ...result });
  });
}
