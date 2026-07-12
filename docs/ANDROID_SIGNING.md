# Android release signing

Release builds are signed with your own upload key when
`android/key.properties` is present, and fall back to the debug key otherwise
(so a fresh clone and CI still build). Wiring lives in
`android/app/build.gradle.kts`.

## 1. Generate an upload keystore (once)

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Keep the `.jks` file and the passwords safe and **out of git** (both are
already gitignored). Losing the key means you can't update the app on Play.

## 2. Point the build at it

Copy the template and fill it in:

```bash
cp android/key.properties.example android/key.properties
```

```properties
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

## 3. Build a signed release

```bash
flutter build apk --release        # signed APK
flutter build appbundle --release  # signed AAB for the Play Store
```

Verify the signature:

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

## CI / Play Store

For CI signing, base64-encode the keystore into a secret, decode it on the
runner, write `key.properties` from secrets, then build — never commit either
file. Also set a real `applicationId` (currently `com.example.lifeos`) in
`android/app/build.gradle.kts` before publishing.
