# Protocol Source Notes

Authoritative inputs used by this backend:

- `Answers.md`: manufacturer answers for the exact hardware and firmware batch.
- `SmartLock-IOT_V1_3_.md`: English protocol document.
- `智响智能锁通讯协议英文版.md`: manufacturer protocol document.

The original scaffold treated several protocol details as unknown. The manufacturer has now confirmed the production profile documented in `docs/protocol-clarifications.md`, including raw TCP transport, Mode 1 registration, 4-hex SEQ values, content-plus-terminator LENGTH calculation, `LOCA` positioning, `CCID` echo ACKs, non-empty `RECORD` ACKs, no ACK for empty `RECORD:1`, 25-second OPEN timeout, and required `UPDATE` plus server `RECORD:` support.

The code still accepts documented packets whose example LENGTH values disagree with the confirmed rule. Those mismatches are recorded as warnings because the docs and sample packets are inconsistent, while outbound packets are generated with the confirmed LENGTH calculation.
