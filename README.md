# Auto Sale Umar — native iOS client

Pure SwiftUI iPhone application for Auto Sale Umar.

## Architecture
- SwiftUI only for the application UI. No WKWebView, injected CSS, website mirror, HTML or JavaScript shell.
- iOS 17 minimum, Xcode 26 project generated with XcodeGen.
- Native navigation, sheets, forms, search, favorites, compare and contact flows.
- Public vehicle data is requested over HTTPS JSON APIs from `https://autosaleumar.com`; D1/R2 stay server-side.
- Local UserDefaults is used only for UI preferences, favorites and a lightweight history of client actions.
- Existing GitHub Actions/TestFlight/signing workflow is intentionally not modified by native source update ZIPs.

## Client surfaces
- Premium launch/splash
- Home
- Vehicle catalog with native search/filtering
- Vehicle detail/gallery/specs
- Favorites and 2-car comparison
- Personal vehicle request
- Showroom visit booking
- Showroom/about/international delivery
- Contacts
- RU / Uzbek and system/light/dark settings

## Update flow
Upload `mobile-update.zip` to repository root. The existing workflow validates, applies and builds it. The update ZIP never contains `.github` or signing material.
