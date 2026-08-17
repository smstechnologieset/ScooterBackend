# Mobile Map and Location

## Purpose

The rider app now has a native phone-location flow and a Mapbox map foundation. This slice answers two separate questions:

- **Where is the rider's phone?** Geolocator reads the Android/iPhone location after foreground permission is granted.
- **Where is a scooter lock?** The backend must supply a recent, valid lock GPS fix through the future rider-safe discovery API.

These locations must never be substituted for each other. A phone location does not prove that a scooter is at the same point, and a stale lock location must not be presented as live.

## Current Behavior

- `/enable-location` checks whether device Location Services are enabled and whether foreground permission is granted.
- Denied permission can be requested again. Permanent denial opens app settings; disabled services open device location settings.
- A successful fix routes to `/find-scooter`.
- `/find-scooter` and `/scooter-list` render the native Mapbox map on Android/iOS, center on the phone, show the Mapbox location puck and accuracy ring, and provide a recenter control.
- The map preserves the last phone fix while a refresh is in progress or a temporary refresh fails.
- Missing token, load failure, and unsupported platform states are explicit.
- Stable `mapbox_maps_flutter` 2.27.0 is Android/iOS only. Web and desktop deliberately show an unavailable message rather than a fake map.
- No fake scooter markers are shown. Scooter markers remain blocked on the rider-safe discovery endpoint and lock GPS validity/staleness rules.

## Runtime Configuration

Create a public Mapbox access token in the Mapbox account. Give it only the public scopes required to load maps/styles. Do not put a Mapbox secret token or a token with account-management/write privileges in Flutter.

Set the public token only in the ignored root `.env`:

```dotenv
MAPBOX_ACCESS_TOKEN=pk.replace-with-public-mapbox-token
```

Generate the ignored Flutter configuration and run the app:

```powershell
cd C:\SMS\ScooterLock
npm.cmd run mobile:env
cd IsokoApp
flutter run --dart-define-from-file=env.local.json
```

`scripts/create-flutter-env.mjs` copies `MAPBOX_ACCESS_TOKEN` into `IsokoApp/env.local.json` only when configured. The generated file remains ignored. `AppConfig` reads it with `String.fromEnvironment`, and `main.dart` calls `MapboxOptions.setAccessToken` before constructing a map on Android/iOS only.

## Native Requirements

Android:

- Minimum SDK 21 or later.
- `android.permission.INTERNET`.
- `android.permission.ACCESS_COARSE_LOCATION`.
- `android.permission.ACCESS_FINE_LOCATION`.

iOS:

- Deployment target iOS 14 or later.
- `NSLocationWhenInUseUsageDescription` explaining the rider-facing purpose.
- A Mac with Xcode/CocoaPods and valid Apple signing remains required to build and accept the iOS app. The current repository has no `ios/Podfile`; verify/regenerate the iOS Flutter platform files on the approved Mac before the first iOS build.

Background location is not requested. The current product only needs location while the rider is using the app. Adding background tracking later requires a separate product, privacy, store-policy, and battery-impact decision.

## Location State Model

`LocationService` isolates Geolocator from application state so permission and failure behavior can be unit tested. `LocationController` exposes:

- `idle`
- `checking`
- `requesting`
- `ready`
- `serviceDisabled`
- `permissionDenied`
- `permissionDeniedForever`
- `unavailable`

The stored `DeviceLocation` includes latitude, longitude, accuracy, capture time, and Geolocator's mocked-location flag. Mocked-location data is retained for future fraud/risk policy; this slice does not block a rider merely because the platform reports a mocked location.

## Scooter GPS Rules

The factory confirmed on July 30, 2026 that cellular base-station positioning is discontinued because its error exceeds 500 metres, it incurs Quectel service fees, and foreign base stations may not support it.

Therefore:

- Do not implement or fabricate an indoor base-station fallback.
- A valid recent lock GPS fix may be shown as the scooter location.
- An invalid, missing, or old fix must be labelled unavailable or stale.
- The phone can still show the rider's position when lock GPS is unavailable.
- The server remains responsible for validating coordinates, timestamp/age, impossible movement, and drift before publishing rider-safe scooter locations.

## Acceptance Checklist

1. Configure a valid public Mapbox token and regenerate `env.local.json`.
2. Test first-run grant on a physical Android device.
3. Test deny, deny-again/permanent denial, app settings return, and disabled Location Services.
4. Confirm the map centers near the real phone position and recenter works without replacing the map screen.
5. Confirm Mapbox attribution/logo remain visible above the bottom panel.
6. Test no-network and temporary GPS failure states.
7. Repeat on a signed physical iPhone after the iOS build path is available.
8. After discovery is implemented, test fresh, stale, invalid, and missing lock GPS independently of phone location.

## Emulator Location and Physical-Device Crashes

Android Emulator location is simulated. A newly created Google emulator commonly starts near Google's campus around Amphitheatre Parkway, Mountain View, California. Mapbox and Geolocator correctly display the coordinate supplied by the emulator; they do not infer the developer's physical location from the Windows PC.

To test Ethiopia, open the emulator's three-dot **Extended controls**, choose **Location**, enter an Ethiopian latitude/longitude (for example Addis Ababa near latitude `9.03`, longitude `38.74`), send/set the location, and then press the app's recenter button.

On July 31, 2026 the owner reported that the debug APK renders the map in the Android emulator but crashes on a physical phone. ADB listed only `emulator-5554`, so no physical-phone stack trace was available. The screenshot proved that a working Mapbox token reached the emulator run, while Codex's earlier APK build command did not list `MAPBOX_ACCESS_TOKEN` among its generated Dart defines. The current `env.local.json` was then confirmed to contain a nonempty public `pk.*` token, `npm.cmd run mobile:env` regenerated it, and a fresh APK was built with the token present in the Dart defines.

Known comparison APK:

- Path: `IsokoApp/build/app/outputs/flutter-apk/app-debug.apk`.
- Size: `244142875` bytes.
- SHA-256: `EA6387BCB6FB91EB7934029401DC70DFA68EABF1B2DF62A61C0BE9E752DFACF6`.
- Installed successfully on `emulator-5554`.
- Launched and remained alive as PID `29067` after eight seconds.
- Filtered AndroidRuntime/native fatal log was empty.

Clean-install this exact artifact on the physical phone before comparing behavior. If it still crashes, the remaining fault is physical-device/stale-state specific rather than an emulator compilation failure. Do not infer a code fix from the symptom alone. Capture the phone's `adb logcat` or Android Studio Logcat output. Likely diagnostic categories include device/Android/GPU-specific native Mapbox failure, stale application data, or another startup exception; location denial itself is handled by the app and should not be assumed to be the cause.

Crash capture procedure after enabling USB debugging and approving the computer on the phone:

```powershell
adb devices -l
adb -s PHONE_SERIAL logcat -c
# Open ISOKO on the phone and reproduce the crash.
adb -s PHONE_SERIAL logcat -d -v time > C:\SMS\ScooterLock\isoko-phone-crash.txt
```

Keep the full log until the fatal exception and native backtrace are identified. The exact phone model, Android version/API level, ABI, whether the crash occurs before or after location permission/map navigation, and whether a clean reinstall changes it are part of the acceptance record.

## Remaining Work

- Obtain and configure the production Mapbox public token and billing/usage alerts.
- Implement the Supabase-rider-protected discovery API with public scooter code, availability, safe battery state, online state, and validated location fields.
- Add scalable Mapbox scooter sources/layers after that API exists.
- Define exact lock-location freshness and GPS-validity thresholds from final-firmware evidence.
- Add analytics/crash reporting only after consent/privacy decisions.
