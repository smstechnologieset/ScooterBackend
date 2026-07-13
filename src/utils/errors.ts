export class NotFoundError extends Error {
  public override readonly name = "NotFoundError";
}

export class OfflineScooterError extends Error {
  public override readonly name = "OfflineScooterError";
}

export class CommandDispatchError extends Error {
  public override readonly name = "CommandDispatchError";
}

export class UnauthorizedError extends Error {
  public override readonly name = "UnauthorizedError";
}

export class ForbiddenError extends Error {
  public override readonly name = "ForbiddenError";
}
