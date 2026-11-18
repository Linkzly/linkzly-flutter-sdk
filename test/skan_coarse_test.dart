import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkzly_flutter_sdk/linkzly_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('linkzly_flutter_sdk/methods');
  final Linkzly sdk = Linkzly.instance;
  final List<MethodCall> calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call);
      return <String, Object?>{'success': true};
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('value only sends exactly the value, as before', () async {
    expect(await sdk.updateConversionValue(12), isTrue);

    expect(calls.single.method, 'updateConversionValue');
    expect(calls.single.arguments, <String, Object?>{'value': 12});
  });

  test('value + coarse + lock passes all three', () async {
    expect(
      await sdk.updateConversionValue(40, coarseValue: 'high', lockWindow: true),
      isTrue,
    );

    expect(calls.single.arguments, <String, Object?>{
      'value': 40,
      'coarseValue': 'high',
      'lockWindow': true,
    });
  });

  test('value + coarse without lock sends lock as false', () async {
    await sdk.updateConversionValue(7, coarseValue: 'low');

    expect(calls.single.arguments, <String, Object?>{
      'value': 7,
      'coarseValue': 'low',
      'lockWindow': false,
    });
  });

  test('an unknown coarse word is dropped', () async {
    await sdk.updateConversionValue(5, coarseValue: 'huge', lockWindow: true);
    await sdk.updateConversionValue(6, coarseValue: 'HIGH');

    expect(calls.map((MethodCall c) => c.arguments), <Object?>[
      <String, Object?>{'value': 5},
      <String, Object?>{'value': 6},
    ]);
  });

  test('lock without coarse is dropped', () async {
    await sdk.updateConversionValue(9, lockWindow: true);

    expect(calls.single.arguments, <String, Object?>{'value': 9});
  });
}
