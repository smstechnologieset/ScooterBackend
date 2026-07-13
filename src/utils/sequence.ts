export class ProtocolSequenceGenerator {
  private counter = 0;

  public next(): string {
    this.counter = (this.counter + 1) & 0xffff;
    return this.counter.toString(16).toUpperCase().padStart(4, "0");
  }
}
