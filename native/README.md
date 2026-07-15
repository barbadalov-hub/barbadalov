# Native-app staging (`native/`)

This folder holds code and instructions for capabilities that **only work in a
native iOS/Android build**, not in the web PWA. It is **excluded from analysis
and from the web build** (`analysis_options.yaml` → `analyzer.exclude:
native/**`), so nothing here affects the current app until it is wired in.

Goal: when the Apple Developer account ($99/yr) is ready, everything needed for
the native app is already written here and can be activated in **one request**.

The app is deliberately built around **conditional-export seams**, so most of
this is "swap the backend", not "rewrite the feature".

---

## Feature status

| Capability | Web PWA | Native | What's needed |
|---|---|---|---|
| Receipt photo OCR | ❌ | ✅ already coded | `ocr_gateway_io.dart` (ML Kit) already ships; just iOS camera permission |
| Local reminders (water/meal/…) | in-app feed only | ✅ already coded | `notification_gateway` io backend already ships; iOS notification permission |
| Steps / sleep / heart-rate auto-sync | ❌ (mock) | ⬜ staged here | swap `deviceHealthSourceProvider` → `RealDeviceHealthSource` + `health` pkg |
| Live step counting (pedometer) | ❌ | ⬜ staged here | `pedometer` package + motion permission |
| Apple Watch / wearables | ❌ | ✅ via HealthKit | data flows through the `health` package above — no extra code |
| Background push (app closed) | ❌ | ⬜ future | needs an APNs push server — out of scope for a client-only build |
| 3D body model / photo body-morph | ❌ (2D silhouette shipped) | ⬜ future | needs a native 3D engine + body-segmentation ML model |

"already coded" = works the moment the project is built as a phone app; only OS
permission strings are required.

---

## One-request activation checklist

### 1. Dependencies (`pubspec.yaml`)
```yaml
  health: ^10.2.0        # HealthKit / Google Fit / Health Connect
  pedometer: ^4.0.2      # live step stream (optional)
```

### 2. Real device health source
- Copy `native/lib/core/devices/device_health_source_real.dart` →
  `lib/core/devices/device_health_source_real.dart`.
- In `lib/features/health/presentation/providers/health_providers.dart`, change
  `deviceHealthSourceProvider` to return `RealDeviceHealthSource(...)` on mobile
  and keep `MockDeviceHealthSource` elsewhere (a `dart.library.io` +
  `Platform.isIOS/isAndroid` guard, or a conditional export like the other
  seams). The rest of the sync flow (`SyncDeviceHealth`, the Health screen's
  sync button, the device picker) is unchanged.

### 3. iOS config (`ios/Runner/Info.plist`)
```xml
<key>NSHealthShareUsageDescription</key>   <string>Read steps, sleep and heart rate to fill your health rings.</string>
<key>NSHealthUpdateUsageDescription</key>  <string>Save workouts you log.</string>
<key>NSMotionUsageDescription</key>        <string>Count your steps.</string>
<key>NSCameraUsageDescription</key>        <string>Scan receipts.</string>
```
- Xcode → Signing & Capabilities → **+ HealthKit**.
- Notifications permission is requested at runtime by the existing gateway.

### 4. Android config
- `android/app/src/main/AndroidManifest.xml`: `ACTIVITY_RECOGNITION`, and Health
  Connect permissions per the `health` package README.

### 5. Build
- `flutter build ipa` / open in Xcode with the Apple Developer account, install
  on device. `flutter build apk` for Android.

---

## Notes
- Keep money as integer minor units, events through the core, i18n in all three
  languages — same rules as the rest of the app (see root `CLAUDE.md`).
- Nothing here should be imported from `lib/` until step 2 is done, or the web
  build will try to pull in phone-only packages.
