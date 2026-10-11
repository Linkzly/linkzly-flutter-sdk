<!-- Generated from https://docs.linkzly.com/docs/sdk-flutter and the linkzly-mobile-sdk skill by linkzly-document/scripts/build-agent-kit.mjs. Do not edit: change the docs page or the skill and regenerate. -->
# Linkzly Flutter SDK: notes for AI agents

This repository is the published Linkzly SDK for Flutter. If you are an AI coding agent adding it to someone's app, read this before you write code.

**SDK version:** 1.0.6

## Install

Use this exactly as it is written. The README's Installation section has the full steps and the other install forms. On iOS the app also needs the `LinkzlySDK` pod pinned to its Git source and tag in `ios/Podfile`, or `pod install` fails; the exact lines are in the README's Installation section.

```yaml
dependencies:
  linkzly_flutter_sdk: ^1.0.6
```

## Rules

- **Ask the person for the SDK key and use the one they give you. Never make one up.** Help with every step, including the ones done in the Linkzly console: say where to go, and carry on when you have the value. If code has to compile before the key arrives, write the placeholder `slk_your_key_from_console`, and when you finish say which file holds it and ask for the key again. The same holds for any other value that only the console or another account can supply.
- **Once `configure()` has run, the SDK sends the install and the opens itself.** Do not add `trackInstall` or `trackOpen`: each call sends one more event. The one exception is on Android, in a native, React Native or Flutter app: if the app has to read deferred deep link data in code, an explicit `trackInstall`, called once behind a first-launch flag, is the only way. It sends a second install event, so tell the person before you add it.
- **Every custom event name must be registered for the app in the Linkzly console.** An event with an unregistered name is dropped while the call still reports success. List the names you used so the person can register them.
- **Purchases go only through `trackPurchase`,** with `revenue`, `currency` and `transactionId`. A refund is `trackRefund` with the purchase's `transactionId`. Never send revenue as a custom event. Purchases are recorded only when Revenue & LTV is enabled for the person's organisation.
- **Push tokens are Firebase tokens on every platform.** On iOS pass the Firebase Cloud Messaging registration token, never the APNs device token, which cannot receive a Linkzly push. Call `setNotificationToken` after `configure` and again whenever the token refreshes.
- **`setTrackingEnabled(false)` stops custom events, purchases and refunds only.** Install, open and session-end events are still sent, and on iOS so are `trackEventBatch` calls. An app that must send nothing before consent delays `configure`.
- **Use the install lines exactly as the Linkzly docs write them, version included.** React Native installs from a GitHub tag, not from npm. If the iOS SDK is added with CocoaPods, the pod needs its Git source and tag. Flutter's install line is the `pubspec.yaml` entry with its version, and it needs the pod pin in `ios/Podfile`.
- **The debug controls that change the batching strategy, batch size and flush interval do not work on iOS,** in a native, React Native or Flutter app alike: the published iOS SDK does not include them. Do not use them to test or confirm anything on iOS. `flushEvents` and `getPendingEventCount` are not among them and do work on iOS.

## Where the full instructions are

- The Linkzly skill, with the order of work and one reference file per topic: `npx skills add Linkzly/skills`
- This SDK's page: https://docs.linkzly.com/docs/sdk-flutter (as markdown: https://docs.linkzly.com/docs/sdk-flutter.md)
- Guides, as markdown: https://docs.linkzly.com/docs/sdk-tracking-events.md, https://docs.linkzly.com/docs/sdk-tracking-purchases.md, https://docs.linkzly.com/docs/sdk-integrations-setup.md
- Every page, listed for agents: https://docs.linkzly.com/llms.txt
