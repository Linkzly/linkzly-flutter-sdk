import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkzly_flutter_sdk/linkzly_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('linkzly_flutter_sdk/methods');
  final Linkzly sdk = Linkzly.instance;
  final List<MethodCall> calls = <MethodCall>[];

  void answerWith(Object? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(calls.clear);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('setConsent', () {
    test('only set fields cross the channel as strings', () async {
      answerWith((_) => <String, Object?>{'success': true});

      await sdk.setConsent(adUserData: ConsentState.denied);

      expect(calls, hasLength(1));
      expect(calls.single.method, 'setConsent');
      expect(calls.single.arguments, <String, Object?>{'adUserData': 'denied'});
    });

    test('all three states cross the channel as their plain words', () async {
      answerWith((_) => <String, Object?>{'success': true});

      await sdk.setConsent(
        analytics: ConsentState.granted,
        adUserData: ConsentState.denied,
        adPersonalization: ConsentState.unspecified,
      );

      expect(calls.single.arguments, <String, Object?>{
        'analytics': 'granted',
        'adUserData': 'denied',
        'adPersonalization': 'unspecified',
      });
    });

    test('a call with no field does not reach the channel', () async {
      answerWith((_) => <String, Object?>{'success': true});

      await sdk.setConsent();

      expect(calls, isEmpty);
    });

    test('an INVALID_CONSENT answer from the platform reaches the caller',
        () async {
      answerWith((_) => throw PlatformException(
            code: 'INVALID_CONSENT',
            message: 'analytics must be granted, denied or unspecified',
          ));

      await expectLater(
        sdk.setConsent(analytics: ConsentState.denied),
        throwsA(isA<PlatformException>()
            .having((PlatformException e) => e.code, 'code', 'INVALID_CONSENT')),
      );
    });

    test('setTrackingEnabled(false) sends only its own call', () async {
      answerWith((_) => <String, Object?>{'success': true});

      await sdk.setTrackingEnabled(false);

      expect(calls.map((MethodCall c) => c.method), <String>['setTrackingEnabled']);
      expect(calls.single.arguments, <String, Object?>{'enabled': false});
    });
  });

  group('getConsent', () {
    test('returns what the platform returns', () async {
      // Fixed clock: 2026-11-12T12:00:00Z in epoch milliseconds.
      final int capturedAt = DateTime.utc(2026, 11, 12, 12).millisecondsSinceEpoch;
      answerWith((_) => <Object?, Object?>{
            'analytics': 'denied',
            'adUserData': 'granted',
            'capturedAt': capturedAt,
          });

      final ConsentSettings? consent = await sdk.getConsent();

      expect(calls.single.method, 'getConsent');
      expect(consent?.analytics, ConsentState.denied);
      expect(consent?.adUserData, ConsentState.granted);
      expect(consent?.adPersonalization, isNull);
      expect(consent?.capturedAt, DateTime.utc(2026, 11, 12, 12));
    });

    test('has no capturedAt when the platform sends none', () async {
      answerWith((_) => <Object?, Object?>{'adPersonalization': 'unspecified'});

      final ConsentSettings? consent = await sdk.getConsent();

      expect(consent?.adPersonalization, ConsentState.unspecified);
      expect(consent?.capturedAt, isNull);
    });

    test('returns null before the first setConsent', () async {
      answerWith((_) => null);

      expect(await sdk.getConsent(), isNull);
    });
  });
}
