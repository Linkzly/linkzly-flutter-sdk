## 1.0.7 - App-scoped push broadcasts

### Changed
- Broadcast campaigns now use a per-(Smart App, platform) FCM topic assigned by the server during `setNotificationToken` registration, replacing the shared `linkzly_broadcast` topic. A campaign now reaches only the app it targets; devices are moved off the legacy topic automatically on the next successful registration.
- `initializePush()` is now a recovery call rather than the mechanism. Registering a token is what subscribes the device; `initializePush()` re-subscribes to the stored topic and is a no-op until a registration has succeeded.
- Bumped native Android dependency `com.github.Linkzly:linkzly-android-sdk` from 1.0.7 to 1.0.9 for app-scoped broadcast topics.
- Tightened the iOS CocoaPods dependency from `LinkzlySDK ~> 1.0` to `~> 1.0.7`. The previous constraint permitted versions with no push support at all.

### Fixed
- Added Tink / error_prone `-dontwarn` rules to the plugin's `consumer-rules.pro`, so host apps building with R8 full mode no longer fail on "Missing class" reports originating from `androidx.security:security-crypto`.

### Documentation
- Documented `initializePush` and `disablePush` in the Dart API, including that `disablePush()` is session-scoped — the next launch re-subscribes, and `clearNotificationToken()` is the durable opt-out.
- Reworked the README push section: registering a token is the whole setup, and the native SDK version requirements are now stated accurately.

### Platform Support
- Requires native iOS `LinkzlySDK` 1.0.7+ and Android `linkzly-android-sdk` 1.0.9+. Both are pinned by the plugin.

## 1.0.6 - Latest Android SDK support

### Changed
- Bumped native Android dependency `com.github.Linkzly:linkzly-android-sdk` from 1.0.6 to 1.0.7 for latest platform fixes and compatibility.

### Platform Support
- Android now resolves `linkzly-android-sdk` 1.0.7 via the Flutter plugin's `android/build.gradle` (JitPack).

## 0.1.4 - Push notification support

### Added
- Device token registration APIs: `setNotificationToken`, `getNotificationToken`, `hasNotificationToken`, and `clearNotificationToken` for APNs/FCM token management with Linkzly's device registry.
- Broadcast topic subscription APIs: `initializePush` and `disablePush` for FCM broadcast campaigns.
- Native bridge support on iOS and Android (requires LinkzlySDK ≥ 1.0.3 on iOS and `linkzly-android-sdk` ≥ 1.0.5 on Android).
- Push notification examples in the sample app and README documentation.

## 0.1.0 - Initial SDK Launch

### Added
- Initial public release of the Linkzly Flutter SDK.
- Core Dart API for generating and managing Linkzly links.
- Flutter plugin integration for native platform communication.

### Platform Support
- Android support via MethodChannel bridge.
- iOS support via MethodChannel bridge.
- EventChannel support for link and callback events.
