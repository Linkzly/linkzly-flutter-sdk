import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkzly_flutter_sdk/src/linkzly_method_channel.dart';
import 'package:linkzly_flutter_sdk/src/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(methodChannelName);
  final LinkzlyMethodChannel sdk = LinkzlyMethodChannel(
    methodChannel: channel,
  );

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('configure passes sdk key and environment to native channel', () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      capturedCall = call;
      return <String, Object?>{'success': true};
    });

    await sdk.configure(
      const LinkzlyConfig(
        sdkKey: 'slk_0000000000000000000000000000000000000000',
        environment: LinkzlyEnvironment.staging,
      ),
    );

    expect(capturedCall?.method, 'configure');
    expect(capturedCall?.arguments, <String, Object?>{
      'sdkKey': 'slk_0000000000000000000000000000000000000000',
      'environment': 1,
    });
  });

  test('trackInstall maps deep link payload', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      return <String, Object?>{
        'url': 'https://example.linkzly.com/product?cid=c1',
        'path': '/product',
        'smartLinkId': 's1',
        'clickId': 'c1',
        'parameters': <String, Object?>{'sku': 'abc'},
      };
    });

    final DeepLinkData? data = await sdk.trackInstall();

    expect(data?.path, '/product');
    expect(data?.smartLinkId, 's1');
    expect(data?.clickId, 'c1');
    expect(data?.parameters['sku'], 'abc');
  });

  test('trackPurchase extracts success response', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      return <String, Object?>{'success': true};
    });

    expect(await sdk.trackPurchase(<String, Object?>{'amount': 10}), isTrue);
  });

  test('affiliate attribution handles nullable fields', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      return <String, Object?>{
        'clickId': null,
        'programId': null,
        'affiliateId': null,
        'timestamp': null,
        'hasAttribution': false,
        'source': 'none',
      };
    });

    final AffiliateAttribution attribution =
        await sdk.getAffiliateAttribution();

    expect(attribution.hasAttribution, isFalse);
    expect(attribution.source, 'none');
  });

  group('event properties cross the message codec', () {
    late List<String?> logs;
    late DebugPrintCallback originalDebugPrint;

    setUp(() {
      logs = <String?>[];
      originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => logs.add(message);
    });

    tearDown(() => debugPrint = originalDebugPrint);

    final DateTime at =
        DateTime.fromMicrosecondsSinceEpoch(1761560130123456, isUtc: true);

    test('trackEvent sends a DateTime as ISO text and drops NaN', () async {
      MethodCall? capturedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        capturedCall = call;
        return <String, Object?>{'success': true};
      });

      await sdk.trackEvent('checkout', <String, Object?>{
        'at': at,
        'price': double.nan,
        'gone': null,
        'items': <Object?>[at, null, double.infinity],
        'keep': 'yes',
      });

      expect(capturedCall?.method, 'trackEvent');
      expect(capturedCall?.arguments, <String, Object?>{
        'eventName': 'checkout',
        'parameters': <String, Object?>{
          'at': '2025-10-27T10:15:30.123Z',
          'items': <Object?>['2025-10-27T10:15:30.123Z', null, null],
          'keep': 'yes',
        },
      });
      expect(logs, hasLength(1));
      expect(logs.single, contains('checkout'));
      expect(logs.single, contains('price'));
    });

    test('trackEventBatch converts each event and still sends them all',
        () async {
      MethodCall? capturedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        capturedCall = call;
        return <String, Object?>{'success': true};
      });

      final bool ok = await sdk.trackEventBatch(<BatchEvent>[
        BatchEvent('first', parameters: <String, Object?>{'at': at}),
        const BatchEvent('second',
            parameters: <String, Object?>{'n': double.infinity, 'k': 1}),
      ]);

      expect(ok, isTrue);
      expect(capturedCall?.arguments, <String, Object?>{
        'events': <Object?>[
          <String, Object?>{
            'eventName': 'first',
            'parameters': <String, Object?>{'at': '2025-10-27T10:15:30.123Z'},
          },
          <String, Object?>{
            'eventName': 'second',
            'parameters': <String, Object?>{'k': 1},
          },
        ],
      });
      expect(logs, hasLength(1));
      expect(logs.single, contains('second'));
      expect(logs.single, contains('n'));
    });
  });
}
