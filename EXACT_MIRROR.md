# Auto Sale Umar — Exact Mirror architecture

This mobile build deliberately does **not** translate the production website into React Native cards/styles.
The production Next.js website remains the visual and functional source of truth.

- Expo Web: the exact production website is rendered in an iframe inside the app shell.
- iOS/Android: an Expo DOM component owns a WebView and navigates it to the exact production website route.
- Native app shell keeps the requested tabs: Главная · Автомобили · Избранное · Профиль.
- Profile adds the requested Клиент ↔ Control System switch.
- Existing site routes, Cloudflare D1/R2 data, login, media, forms and Control System continue to be the same implementation.

This is intentional: pixel-for-pixel equality cannot be guaranteed by converting DOM/CSS to React Native StyleSheet primitives. Exact Mirror avoids that drift.
