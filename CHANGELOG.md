## 1.0.8 - Event property values, consent and SKAdNetwork coarse values

### Added
- `setConsent` and `getConsent`. `setConsent` takes `analytics`, `adUserData` and `adPersonalization`, each `ConsentState.granted`, `denied` or `unspecified`; a field you leave out keeps its value. The native SDK attaches the answers to every later event and sends a denial to Linkzly. A grant is never sent to Linkzly's server, so granting cannot undo a denial recorded there. `getConsent` returns what you have set, or `null` before the first `setConsent`.
- `updateConversionValue` takes optional `coarseValue` (`'low'`, `'medium'` or `'high'`) and `lockWindow` for SKAdNetwork 4. They apply on iOS 16.1 and later; any other value, or an older iOS, sends the fine value alone. Android still ignores the call.
- Documented the optional purchase keys `environment`, `original_transaction_id`, `refund_id` and `is_renewal` on `trackPurchase` and `trackRefund`. The plugin passes the whole map to the native SDK unchanged.

### Changed
- `trackEvent` and `trackEventBatch` now send a `DateTime` property as ISO 8601 UTC text with milliseconds (`2026-10-27T10:15:30.123Z`) instead of throwing and losing the event. NaN, Infinity or an unsupported value is dropped with a debug warning (inside a list or map it becomes `null`), a top-level `null` leaves the key out on both platforms, and the rest of the event is still sent. A property named with a Linkzly-reserved key (or the `__` prefix) logs a debug warning and is still sent.
- Minimum iOS version is now 15.0 (it was 13). The native iOS SDK 1.0.8 requires it.
- Tightened the iOS CocoaPods dependency from `LinkzlySDK ~> 1.0.7` to `~> 1.0.8`, and bumped the native Android dependency `com.github.Linkzly:linkzly-android-sdk` from 1.0.9 to 1.0.10, for consent support.

### Platform Support
- Requires native iOS `LinkzlySDK` 1.0.8+ and Android `linkzly-android-sdk` 1.0.10+. Both are pinned by the plugin.

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
