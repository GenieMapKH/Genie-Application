# Genie

Flutter app for the Genie property marketplace: browse listings on a map, draw land
boundaries, list your own property, and chat with owners (end-to-end encrypted).

The backend lives in the `genie-backend` repository.

## Run it

```bash
cp .env.example .env              # debug runs read .env
cp .env.example .env.production   # release builds read .env.production
flutter pub get
flutter run
```

Set `API_BASE_URL` in the env files to point at a local backend
(Android emulator: `http://10.0.2.2:4000`) or the hosted one. The env files are
git-ignored and bundled into the app, so they must never contain secrets.

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
  core/        config, errors, logging, network (Dio client + interceptors), theme
  features/
    auth/      login, register, Google sign-in, password reset, guest session
    home/      map screen, drawing tools, UTM/OCR locate
      utils/map/markers/   how each kind of map marker is drawn
      utils/map/layers/    what is drawn at each zoom level
    property/  listings: browse, add, detail, saved
    chat/      conversations, messages
      data/    socket + backup API
      e2ee/    keys, PIN backup, setup and key-management logic (no UI)
    profile/   account screen
  shared/      widgets reused by several features
```

Rules the code follows:

- Widgets render state and forward events; API calls and business rules live in repositories,
  services and notifiers.
- Logging goes through `AppLogger` (silent in release). `print` is a lint error.
- Network logging (`SafeLogInterceptor`, debug only) prints method, path and status, never
  headers or bodies, because those carry tokens and passwords.
- Anything that needs a dialog takes a callback (see `PinPrompt`) so the logic stays testable.

## Security notes

- Tokens are kept in the platform keystore (`flutter_secure_storage`).
- Chat messages are encrypted on the device; the server only stores ciphertext.
- The identity key is backed up encrypted with the user's PIN. Forgetting the PIN means the
  backup cannot be recovered.
