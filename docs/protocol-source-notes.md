# Protocol Source Notes

Authoritative inputs provided for this scaffold:

- `SmartLock-IOT(V1.3).pdf`
- `智响智能锁通讯协议英文版.pdf`
- Project instruction attachment in `.codex/attachments/.../pasted-text.txt`

The IoT PDF table of contents is extractable and lists these TCP-related sections:

- Protocol format
- Positioning package
- Heartbeat packet for 4G-LTE long connections
- Search/inquire vehicle
- Unlock for 4G-LTE long connections
- Close and lock
- Transaction record
- Heartbeat upload interval setting
- Lock positioning upload interval setting
- Cycling positioning upload interval setting
- Remote firmware update protocol
- SIM CCID reporting
- Version reporting
- Voice command modification
- Bluetooth connection authentication
- Error codes

The body text uses custom PDF font encodings, so the local extraction pass could not recover field tables reliably without a dedicated parser/OCR workflow. The implementation therefore encodes only the protocol details included in the project instructions:

- ASCII text packet family.
- Base example shape: `G168#DEVICEID#SEQ#LENGTH#COMMAND$`.
- Server ACK prefix examples: `ACK^REGISTER`, `ACK^SYNC`, `ACK^OPEN`, `ACK^LOCK`.
- Command tokens listed in the instructions: `REGISTER`, `SYNC`, `OPEN`, `LOCK`, `UPDATE`, `VOICE`, `CCID`, `AUTHOR`.

All omitted or ambiguous behavior remains configurable in `.env.example` and is listed in `docs/protocol-clarifications.md`.
