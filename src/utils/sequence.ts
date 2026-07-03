export class ProtocolSequenceGenerator {
  private counter = 0;

  public next(): string {
    this.counter = (this.counter + 1) % 1000000;
    const timePart = Date.now().toString(36).toUpperCase();
    const counterPart = this.counter.toString(36).toUpperCase().padStart(4, "0");
    return `${timePart}${counterPart}`;
  }
}
