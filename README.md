# Linkzly Flutter SDK

Flutter bridge for Linkzly deep linking, deferred attribution, event tracking, affiliate attribution, and mobile measurement.

## Requirements

- Flutter 3.38+
- Dart 3.10+
- iOS 13+
- Android API 21+

## Installation

### 1. Add the Flutter package

The Flutter SDK is distributed via GitHub (it is not yet published to pub.dev). Pin to a tag in your app's `pubspec.yaml`:

```yaml
dependencies:
  linkzly_flutter_sdk:
    git:
      url: https://github.com/linkzly/linkzly-flutter-sdk.git
      ref: v0.1.0
```

Then run `flutter pub get`.

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

#### 3a. Configure Android App Links

Add an intent filter to the activity that launches your Flutter app, usually `android/app/src/main/AndroidManifest.xml`:

```xml
<activity
  android:name=".MainActivity"
  android:exported="true"
  android:launchMode="singleTop">

  <intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="your-linkzly-domain.example" />
  </intent-filter>
</activity>
```

Replace `your-linkzly-domain.example` with the host you configured in the Linkzly Console for this app.

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
- `initializePush` / `disablePush`
- affiliate attribution helpers
- gaming tracking helpers
- debug batching helpers

## Deep Link Streams

Use `deepLinkStream` for backend-enriched deep link data and `universalLinkStream` for raw universal/app link capture events.

```dart
final subscription = Linkzly.instance.deepLinkStream.listen((data) {
  print(data.path);
});
```

## Notes

The Flutter SDK does not reimplement attribution logic. Install/open attribution, event queuing, SKAdNetwork conversion updates, ATT/IDFA, affiliate storage, and push-topic reflection are delegated to the native Linkzly SDKs.
