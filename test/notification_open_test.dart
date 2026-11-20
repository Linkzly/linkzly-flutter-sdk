import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  group('trackNotificationOpen finds the push data in what a tap handler was given', () {
    const Map<String, String> linkzly = <String, String>{
      'campaign_id': 'c1',
      'template_id': 't1',
      'locale': 'en',
    };

    Future<Object?> sent(Object? input) async {
      Object? data = 'not called';
      mockChannel((MethodCall call) async {
        data = (call.arguments as Map<Object?, Object?>)['data'];
        return null;
      });
      await Linkzly.instance.trackNotificationOpen(input);
      return data;
    }

    test('a firebase_messaging RemoteMessage map: data one level down', () async {
      expect(
        await sent(<String, Object?>{
          'messageId': 'm1',
          'notification': <String, Object?>{'title': 'Hi'},
          'data': linkzly,
        }),
        linkzly,
      );
    });

    test('a flutter_local_notifications payload: a JSON string', () async {
      expect(await sent(jsonEncode(linkzly)), linkzly);
      expect(
        await sent(<String, Object?>{'id': 1, 'payload': jsonEncode(linkzly)}),
        linkzly,
      );
    });

    test('keys two levels down, under notification then data', () async {
      expect(
        await sent(<String, Object?>{
          'notification': <String, Object?>{'id': 'n1', 'data': linkzly},
        }),
        linkzly,
      );
    });

    test('a map whose keys are not typed as strings is read too', () async {
      expect(
        await sent(<Object?, Object?>{'data': <Object?, Object?>{...linkzly}}),
        linkzly,
      );
    });

    test('a triggered push: flow fields come from the map that holds the delivery',
        () async {
      const Map<String, String> flow = <String, String>{
        'flow_id': 'flow-1',
        'flow_delivery_id': 'delivery-1',
      };
      expect(
        await sent(<String, Object?>{'flow_id': 'other', 'userInfo': flow}),
        flow,
      );
    });

    test('keys at the top win over keys further down', () async {
      expect(
        await sent(<String, Object?>{
          'campaign_id': 'top',
          'data': <String, Object?>{'campaign_id': 'nested'},
        }),
        <String, String>{'campaign_id': 'top'},
      );
    });

    test('data three levels down, or under other keys, is not looked for',
        () async {
      expect(
        await sent(<String, Object?>{
          'data': <String, Object?>{
            'data': <String, Object?>{'data': linkzly},
          },
        }),
        <String, String>{},
      );
      expect(
        await sent(<String, Object?>{'extras': linkzly}),
        <String, String>{},
      );
    });

    test('without Linkzly keys anywhere, the given map is sent as before',
        () async {
      expect(
        await sent(<String, Object?>{
          'type': 'chat',
          'data': <String, Object?>{'x': 'y'},
        }),
        <String, String>{'type': 'chat'},
      );
    });

    test('keys that are not strings are left out and never hashed', () async {
      final Map<Object?, Object?> odd = Map<Object?, Object?>.identity()
        ..[_Hostile()] = 'x'
        ..['campaign_id'] = 'c1';
      expect(await sent(odd), <String, String>{'campaign_id': 'c1'});
    });

    test('a nested map that throws when read is skipped', () async {
      expect(
        await sent(<String, Object?>{
          'type': 'chat',
          'data': _ThrowingMap(),
          'payload': jsonEncode(<String, String>{'campaign_id': 'c2'}),
        }),
        <String, String>{'campaign_id': 'c2'},
      );
      expect(
        await sent(<String, Object?>{'type': 'chat', 'data': _ThrowingMap()}),
        <String, String>{'type': 'chat'},
      );
    });

    test('a debugPrint that throws does not escape', () async {
      final DebugPrintCallback original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) =>
          throw StateError('app logger');
      addTearDown(() => debugPrint = original);
      mockChannel((MethodCall call) async {
        throw PlatformException(code: 'BOOM');
      });
      await expectLater(
        Linkzly.instance.trackNotificationOpen(<String, Object?>{
          'campaign_id': 'c1',
        }),
        completes,
      );
    });

    test('a fake that implements Linkzly with the earlier signature compiles',
        () async {
      final Linkzly fake = _OldSignatureFake();
      await fake.trackNotificationOpen(<String, dynamic>{'campaign_id': 'c1'});
      expect((fake as _OldSignatureFake).calls, 1);
    });

    test('anything that is not a map, or a JSON string of one, does nothing',
        () async {
      for (final Object? input in <Object?>[
        null,
        'not json',
        '[1, 2]',
        '{broken',
        42,
        <Object?>['a'],
      ]) {
        expect(await sent(input), 'not called');
      }
    });
  });

  group('trackNotificationOpen before configure', () {
    test('is passed to the channel once and not sent again by configure',
        () async {
      final List<MethodCall> calls = <MethodCall>[];
      mockChannel((MethodCall call) async {
        calls.add(call);
        return null;
      });
      final LinkzlyMethodChannel sdk = LinkzlyMethodChannel(
        methodChannel: channel,
      );
      Iterable<MethodCall> taps() => calls
          .where((MethodCall call) => call.method == 'trackNotificationOpen');
      await sdk.trackNotificationOpen(<String, Object?>{'campaign_id': 'c1'});
      expect(taps(), hasLength(1));
      await sdk.configure(const LinkzlyConfig(sdkKey: 'slk_test'));
      expect(taps(), hasLength(1));
    });
  });
}

/// An object whose hashCode and toString throw, like a broken app type.
class _Hostile {
  @override
  int get hashCode => throw StateError('hashCode');

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  String toString() => throw StateError('toString');
}

/// An app's test fake written against the earlier `Map<String, dynamic>`
/// parameter.
class _OldSignatureFake implements Linkzly {
  int calls = 0;

  @override
  Future<void> trackNotificationOpen(
    Map<String, dynamic> data, {
    String? actionId,
  }) async {
    calls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A map that throws when its entries are read, like a broken app type.
class _ThrowingMap extends MapBase<Object?, Object?> {
  @override
  Object? operator [](Object? key) => throw _Hostile();

  @override
  void operator []=(Object? key, Object? value) {}

  @override
  void clear() {}

  @override
  Iterable<Object?> get keys => throw _Hostile();

  @override
  Object? remove(Object? key) => null;
}
