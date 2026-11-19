import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkzly_flutter_sdk/linkzly_flutter_sdk.dart';
import 'package:linkzly_flutter_sdk/src/linkzly_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(methodChannelName);

  void mockChannel(Future<Object?>? Function(MethodCall call)? handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  tearDown(() => mockChannel(null));

  group('trackNotificationOpen', () {
    test(
      'a campaign data map reaches the channel with its keys unchanged',
      () async {
        MethodCall? captured;
        mockChannel((MethodCall call) async {
          captured = call;
          return null;
        });

        await Linkzly.instance.trackNotificationOpen(<String, dynamic>{
          'campaign_id': '6b741e20-0000-0000-0000-000000000000',
          'flow_id': 'flow-1',
          'flow_delivery_id': 'delivery-1',
          'screen': 'offers',
        });

        expect(captured?.method, 'trackNotificationOpen');
        expect(captured?.arguments, <String, Object?>{
          'data': <String, Object?>{
            'campaign_id': '6b741e20-0000-0000-0000-000000000000',
            'flow_id': 'flow-1',
            'flow_delivery_id': 'delivery-1',
            'screen': 'offers',
          },
          'actionId': null,
        });
      },
    );

    test('the future completes with nothing', () async {
      mockChannel(
        (MethodCall call) async => <String, Object?>{'success': true},
      );

      final Future<void> future = Linkzly.instance.trackNotificationOpen(
        <String, dynamic>{'campaign_id': 'c1'},
      );

      await expectLater(future, completion(isNull));
    });

    test(
      'a PlatformException from the channel still completes normally',
      () async {
        mockChannel((MethodCall call) async {
          throw PlatformException(code: 'BOOM', message: 'native side failed');
        });

        await expectLater(
          Linkzly.instance.trackNotificationOpen(<String, dynamic>{
            'campaign_id': 'c1',
          }),
          completes,
        );
      },
    );

    test('a MissingPluginException still completes normally', () async {
      // No handler: the channel has no implementation behind it.
      mockChannel(null);

      await expectLater(
        Linkzly.instance.trackNotificationOpen(<String, dynamic>{
          'campaign_id': 'c1',
        }),
        completes,
      );
    });

    test(
      'a handler that throws something else still completes normally',
      () async {
        mockChannel((MethodCall call) async => throw StateError('unexpected'));

        await expectLater(
          Linkzly.instance.trackNotificationOpen(<String, dynamic>{
            'campaign_id': 'c1',
          }),
          completes,
        );
      },
    );

    test('no action id, an empty one and a real one', () async {
      final List<Object?> sent = <Object?>[];
      mockChannel((MethodCall call) async {
        sent.add((call.arguments as Map<Object?, Object?>)['actionId']);
        return null;
      });
      final Map<String, dynamic> data = <String, dynamic>{'campaign_id': 'c1'};

      await Linkzly.instance.trackNotificationOpen(data);
      await Linkzly.instance.trackNotificationOpen(data, actionId: null);
      await Linkzly.instance.trackNotificationOpen(data, actionId: '');
      await Linkzly.instance.trackNotificationOpen(data, actionId: 'reply');
      await Linkzly.instance.trackNotificationOpen(data, actionId: 'default');

      // Null and empty reach native as null, never as a word such as "default".
      // A string the app chose passes through as it is.
      expect(sent, <Object?>[null, null, null, 'reply', 'default']);
    });

    test(
      'values that are not strings are left out and do not break the call',
      () async {
        MethodCall? captured;
        mockChannel((MethodCall call) async {
          captured = call;
          return null;
        });

        await Linkzly.instance.trackNotificationOpen(<String, dynamic>{
          'campaign_id': 'c1',
          'count': 3,
          'ratio': 0.5,
          'flag': true,
          'nothing': null,
          'list': <Object?>['a', 1],
          'nested': <String, Object?>{'k': 'v'},
          'when': DateTime.utc(2026, 11, 19),
          'nan': double.nan,
          'flow_delivery_id': 'd1',
        });

        expect(captured?.arguments, <String, Object?>{
          'data': <String, Object?>{
            'campaign_id': 'c1',
            'flow_delivery_id': 'd1',
          },
          'actionId': null,
        });
      },
    );

    test('an empty data map is sent as an empty map', () async {
      MethodCall? captured;
      mockChannel((MethodCall call) async {
        captured = call;
        return null;
      });

      await Linkzly.instance.trackNotificationOpen(<String, dynamic>{});

      expect(captured?.arguments, <String, Object?>{
        'data': <String, Object?>{},
        'actionId': null,
      });
    });
  });
}
