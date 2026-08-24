# Auto Sale Umar — native iOS / TestFlight

Auto Sale Umar is a native SwiftUI iPhone app with a WKWebView shell around `https://autosaleumar.com`, native settings, SF Symbols, and the iOS 26 Liquid Glass tab bar when available.

## Release architecture

The repository already contains the automated native iOS pipeline in `.github/workflows/apply-mobile-update.yml`.

The normal update path is:

1. Put a ChatGPT patch named exactly `mobile-update.zip` in the repository root and commit it to `main`.
2. GitHub Actions safely extracts the ZIP into a staging directory. `.git`, `.github`, and `Signing` are protected from patch writes.
3. XcodeGen generates `AutoSaleUmar.xcodeproj` from `project.yml`.
4. An unsigned iOS Simulator build is compiled as a gate. The patch is committed to `main` only if this build succeeds.
5. If repository variable `AUTO_TESTFLIGHT` is exactly `true`, the same workflow checks out the verified commit, rebuilds it for Release, signs it with the App Store profile from GitHub Secrets, exports the IPA, validates it with Apple, and uploads it to TestFlight.

No `.p8` App Store Connect API key is required by this pipeline. TestFlight upload uses the Apple ID email plus an app-specific password, matching the working iumrah Business approach.

## Required GitHub Secrets

The automatic TestFlight release uses:

- `APPLE_TEAM_ID`
- `APPLE_ID_EMAIL`
- `APPLE_APP_SPECIFIC_PASSWORD`
- `IOS_SIGNING_KEY_PASSWORD`
- `IOS_DISTRIBUTION_PRIVATE_KEY_B64`
- `IOS_APP_STORE_PROFILE_B64`

The Development/Debug secrets can remain in the repository for the legacy Debug IPA workflow, but they are not required for App Store/TestFlight Release signing.

## One required repository variable

Open **Settings → Secrets and variables → Actions → Variables** and create:

- Name: `AUTO_TESTFLIGHT`
- Value: `true`

With this variable enabled, every successfully verified `mobile-update.zip` update becomes a new TestFlight build automatically.

## iOS build configuration

- XcodeGen project: `project.yml`
- Scheme: `AutoSaleUmar`
- Bundle ID: `com.autosaleumar.app`
- Minimum iOS: 17.0
- Release build number: GitHub Actions run number
- Signing: Apple Distribution + App Store Connect provisioning profile
- Upload: `xcrun altool` using Apple ID + app-specific password

## Privacy manifest

`Resources/PrivacyInfo.xcprivacy` is included in the app bundle. Auto Sale Umar uses `UserDefaults` only for its own local language/theme preferences, declared with Apple approved reason `CA92.1`.

## Legacy workflows

The old Metro/React Native and Development Debug IPA workflows may still appear under Actions, but the production path is **Auto Sale Umar Native iOS CI**. The app source itself is native SwiftUI; Metro is not part of the TestFlight release path.
