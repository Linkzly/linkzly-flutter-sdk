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
