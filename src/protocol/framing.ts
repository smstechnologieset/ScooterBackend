export class TcpFrameBuffer {
  private buffer = Buffer.alloc(0);

  public constructor(
    private readonly terminator: string,
    private readonly maxFrameBytes: number
  ) {}

  public push(chunk: Buffer): Buffer[] {
    this.buffer = Buffer.concat([this.buffer, chunk]);

    if (this.buffer.length > this.maxFrameBytes) {
      const oversized = this.buffer;
      this.buffer = Buffer.alloc(0);
      throw new Error(`TCP frame exceeded ${this.maxFrameBytes} bytes: ${oversized.length}`);
    }

    if (!this.terminator) {
      const singleFrame = this.buffer;
      this.buffer = Buffer.alloc(0);
      return [singleFrame];
    }

    const frames: Buffer[] = [];
    const terminatorBuffer = Buffer.from(this.terminator, "ascii");

    while (true) {
      const index = this.buffer.indexOf(terminatorBuffer);

      if (index < 0) {
        break;
      }

      const end = index + terminatorBuffer.length;
      frames.push(this.buffer.subarray(0, end));
      this.buffer = this.buffer.subarray(end);
    }

    return frames;
  }

  public clear(): void {
    this.buffer = Buffer.alloc(0);
  }
}
