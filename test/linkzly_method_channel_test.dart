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
}
