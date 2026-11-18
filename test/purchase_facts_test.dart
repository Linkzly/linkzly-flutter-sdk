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

  test('the optional purchase keys reach the channel unchanged', () async {
    final Map<String, Object?> purchase = <String, Object?>{
      'revenue': 9.99,
      'currency': 'USD',
      'transactionId': 'txn-0001',
      'environment': 'sandbox',
      'originalTransactionId': 'orig-0001',
      'original_transaction_id': 'orig-0001',
      'isRenewal': true,
      'is_renewal': true,
    };

    expect(await sdk.trackPurchase(Map<String, Object?>.of(purchase)), isTrue);

    expect(calls.single.method, 'trackPurchase');
    expect(calls.single.arguments, <String, Object?>{'parameters': purchase});
  });

  test('the optional refund keys reach the channel unchanged', () async {
    final Map<String, Object?> refund = <String, Object?>{
      'revenue': 9.99,
      'currency': 'USD',
      'transactionId': 'txn-0001',
      'refundId': 'refund-0001',
      'refund_id': 'refund-0001',
    };

    expect(await sdk.trackRefund(Map<String, Object?>.of(refund)), isTrue);

    expect(calls.single.method, 'trackRefund');
    expect(calls.single.arguments, <String, Object?>{'parameters': refund});
  });

  test('a purchase with none of the new keys sends the same map as before',
      () async {
    await sdk.trackPurchase(<String, Object?>{'revenue': 1, 'currency': 'EUR'});
    await sdk.trackPurchase();

    expect(calls.map((MethodCall c) => c.arguments), <Object?>[
      <String, Object?>{
        'parameters': <String, Object?>{'revenue': 1, 'currency': 'EUR'},
      },
      <String, Object?>{'parameters': <String, Object?>{}},
    ]);
  });
}
