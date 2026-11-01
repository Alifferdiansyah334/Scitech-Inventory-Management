# SIMS v1.0 — Flutter apps and API

This branch contains the Flutter application, Next.js API, database schema and source tests. The previous standalone web interface is not included.

## UI changes

[UI change notes and before/after screenshots](app_inventory/docs/ui-redesign.md) cover the Flutter redesign against `316f664` on `SIMS-v1.0`, including mobile and desktop captures, local verification results, and sample-data limitations. Flutter setup and component details are in [the app README](app_inventory/README.md).

## API and Flutter

Use Node.js 24. Run `npm ci`, configure `.env.local` using `.env.example`, then run `npm run dev`. Private Supabase and Brevo credentials stay on the server. Never put them in Flutter definitions or Git.

For a new Supabase project apply `supabase/bootstrap_sams.sql`, followed by `supabase/transition_setup.sql`. After changing static queries, regenerate the allowlist using `npm run db:prepare`, review and apply it before releasing the API.

Inside `app_inventory` run `flutter pub get`, then:

    flutter run -d chrome --web-port=5173 --no-web-resources-cdn

The local API uses port 3000. To serve Flutter and the API from one origin, build from `app_inventory`:

    flutter build web --release --base-href=/app/ --no-web-resources-cdn

Then from the repository root:

    node scripts/bundle-flutter.mjs
    npm run check:release
    npm run build
    npm run start

The two support contacts are defined in `lib/backend/admin-contacts.ts`. The user chooses a recipient before WhatsApp opens. Account, loan and image access is checked by the server. Colleague activity excludes private contacts, notes and condition photos.

## Direct APK updates

Keep one stable application ID and private signing key from the first distributed APK. Copy `app_inventory/android/key.properties.example` privately to `key.properties` and configure the keystore. Neither file nor the keystore should be committed. Debug signing is rejected for release builds. A debug-signed app cannot be updated using a different release signer.

Every update needs a higher build number. For the next release:

    node scripts/set-app-version.mjs 1.0.1+4

Build a signed APK inside `app_inventory` using a deployed HTTPS API origin:

    flutter build apk --release --dart-define=API_URL=https://YOUR-API-DOMAIN

From the repository root, prepare distribution files using Android build-tools `aapt` and `lib/apksigner.jar`:

    node scripts/prepare-android-release.mjs app_inventory/build/app/outputs/flutter-apk/app-release.apk /path/to/aapt /path/to/lib/apksigner.jar

Publish the generated `public/releases` directory together with the API at that same HTTPS origin. Generated APK files are excluded from Git. The update feed stays unavailable until a genuine signed APK and matching metadata are present.

The app displays an update notice and provides **Akun > Pembaruan aplikasi**. It downloads to private app cache and checks HTTPS origin, size, SHA-256, package ID, a higher version code and matching signing certificates before opening Android's system installer. The user grants installation permission and confirms installation. The app never bypasses Android security or uninstalls the existing app. Browser updates reload the app without clearing account storage.

## Verification and publishing prerequisites

    npm test
    npm run typecheck
    npm run lint
    npm run check:services

Inside `app_inventory`, run `flutter analyze --no-pub` and `flutter test`. Native installation must also be checked on an Android device before distribution.

Publishing requires a deployed HTTPS backend, a private release signing key and a hosted signed APK. Pushing this branch does not deploy hosting or publish an APK. Changelogs, local audit results, ENV files, signing material and generated binaries are excluded from Git.
