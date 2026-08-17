# ISOKO Mobile Authentication Links

Last updated: July 29, 2026.

This guide configures signup confirmation, email-change confirmation, and password-recovery links for the Flutter rider app. It does not change the VPS, scooter PostgreSQL database, admin dashboard, or physical-lock protocol.

## Current Mobile Identity

- Android application ID and namespace: `com.smstechnologieset.isoko`.
- iOS bundle ID: `com.smstechnologieset.isoko`.
- Current callback: `com.smstechnologieset.isoko://auth/callback`.
- Build-time override: `AUTH_REDIRECT_URL`.
- Planned HTTPS callback after domain association is ready: `https://app.smstechnologieset.com/auth/callback`.

The custom scheme is the active callback because it works before release signing and Apple Team details are available. Supabase uses PKCE, so open recovery links on the same device/app installation that requested them.

## Supabase Dashboard Setup

1. Open the Supabase project.
2. Go to **Authentication > URL Configuration**.
3. Keep **Site URL** as the approved public website URL; do not use a secret or localhost production value.
4. Add this exact **Redirect URL**:

   ```text
   com.smstechnologieset.isoko://auth/callback
   ```

5. Save the URL configuration.
6. Go to **Authentication > Email Templates**.
7. Confirm the **Confirm signup**, **Reset password**, and **Change email address** templates use Supabase's generated `{{ .ConfirmationURL }}`. Do not build a token URL manually in an email template.
8. Keep the Auth password minimum at 8 characters or increase both Supabase policy and Flutter validation together.
9. Configure production SMTP before a real launch so deliverability, sender identity, and rate limits do not depend on the Supabase trial sender.

No SQL migration or service-role key is needed for password recovery.

## Local Public Configuration

The root `.env` may include:

```env
AUTH_REDIRECT_URL=com.smstechnologieset.isoko://auth/callback
```

Generate the ignored Flutter configuration:

```powershell
cd C:\SMS\ScooterLock
npm.cmd run mobile:env
```

The generator copies only public mobile values and never copies `SUPABASE_SERVICE_ROLE_KEY`.

## Android Test

The application ID changed from the old Flutter placeholder. Remove the old debug app once if both installations are confusing:

```powershell
adb uninstall com.example.isoko_scooter
```

Run the current app:

```powershell
cd C:\SMS\ScooterLock\IsokoApp
flutter run --dart-define-from-file=env.local.json
```

Acceptance test:

1. Sign out and tap **Forgot password?**.
2. Enter a real confirmed rider email and send the reset link.
3. Open the email on the same Android device.
4. Confirm Android opens ISOKO and the app shows **Create new password** instead of account setup.
5. Enter matching passwords of at least 8 characters.
6. Confirm the success state, continue, and verify the authenticated account loads normally.
7. Sign out and prove the new password works and the old password does not.
8. Reopen the used link and confirm the app shows a safe invalid/expired-link screen.
9. Request another link and confirm rate-limit errors are friendly.
10. Kill the app after requesting a link, then open the email and verify cold-start recovery still reaches the reset screen.

The custom-scheme intent registration can be inspected with:

```powershell
adb shell dumpsys package com.smstechnologieset.isoko
```

## iOS Test

The iOS bundle ID and `CFBundleURLTypes` now use `com.smstechnologieset.isoko`. Build/sign the app with the client's Apple Developer team, install it on a physical device, and repeat the Android acceptance test. Simulator email/browser behavior is useful for development but does not replace a signed-device link test.

## HTTPS App Links and Universal Links

Do not switch `AUTH_REDIRECT_URL` to HTTPS until all of these exist:

1. `app.smstechnologieset.com` resolves over HTTPS without redirects or certificate errors.
2. Android release signing is finalized and its SHA-256 certificate fingerprint is known.
3. The domain serves `/.well-known/assetlinks.json` with package `com.smstechnologieset.isoko` and the release SHA-256 fingerprint.
4. The Android manifest has an HTTPS `android:autoVerify="true"` intent filter for host `app.smstechnologieset.com` and path `/auth/callback`.
5. The client's Apple Team ID is known.
6. The domain serves `/.well-known/apple-app-site-association` with `<APPLE_TEAM_ID>.com.smstechnologieset.isoko` and `/auth/callback` access.
7. The iOS Runner target has the Associated Domains entitlement `applinks:app.smstechnologieset.com` and a matching provisioning profile.
8. Supabase Redirect URLs includes `https://app.smstechnologieset.com/auth/callback`.
9. `AUTH_REDIRECT_URL` is changed to that HTTPS URL and new Android/iOS builds are released.

Keep the custom scheme allow-listed during a controlled migration until installed older builds are no longer supported.

## Security Behavior

- Forgot-password success text does not reveal whether an email is registered.
- Supabase Auth, not Flutter or VPS PostgreSQL, sends links and changes passwords.
- Recovery event state overrides ordinary signed-in routing so a recovery session cannot silently enter the app before password handling.
- A local pending marker survives app restart and is cleared by normal sign-in/sign-out or completed recovery.
- Invalid, expired, malformed, and wrong-device PKCE links show a generic safe error.
- No service-role key, password, token, or code verifier is logged or stored in project files.

## Troubleshooting

- Nothing happens when the link is pasted into Chrome while testing Flutter Web: this callback is native-only. Run/install the Android or iOS app, request recovery inside that native app, and tap the email link on the same device. A web build needs a separate allow-listed HTTP(S) callback and web route; it cannot use the Android/iOS custom scheme as its browser callback.
- Avoid manually sharing or repeatedly pasting a recovery URL. It contains a short-lived, one-use credential; request a fresh link after troubleshooting.
- Link opens a browser only: verify the exact callback is allow-listed in Supabase and the current app with ID `com.smstechnologieset.isoko` is installed.
- `Code verifier could not be found`: request and open the link on the same app installation/device.
- App opens sign-in instead of reset: verify the link is a Recovery template link and was not already used or expired.
- Email never arrives: check spam, Supabase Auth logs, SMTP configuration, and email rate limits.
- Old and new ISOKO icons both appear: uninstall the old `com.example.isoko_scooter` debug package.
