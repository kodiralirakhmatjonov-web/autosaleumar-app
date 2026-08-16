# Auto Sale Umar — iOS mobile client

Clean bare React Native iOS application. Expo and EAS are intentionally not used.

## Architecture

- React Native 0.87
- React 19.2.3
- Native Xcode project committed in `ios/`
- `react-native-webview` for `https://autosaleumar.com`
- Bundle ID: `com.autosaleumar.app`
- One GitHub Actions workflow: `.github/workflows/apply-mobile-update.yml`
- No App Store Connect is required for the registered-device Debug IPA flow

## GitHub Actions

Open **Actions → Auto Sale Umar Mobile CI → Run workflow** and choose a task:

- `validate` — npm dependency tree + repository check + TypeScript
- `ios-compile` — npm + CocoaPods + unsigned iOS Simulator Xcode compilation on `macos-26`
- `signing-csr` — creates a certificate signing request and private key artifact
- `debug-ipa` — builds a signed Debug IPA for an Apple Development provisioning profile
- `metro` — starts Metro plus an HTTPS Quick Tunnel for Fast Refresh

Uploading `mobile-update.zip` to the repository root automatically uses the same workflow. The update is first validated on Ubuntu, then compiled with CocoaPods/Xcode on `macos-26`, and is committed only after both gates pass. Update ZIPs are not allowed to modify `.github` or `.git`.

## Apple signing secrets

Configure these only after `validate` and `ios-compile` are green:

- `APPLE_TEAM_ID`
- `IOS_DEVELOPMENT_CERTIFICATE_P12_BASE64`
- `IOS_DEVELOPMENT_CERTIFICATE_PASSWORD`
- `IOS_DEVELOPMENT_PROFILE_BASE64`

The profile must be an **iOS App Development** provisioning profile for `com.autosaleumar.app` and must include the test iPhone UDID.
