# AutoSale Umar App

Native iOS-first client for the existing AutoSale Umar backend.

## Architecture
- Web: existing Next.js repository
- Mobile: this Expo/React Native repository
- Backend/API/database/media: existing `https://autosaleumar.com/api/*`
- iOS 26+: native Liquid Glass via `expo-glass-effect`
- Navigation: Expo Router Native Tabs (system native tab bar)

## First-time setup
1. Create a new empty GitHub repository for this app, e.g. `autosaleumar-app`.
2. Upload the contents of this ZIP to the repository root.
3. Create/sign in to an Expo account.
4. Open the repository in GitHub Codespaces.
5. Run `npm install`.
6. Run `npx eas-cli@latest login`.
7. Run `npx eas-cli@latest init` and allow it to add the Expo `projectId` to app config.
8. Run `npx eas-cli@latest build --profile development --platform ios` to create the first DEV build.
9. Install the resulting development build on the registered iPhone.
10. For live Fast Refresh in Codespaces, run `npm run start:tunnel` and open the development server from AutoSale Umar DEV.

## GitHub automatic OTA updates
Add repository secret `EXPO_TOKEN`. Every push to `main` will run typecheck and then publish an EAS Update to branch `development`.

Important: OTA updates and Fast Refresh are different. Fast Refresh requires a running Metro dev server. EAS Update is a published JS/assets update and is normally applied when the app checks/reloads/starts on a compatible runtime.

## Native rebuild required when
A new native library/configuration/plugin is added, the runtime changes, or native iOS settings change. Pure React/JS/TS/UI/API changes can normally use Fast Refresh or EAS Update.

## API
Default: `https://autosaleumar.com`. Override with `EXPO_PUBLIC_API_BASE_URL` when needed.

## Phone-friendly ZIP update workflow
After the first repository bootstrap, future assistant updates can be delivered as a ZIP named exactly `mobile-update.zip`.
Upload that ZIP to the repository root and commit it to `main`.
`Apply mobile-update.zip` will unpack it, run TypeScript checks, commit the extracted files, and publish a DEV EAS Update when `EXPO_TOKEN` is configured.
