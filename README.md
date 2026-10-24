# Genie

Flutter app for the Genie property marketplace: browse listings on a map, draw land
boundaries, list your own property, and chat with owners (end-to-end encrypted).

The backend lives in the `genie-backend` repository.

## Run it

```bash
cp .env.example .env              # for debug runs
cp .env.example .env.production   # for release builds
flutter pub get
flutter run --dart-define-from-file=.env
flutter build apk --release --dart-define-from-file=.env.production
```

Set `API_BASE_URL` in the env files to point at a local backend
(Android emulator: `http://10.0.2.2:4000`) or the hosted one. In VS Code, F5 passes the file
for you (`.vscode/launch.json`). A debug run without it stops at once and says so, instead of
quietly talking to the production server; a release build without it uses production.

The env files are git-ignored and **not shipped in the app**: their values are compiled in
(`lib/core/config/app_config.dart`). That keeps them out of the APK's files, but a compiled-in
value can still be extracted, so they must never contain secrets.

## Error reporting (Sentry)

Errors the app does not catch (Flutter's own and uncaught async errors) go to Sentry when the env file has `SENTRY_DSN` (the
Flutter project's DSN in Sentry; a DSN can only write reports, so it may be compiled in) and,
optionally, `SENTRY_ENVIRONMENT` (default `production` for a release build, `development`
otherwise). Without `SENTRY_DSN` nothing is sent. Reports carry no IP address or request details, and only
the user's id (`lib/core/observability/error_reporting.dart`). It uses Sentry's Dart client, not
`sentry_flutter`: that one needs Android 8 (minSdk 26) and did not build with this Flutter version,
so crashes in native code are not reported.
Errors the app handles itself (offline, a refused request) are shown to the user, not reported.

## Quality gates

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

CI runs the same three checks, then builds the release APK from `main`.

### Release signing

Without `android/key.properties` the release build falls back to the debug key, which is fine
for testing but not for the Play Store. Copy `android/key.properties.example` and fill it in.
In CI set the secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD`.

## Code layout

Organised by feature first, then by layer.

```
lib/
  app/         the MaterialApp, routes, and what spans several features (sign-out)
  core/        config, errors, logging, network (Dio client + interceptors), theme, device info
  l10n/        translations: app_en.arb, app_km.arb (generated/ is built from them)
  features/
    auth/      login, register, Google sign-in, password reset, guest session
    home/      map screen, drawing tools, UTM/OCR locate
      utils/map/markers/   how each kind of map marker is drawn
      utils/map/layers/    what is drawn at each zoom level
    property/  listings: browse, add, detail, saved
    chat/      conversations, messages
      data/    socket + backup API
      e2ee/    keys, PIN backup, setup and key-management logic (no UI)
    profile/   the "User" tab and the personal information screen
    security/  chat keys (PIN, forgotten PIN, reset), password, logged-in devices and the
               new sign-in alert, deactivate / delete account
    settings/  the saved theme and language, and the rows that change them
  shared/      widgets reused by several features
```

Rules the code follows:

- Widgets render state and forward events; API calls and business rules live in repositories,
  services and notifiers.
- Logging goes through `AppLogger` (silent in release). `print` is a lint error.
- Network logging (`SafeLogInterceptor`, debug only) prints method, path and status, never
  headers or bodies, because those carry tokens and passwords.
- Anything that needs a dialog takes a callback (see `PinPrompt`) so the logic stays testable.

## Light and dark theme

Every colour has a name in `lib/core/theme/app_colors.dart`, with a light and a dark value.
Widgets read them with `context.colors.textPrimary`, `context.colors.surface` and so on, never as
hex values, so a new screen works in both themes without extra work. `AppTheme` builds the two
`ThemeData` from the same palette. The user's choice (System / Light / Dark) is kept on the device
by `features/settings`.

Two places keep their own colours on purpose: what is drawn onto the map (`home/utils/map`) and
the toast messages (`shared/utils/app_popup.dart`).

## Languages

English and Khmer. To add or change a text:

1. Add the key to `lib/l10n/app_en.arb` and its translation to `lib/l10n/app_km.arb`.
2. Run `flutter gen-l10n` (also run by `flutter pub get`, `run` and `build`).
3. Use it in a widget: `context.l10n.theKey`.

To add a language, add `app_<code>.arb` and list it in `AppLanguages` (`lib/l10n/l10n.dart`).
Only widgets read translations: state and data classes return a result (an enum) and the screen
picks the words, see `ProfileSaveResult` or `AccountActionResult`.

Not translated yet (shown in English in both languages): the Terms of Service, the choices inside
the add-property drop-downs (their text is also the value sent to the server), texts built with a
name or number in them, and messages composed in state classes (login form validation, chat send
errors, last-seen labels).

## Security notes

- Tokens are kept in the platform keystore (`flutter_secure_storage`).
- Chat messages are encrypted on the device; the server only stores ciphertext.
- The identity key is backed up encrypted with the user's PIN. Forgetting the PIN means the
  backup cannot be recovered, and the keys cannot be reset: changing the PIN and resetting keys
  both ask for the current PIN, which the server checks, so an unlocked phone is not enough to
  take over someone's chats.
- Changing the password, deactivating and deleting the account ask for the password again (or a
  fresh Google sign-in).
- A forgotten PIN is recovered with the account password. An account that signs in with Google
  has none until its owner creates one (Security > Create password). A device that still holds
  the chat keys keeps them and the history; any other device gets new keys.
- When the server ends this device's session (signed out from another device, password changed,
  account deactivated or deleted) the app returns to the welcome screen at once: the API client
  reports it (`sessionEndedProvider`) and `lib/app/app.dart` acts on it. Being offline never
  signs anyone out.
- A device signed in for less than a day cannot sign other devices out, change the password, or
  deactivate or delete the account. The server decides; the app only shows what it says
  (`DeviceList.canSignOutOthers`, `AccountActionResult.deviceTooNew`).
- The app tells the user when another device signs in (`NewSignInAlert`), by comparing the device
  list with the devices it has already shown.
- The profile picture is uploaded (camera or gallery) or synced from the Google account; the
  options are in `profile/presentation/widgets/avatar_options_sheet.dart`.
- Every picture is compressed on the device before it is uploaded (`lib/core/media`): re-encoded
  as a JPEG, its shorter side reduced (profile 480 px, chat 1080 px, listing 1280 px), and the
  quality lowered until it fits the target (about 120 KB, 400 KB and 600 KB). A phone photo of
  5 to 10 MB therefore uploads as a few hundred KB, and its location metadata is dropped. The
  original may be at most 500 MB, and a picture still above the limit after compression (1 MB,
  3 MB and 4 MB) is refused with a message. The sizes are in `ImageUploadPolicy`.
- Chat pictures are encrypted after compression, so the server cannot do it for them: the limit
  there is enforced by the storage bucket, not by compressing on the server.
- Sign-in requests carry the device's name and platform (`X-Device-Name`, `X-Device-Platform`)
  so the owner can recognise it under "Logged-in devices".
