# Auto Sale Umar — native iOS

The React Native / Metro layer has been removed. The app is now a SwiftUI iPhone application with a native WKWebView shell around `https://autosaleumar.com`, native settings, native SF Symbols and a native bottom navigation layer.

## Architecture

- SwiftUI + WKWebView
- iOS 17 minimum; iOS 26 Liquid Glass when available
- XcodeGen project generation (`project.yml`)
- Bundle ID: `com.autosaleumar.app`
- Xcode 26 / macOS 26 GitHub runner
- Simulator compile gate before release
- App Store distribution signing and direct TestFlight upload
- No React Native, npm, CocoaPods, Metro or Cloudflare Quick Tunnel in the mobile repository

The public website/backend can still remain on Cloudflare; this repository no longer needs Cloudflare for the mobile development/runtime layer.

## TestFlight

1. Configure repository secrets:
   - `APPLE_TEAM_ID`
   - `APPLE_ID_EMAIL`
   - `APPLE_APP_SPECIFIC_PASSWORD`
   - `IOS_SIGNING_KEY_PASSWORD`
2. Put the encrypted Apple Distribution private key at `Signing/distribution-private-key.enc`.
3. Put an App Store Connect provisioning profile for `com.autosaleumar.app` in `Signing/`.
4. Run **Build Auto Sale Umar / TestFlight** with `upload_to_testflight = true`.

If Auto Sale Umar and Lattice use the same Apple Developer team and Apple Distribution certificate, the same encrypted distribution private key can be reused. The provisioning profile must still be created specifically for `com.autosaleumar.app` and must include that same distribution certificate.

Set repository variable `AUTO_TESTFLIGHT=true` if every verified source update should automatically become a TestFlight build.

## ZIP updates

Future source patches can be uploaded to repository root using the name `autosaleumar-ios-*.zip`. The apply workflow extracts the patch, generates the Xcode project, compiles an unsigned iOS Simulator build, and only commits the patch after the Xcode gate passes.
