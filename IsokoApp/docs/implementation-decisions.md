# ISOKO App Implementation Decisions

These decisions are now represented in code:

- Development API base URL: `http://62.171.160.225:3000`.
- Launch country: Rwanda.
- Supported currencies: `RWF` and `USD`.
- Primary user-facing scooter code format: `BK2113`.
- QR codes identify scooters by public code. The parser accepts `BK2113`, `ISOKO:BK2113`, and future deep links such as `isoko://scooter/BK2113`.
- Auth methods to support: phone OTP, email/password, Google, and Apple.
- Payment providers to support: MTN Mobile Money, Airtel Money, Stripe/card, and ISOKO wallet.
- Map provider direction: Mapbox. A `MAPBOX_ACCESS_TOKEN` dart define is reserved for the native Mapbox integration.
- Pause/resume is enabled from launch.
- Ending rides outside parking zones must be blocked.
- Android and iOS are both target platforms.

Next implementation phase:

1. Replace prototype auth screens with auth feature screens backed by real auth repositories.
2. Add backend auth endpoints or align with the chosen auth provider.
3. Add Mapbox native dependency and platform tokens.
4. Add QR/camera scanner package and route scanned payloads through `ScooterQrPayload`.
5. Connect unlock/manual-code/start-ride/end-ride screens to `ScooterApi`.
6. Add payment provider adapters once merchant accounts/API credentials are available.
