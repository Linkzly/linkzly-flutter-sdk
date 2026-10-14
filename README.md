# Linkzly Flutter SDK

Flutter bridge for Linkzly deep linking, deferred attribution, event tracking, affiliate attribution, and mobile measurement.

Full documentation: https://docs.linkzly.com/docs/sdk-flutter

Guides: [Tracking events](https://docs.linkzly.com/docs/sdk-tracking-events), [Tracking purchases](https://docs.linkzly.com/docs/sdk-tracking-purchases), [Integrations setup](https://docs.linkzly.com/docs/sdk-integrations-setup).

## Using an AI coding agent

If you use an AI coding agent (Claude Code, Codex, Cursor, GitHub Copilot, Antigravity), give it the Linkzly skill and ask it to add the SDK to your app: `npx skills add Linkzly/skills`. The skill carries these instructions, cut to your platform, and rules for the SDK behaviours that are easy to get wrong. It asks you for your SDK key and never makes one up. See [Set up with an AI agent](https://docs.linkzly.com/docs/sdk-ai-agents).

## Requirements

Minimums declared by the package:

- Flutter 3.35.6+
- Dart 3.9+
- iOS 13+
- Android API 21+

## Installation

**SDK version:** 1.0.6

### 1. Add the Flutter package

The Flutter SDK is published on pub.dev: https://pub.dev/packages/linkzly_flutter_sdk

```bash
flutter pub add linkzly_flutter_sdk
```

Or add it manually to your app's `pubspec.yaml` and run `flutter pub get`:

```yaml
dependencies:
  linkzly_flutter_sdk: ^1.0.6
```

### 2. iOS Setup

#### 2a. Add LinkzlySDK to your Podfile (required)

The native iOS `LinkzlySDK` is **not on CocoaPods Trunk**: `pod install` cannot resolve it transitively and fails with `Unable to find a specification for 'LinkzlySDK'`. Add an explicit pin to your app's `ios/Podfile`, inside the `target 'Runner'` block:

```ruby
target 'Runner' do
  use_frameworks!

  # Required: pin the native LinkzlySDK from GitHub.
  pod 'LinkzlySDK', :git => 'https://github.com/Linkzly/linkzly-ios-sdk.git', :tag => '1.0.7'

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end
```

Then run:

```bash
cd ios && pod install --repo-update && cd ..
```

#### 2b. Configure `Info.plist`

Add the following keys to `ios/Runner/Info.plist`:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>We use your data to provide personalized content and improve your app experience.</string>

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>your.bundle.identifier</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>your-app-scheme</string>
    </array>
  </dict>
</array>
```

Replace the example `NSUserTrackingUsageDescription` text with your own. The permission prompt shows it to the person, so keep it short and specific; iOS adds your app's name itself.

If you call `Linkzly.instance.updateConversionValue(...)` for SKAdNetwork attribution, you must also add `SKAdNetworkItems` with the ad-network identifiers your app uses. Linkzly does not require its own identifier here unless instructed by your account manager.

#### 2c. Configure Associated Domains (Universal Links)

Universal Links **do not work without an Associated Domains entitlement**. Create `ios/Runner/Runner.entitlements` (or update yours) with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.developer.associated-domains</key>
  <array>
    <string>applinks:your-linkzly-domain.example</string>
  </array>
</dict>
</plist>
```

Open `ios/Runner.xcworkspace` in Xcode and:
- Select the Runner target → Signing & Capabilities → confirm **Associated Domains** lists your domain.
- Or set `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;` in each build configuration's `buildSettings` (Debug / Release / Profile).

Replace `your-linkzly-domain.example` with the host you configured in the Linkzly Console for this app.

Universal Links also require a valid Apple App Site Association file for your app bundle identifier and team ID on that domain.

### 3. Android Setup

Add JitPack to your app's Android repositories so Gradle can resolve the native Android SDK dependency.

For Kotlin DSL Flutter projects, add it to `android/build.gradle.kts`:

```kotlin
allprojects {
  repositories {
    google()
    mavenCentral()
    maven("https://jitpack.io")
  }
}
```

If your app uses `dependencyResolutionManagement` in `android/settings.gradle.kts`, add JitPack there instead:

```kotlin
dependencyResolutionManagement {
  repositories {
    google()
    mavenCentral()
    maven("https://jitpack.io")
  }
}
```

For Groovy Flutter projects, add it to `android/build.gradle`:

```gradle
allprojects {
  repositories {
    google()
    mavenCentral()
    maven { url 'https://jitpack.io' }
  }
}
```

The Flutter plugin declares the native Android SDK itself and Gradle brings it in, so you do not add an Android SDK dependency line. The only Android step is the JitPack repository above.

#### 3a. Configure Android Manifest Deep Links and App Links

Add Linkzly deep link intent filters inside the existing Flutter launcher activity in `android/app/src/main/AndroidManifest.xml`.
Do not create a separate activity for Linkzly links. Keep the standard launcher intent filter, then add:
- a custom scheme deep link intent filter for URI schemes such as `example://...`
- an Android App Links intent filter for verified HTTPS links such as `https://example.linkzly.com/...`

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop">
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>

    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="example" />
    </intent-filter>

    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https" android:host="example.linkzly.com" />
    </intent-filter>
</activity>
```

For live client apps, replace `example` with the custom URI scheme assigned to the app and replace `example.linkzly.com` with the verified Linkzly domain configured in the Linkzly Console.

Android App Links also require a valid Digital Asset Links file for your app package and signing certificate on that domain.

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:linkzly_flutter_sdk/linkzly_flutter_sdk.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Linkzly.instance.deepLinkStream.listen((DeepLinkData data) {
    // Route the user based on data.path and data.parameters.
  });

  Linkzly.instance.universalLinkStream.listen((UniversalLinkEvent event) {
    // Optional: inspect the raw app/universal link event.
  });

  await Linkzly.instance.configure(
    const LinkzlyConfig(
      sdkKey: 'slk_your_sdk_key',
      environment: LinkzlyEnvironment.production,
    ),
  );

  runApp(const MyApp());
}
```

Your SDK key starts with `slk_` and is shown in the Linkzly Console under **Apps → Manage app → Overview → SDK Configuration**. Each app has a unique key — do not share keys between apps.

`configure` completes even when the native SDK refused the key. A key that is not `slk_` followed by at least 40 hex characters (the placeholder above is one) leaves the SDK unconfigured for the life of the app process, and later `configure` calls are ignored. After you put the real key in, stop the app and run it again; hot reload and hot restart are not enough.

## Tracking Events

**Register the name first.** A custom event is kept only if its name is registered for the app in the console. An unregistered name is dropped, and on the default batched path the call and the flush still report success. See [Register each name in the console](https://docs.linkzly.com/docs/sdk-tracking-events#register-each-name-in-the-console).

```dart
// Custom event: the name, then an optional positional map of parameters
await Linkzly.instance.trackEvent('signup_completed', {'method': 'email'});

// Batch
await Linkzly.instance.trackEventBatch([
  const BatchEvent('level_started', parameters: {'level': 1}),
]);

await Linkzly.instance.flushEvents();
final int pending = await Linkzly.instance.getPendingEventCount();
```

### Purchases and refunds

Send `revenue`, `currency` and `transactionId` in every call. `transactionId` is the dedup key. A refund reuses the original `transactionId`. Purchases are recorded only when Revenue & LTV is enabled for your organisation. See the [purchases guide](https://docs.linkzly.com/docs/sdk-tracking-purchases).

```dart
final bool purchased = await Linkzly.instance.trackPurchase({
  'revenue': 29.99,
  'currency': 'USD',
  'transactionId': 'order-12345',
});

final bool refunded = await Linkzly.instance.trackRefund({
  'revenue': 29.99,
  'currency': 'USD',
  'transactionId': 'order-12345',
});
```

## Affiliate Attribution

```dart
// Capture from a deep link URL: call this from your universal/app link handler
await Linkzly.instance.captureAffiliateAttribution(url);

final String? clickId = await Linkzly.instance.getAffiliateClickId();
final AffiliateAttribution attribution =
    await Linkzly.instance.getAffiliateAttribution();
final bool hasAttribution = await Linkzly.instance.hasAffiliateAttribution();
await Linkzly.instance.clearAffiliateAttribution();
```

## Gaming Tracking

Gaming tracking runs a separate pipeline with its own credentials. Call `configureGamingTracking` first.

```dart
await Linkzly.instance.configureGamingTracking(
  apiKey: 'YOUR_GAMING_API_KEY',
  organizationId: 'YOUR_ORGANIZATION_ID',
  gameId: 'YOUR_GAME_ID',
  options: const GamingTrackingOptions(autoSessionTracking: true),
);

await Linkzly.instance.identifyGamingPlayer('player-42', {'tier': 'gold'});
await Linkzly.instance.startGamingSession();
await Linkzly.instance.trackGamingEvent('level_complete', data: {'level': 3});
await Linkzly.instance.setGamingAttribution(clickId: 'click-abc');

final GamingTrackingStatus status = await Linkzly.instance.getGamingStatus();

await Linkzly.instance.flushGamingEvents();
await Linkzly.instance.endGamingSession();
await Linkzly.instance.clearGamingAttribution();
await Linkzly.instance.resetGamingTracking();
```

## Debug and batching controls

These controls do not work on iOS: every `debug...` call fails with a `PlatformException` whose code is `DEBUG_ONLY`. On Android they work in debuggable app builds only. The plugin has no `simulateServerConfig` or `printDebugConfig`. Accepted strategies for `debugSetBatchingStrategy`: `"all"` batches every event, `"smart"` (the default) batches custom events only, `"instant"` sends everything at once, `"custom"` behaves like `"smart"`.

```dart
await Linkzly.instance.debugSetBatchingStrategy('instant'); // 'all' | 'smart' | 'instant' | 'custom'
await Linkzly.instance.debugSetBatchSize(5);
await Linkzly.instance.debugSetFlushInterval(30); // seconds
final Map<String, Object?>? config = await Linkzly.instance.debugGetConfig();
await Linkzly.instance.debugResetConfig();
```

## API Reference

Every method is called as `Linkzly.instance.<method>(...)`.

- Setup: `configure`
- Install, open and events: `trackInstall`, `trackOpen`, `trackEvent`, `trackEventBatch`, `flushEvents`, `getPendingEventCount`. The SDK sends the install itself on the first launch of a new install, so calling `trackInstall` on a new install sends a second install event. On iOS, `deepLinkStream` receives the deferred `DeepLinkData` from the automatic install. On Android it does not, so an explicit `trackInstall` is currently the only way to get it there; call it once, behind your own first-launch flag (the flag stops a third event, not the second). The SDK already sends opens itself: when the app returns to the foreground after more than 30 seconds, and from `configure` unless `autoTrackAppOpens` is `false`. Each explicit `trackOpen` call sends one more open event; call it only when you need the `DeepLinkData` it returns.
- Revenue: `trackPurchase`, `trackRefund`
- Identity: `setUserId`, `getUserId`, `getVisitorId`, `resetVisitorId`
- Deep links: `handleUniversalLink`, and the streams `deepLinkStream` and `universalLinkStream`
- Affiliate: `captureAffiliateAttribution`, `getAffiliateAttribution`, `getAffiliateClickId`, `hasAffiliateAttribution`, `clearAffiliateAttribution`
- Tracking permission and SKAdNetwork (iOS only): `requestTrackingPermission`, `getAttStatus`, `getIdfa`, `updateConversionValue`
- Advertising tracking: `setAdvertisingTrackingEnabled`, `isAdvertisingTrackingEnabled`
- Push: `setNotificationToken`, `getNotificationToken`, `hasNotificationToken`, `clearNotificationToken`, `initializePush`, `disablePush`
- Privacy: `setTrackingEnabled`, `isTrackingEnabled`. `setTrackingEnabled(false)` stops custom events, purchases and refunds, and on Android `trackEventBatch`; on iOS `trackEventBatch` is not stopped. It does not stop the install, open and session-end events the SDK sends itself, and on Android it has no effect before `configure`. The SDK sends nothing before `configure`: an app that must send nothing before the user consents delays `configure` until the user has consented, and uses `setTrackingEnabled(false)` afterwards to stop events, purchases and refunds.
- Gaming: `configureGamingTracking`, `identifyGamingPlayer`, `trackGamingEvent`, `flushGamingEvents`, `startGamingSession`, `endGamingSession`, `setGamingAttribution`, `clearGamingAttribution`, `getGamingStatus`, `resetGamingTracking`
- Debug (fail with `DEBUG_ONLY` on iOS; debuggable builds only on Android): `debugSetBatchingStrategy`, `debugSetBatchSize`, `debugSetFlushInterval`, `debugResetConfig`, `debugGetConfig`

On Android the iOS-only methods do nothing: `updateConversionValue` returns `false`, `requestTrackingPermission` returns `'unsupported'`, `getIdfa` and `getAttStatus` return `null`.

On iOS, `requestTrackingPermission` returns `'authorized'`, `'denied'`, `'restricted'`, `'notDetermined'` or `'unknown'`. It hands the request to Apple's App Tracking Transparency framework, so Apple's rules decide what happens:

- **The `Info.plist` key comes first.** `NSUserTrackingUsageDescription` has to be in `Info.plist` before the first call: the app crashes if the call runs without it.
- **The app has to be active.** iOS shows the prompt only while the app is active. Called earlier, while the app is still starting, no prompt appears and the call returns at once with the current status, which is `'notDetermined'` on a new install. Call it from a screen the person has reached.
- **iOS 14.5 or later.** On an earlier iOS version the call returns `null`.

The SDK does not wait for the answer. It reads the IDFA at the moment it sends an event, and `configure` sends the install event on the first launch. So the install event has no IDFA unless the person had already allowed tracking when `configure` ran, and the SDK does not send it again once they do. Events sent after the person allows tracking carry the IDFA.

## Push Notification Support

The SDK exposes **two push features**. They are not independent: broadcast delivery is unlocked by device token registration, so start with the first one.

| Feature | Methods | What it does | When to use |
|---|---|---|---|
| **Device token registration** | `setNotificationToken` / `getNotificationToken` / `hasNotificationToken` / `clearNotificationToken` | Registers this device's **Firebase Cloud Messaging (FCM) registration token** in Linkzly's device registry so campaigns can target the specific device/user. On iOS as well as Android, pass the token `firebase_messaging` gives you, never the APNs device token. Devices registered through the SDK are reached through Firebase Cloud Messaging. | You want Linkzly to send (or target) notifications to individual devices/users. |
| **Broadcast topic subscription** | `initializePush` / `disablePush` | Subscribes the device to its **per-(Smart App, platform) FCM topic** for "send to All" campaigns. The topic name comes from a successful `setNotificationToken` registration — `initializePush()` alone is a no-op until then. FCM-only, via reflection in the native SDK. | You need broadcast-to-everyone campaigns and use Firebase Cloud Messaging. |

Before `configure` has run, `setNotificationToken` is ignored on both iOS and Android (nothing is stored). If your app delays `configure`, for example until the user has consented, call `setNotificationToken` again after `configure` with the current token from your Firebase Messaging library; a call made after `configure` registers normally.

**Registering a token is the whole setup.** A successful `setNotificationToken()` subscribes the device to its broadcast topic immediately, and the native SDK re-subscribes on every launch. `initializePush()` / `disablePush()` are recovery and opt-out controls, not the mechanism.

> **Stale native SDK.** Push lives in the native iOS and Android SDKs. If the build cannot find these methods, or broadcasts never arrive, your project is probably resolving an older native SDK from a lockfile or cache. Refresh both:
>
> ```bash
> cd ios && pod update LinkzlySDK && cd ..
> cd android && ./gradlew --refresh-dependencies && cd ..
> ```

### Registering a device push token

The example below needs `firebase_core` and `firebase_messaging` in your app (`flutter pub add firebase_core firebase_messaging`) with Firebase set up. They are prerequisites of this example only: `setNotificationToken` takes the FCM registration token.

Capture the device push token from your push library (e.g. `firebase_messaging`) and forward it. The native SDK throttles network calls (it only re-registers when the token, user, or app version changes, or after 7 days), so it is safe to call on every launch.

Call `Firebase.initializeApp()` **before** this — Flutter apps commonly initialize Firebase inside an async `main()`, and if it lands after the token is registered the topic is stored but the subscribe fails. Nothing is lost: the native SDK re-subscribes on the next launch, and `initializePush()` fixes it immediately.

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

await Firebase.initializeApp();

final String? token = await FirebaseMessaging.instance.getToken();
if (token != null) {
  await Linkzly.instance.setNotificationToken(token);
}

FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
  Linkzly.instance.setNotificationToken(newToken);
});
```

**Binding to a user:** when you call `Linkzly.instance.setUserId(...)`, the native SDK automatically re-registers the stored token against the new user id.

**On logout / notifications disabled:** clear the token — this removes it locally and revokes it server-side.

```dart
await Linkzly.instance.clearNotificationToken();
```

**Inspecting state:**

```dart
final token = await Linkzly.instance.getNotificationToken(); // String?
final has = await Linkzly.instance.hasNotificationToken();   // bool
```

### Broadcast topic subscription (FCM-only)

There is no separate broadcast setup call — the registration above already subscribes this device to its topic (`linkzly_broadcast_<smartAppId>_<platform>`), and the native SDK re-subscribes on every launch. Topics are scoped per Smart App and platform, so a campaign only reaches the app it selected; the legacy shared `linkzly_broadcast` topic is unsubscribed automatically.

`initializePush()` re-subscribes to the topic stored by the last successful `setNotificationToken()` registration. That makes it a **recovery call** for two situations: you unsubscribed from the topic yourself, or registration succeeded while Firebase Messaging was not yet live so the topic was stored but the subscribe failed. If registration has never succeeded there is no stored topic and it returns `false` — fix the registration instead.

```dart
final resubscribed = await Linkzly.instance.initializePush();
if (!resubscribed) {
  // No topic stored yet (register first) or Firebase Messaging is unavailable.
}
```

```dart
await Linkzly.instance.disablePush();
```

> **`disablePush()` is session-scoped, not a durable opt-out.** It unsubscribes, but the stored topic and token are kept, so the next launch re-subscribes. For a permanent opt-out use `clearNotificationToken()` — it revokes the token server-side and clears the stored topic.

If your app also uses another push provider for its own delivery, you do **not** need to call these methods for it. Devices registered through the SDK are reached through Firebase Cloud Messaging.

#### Troubleshooting

| Symptom | Likely cause |
|---|---|
| `initializePush()` returns `false` | No topic stored yet — `setNotificationToken()` has not completed successfully. Or Firebase Messaging is not in your app. |
| Broadcasts never arrive | The device never registered. Check `setNotificationToken()` was called with a real FCM registration token (on iOS the Firebase token, not the APNs device token) and the registry call succeeded. |
| Broadcasts arrive only after a restart | Firebase was not live when the token registered, so the topic was stored but the subscribe failed. Move `Firebase.initializeApp()` earlier, or call `initializePush()` once Firebase is ready. |
| Notifications stop after a "disable" | `disablePush()` only lasts the session. Use `clearNotificationToken()`. |
| Wrong app receives a campaign | The device is still on the legacy shared topic — dropped on the next successful registration against a current native SDK. |

## Deep Link Streams

Use `deepLinkStream` for backend-enriched deep link data and `universalLinkStream` for raw universal/app link capture events.

```dart
final subscription = Linkzly.instance.deepLinkStream.listen((DeepLinkData data) {
  print(data.path);
});
```

## Notes

The Flutter SDK does not reimplement attribution logic. Install/open attribution, event queuing, SKAdNetwork conversion updates, ATT/IDFA, affiliate storage, and push-topic reflection are delegated to the native Linkzly SDKs.
