# Linkzly Flutter SDK

Flutter bridge for Linkzly deep linking, deferred attribution, event tracking, affiliate attribution, and mobile measurement.

## Requirements

- Flutter 3.35.6+
- Dart 3.9+
- iOS 13+
- Android API 21+

## Installation

### 1. Add the Flutter package

The Flutter SDK is published on pub.dev: https://pub.dev/packages/linkzly_flutter_sdk

```bash
flutter pub add linkzly_flutter_sdk
```

Or add it manually to your app's `pubspec.yaml` and run `flutter pub get`:

```yaml
dependencies:
  linkzly_flutter_sdk: ^0.1.0
```

#### Alternative: pin to a Git tag

```yaml
dependencies:
  linkzly_flutter_sdk:
    git:
      url: https://github.com/linkzly/linkzly-flutter-sdk.git
      ref: v0.1.0
```

#### Alternative: local monorepo development

```yaml
dependencies:
  linkzly_flutter_sdk:
    path: ../3rd-party-sdk/linkzly-flutter-sdk
```

### 2. iOS Setup

#### 2a. Add LinkzlySDK to your Podfile (required)

The native iOS `LinkzlySDK` is **not on CocoaPods Trunk** — `pod install` cannot resolve it transitively. Add an explicit pin to your app's `ios/Podfile`, inside the `target 'Runner'` block:

```ruby
target 'Runner' do
  use_frameworks!

  # Required: pin the native LinkzlySDK from GitHub.
  pod 'LinkzlySDK', :git => 'https://github.com/linkzly/linkzly-ios-sdk.git', :tag => '1.0.0'

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
  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
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

The Flutter plugin already declares the native Android dependency:

```gradle
implementation "com.github.Linkzly:linkzly-android-sdk:1.0.5"
```

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

Your SDK key starts with `slk_` and is shown in the Linkzly Console under **Apps → Manage App → Overview → SDK Configuration**. Each app has a unique key — do not share keys between apps.

## API Surface

- `configure`
- `handleUniversalLink`
- `trackInstall`
- `trackOpen`
- `trackEvent`
- `trackPurchase`
- `trackEventBatch`
- `flushEvents`
- `getPendingEventCount`
- `setUserId` / `getUserId`
- `setTrackingEnabled` / `isTrackingEnabled`
- `getVisitorId` / `resetVisitorId`
- `updateConversionValue`
- `requestTrackingPermission`
- `getAttStatus`
- `getIdfa`
- `setAdvertisingTrackingEnabled`
- `isAdvertisingTrackingEnabled`
- `setNotificationToken` / `getNotificationToken` / `hasNotificationToken` / `clearNotificationToken`
- `initializePush` / `disablePush`
- affiliate attribution helpers
- gaming tracking helpers
- debug batching helpers

## Push Notification Support

The SDK exposes **two push features**. They are not independent: broadcast delivery is unlocked by device token registration, so start with the first one.

| Feature | Methods | What it does | When to use |
|---|---|---|---|
| **Device token registration** | `setNotificationToken` / `getNotificationToken` / `hasNotificationToken` / `clearNotificationToken` | Registers this device's **APNs/FCM token** in Linkzly's device registry so campaigns can target the specific device/user. Works with **any** push provider. | You want Linkzly to send (or target) notifications to individual devices/users. |
| **Broadcast topic subscription** | `initializePush` / `disablePush` | Subscribes the device to its **per-(Smart App, platform) FCM topic** for "send to All" campaigns. The topic name comes from a successful `setNotificationToken` registration — `initializePush()` alone is a no-op until then. FCM-only, via reflection in the native SDK. | You need broadcast-to-everyone campaigns and use Firebase Cloud Messaging. |

**Registering a token is the whole setup.** A successful `setNotificationToken()` subscribes the device to its broadcast topic immediately, and the native SDK re-subscribes on every launch. `initializePush()` / `disablePush()` are recovery and opt-out controls, not the mechanism.

> **Native SDK versions.** Push lives in the native iOS/Android SDKs. This plugin already pins versions that support it — iOS `LinkzlySDK` 1.0.7+ and Android `linkzly-android-sdk` 1.0.9+ — so there is nothing extra to add.
>
> If the build can't find these methods, or broadcasts never arrive, your project is probably still resolving an older native SDK from a lockfile or cache:
>
> ```bash
> cd ios && pod update LinkzlySDK && cd ..
> cd android && ./gradlew --refresh-dependencies && cd ..
> ```

### Registering a device push token

Capture the device push token from your push library (e.g. `firebase_messaging`) and forward it. The native SDK throttles network calls (it only re-registers when the token, user, or app version changes, or after 7 days), so it is safe to call on every launch.

Call `Firebase.initializeApp()` **before** this — Flutter apps commonly initialize Firebase inside an async `main()`, and if it lands after the token is registered the topic is stored but the subscribe fails. Nothing is lost: the native SDK re-subscribes on the next launch, and `initializePush()` fixes it immediately.

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

await Firebase.initializeApp();

final token = await FirebaseMessaging.instance.getToken();
if (token != null) {
  await Linkzly.instance.setNotificationToken(token);
}

FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
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

If your app uses **OneSignal**, **Braze**, or another push provider, you do not need these methods. Your provider's own SDK handles subscriptions, and Linkzly delivers campaigns through whichever provider is configured in the Console.

#### Troubleshooting

| Symptom | Likely cause |
|---|---|
| `initializePush()` returns `false` | No topic stored yet — `setNotificationToken()` has not completed successfully. Or Firebase Messaging is not in your app. |
| Broadcasts never arrive | The device never registered. Check `setNotificationToken()` was called with a real APNs/FCM token and the registry call succeeded. |
| Broadcasts arrive only after a restart | Firebase was not live when the token registered, so the topic was stored but the subscribe failed. Move `Firebase.initializeApp()` earlier, or call `initializePush()` once Firebase is ready. |
| Notifications stop after a "disable" | `disablePush()` only lasts the session. Use `clearNotificationToken()`. |
| Wrong app receives a campaign | The device is still on the legacy shared topic — dropped on the next successful registration against a current native SDK. |

## Deep Link Streams

Use `deepLinkStream` for backend-enriched deep link data and `universalLinkStream` for raw universal/app link capture events.

```dart
final subscription = Linkzly.instance.deepLinkStream.listen((data) {
  print(data.path);
});
```

## Notes

The Flutter SDK does not reimplement attribution logic. Install/open attribution, event queuing, SKAdNetwork conversion updates, ATT/IDFA, affiliate storage, and push-topic reflection are delegated to the native Linkzly SDKs.
