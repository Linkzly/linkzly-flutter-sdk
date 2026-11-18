import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkzly_flutter_sdk/src/event_properties.dart';

class _Thing {}

class _BadKey {
  @override
  String toString() => throw StateError('no string');
}

void main() {
  late List<String> warnings;

  Map<String, Object?> encode(
    Map<String, Object?> properties, {
    String eventName = 'checkout',
  }) => encodeEventProperties(eventName, properties, warn: warnings.add);

  setUp(() => warnings = <String>[]);

  group('dates', () {
    test('a UTC DateTime is sent as ISO 8601 UTC with 3 ms digits and Z', () {
      final DateTime at = DateTime.fromMillisecondsSinceEpoch(
        1761560130123,
        isUtc: true,
      );
      expect(encode(<String, Object?>{'at': at}), <String, Object?>{
        'at': '2025-10-27T10:15:30.123Z',
      });
      expect(warnings, isEmpty);
    });

    test('a local DateTime is sent as the same instant in UTC', () {
      final DateTime at = DateTime.fromMillisecondsSinceEpoch(1761560130123);
      expect(
        encode(<String, Object?>{'at': at})['at'],
        '2025-10-27T10:15:30.123Z',
      );
    });

    test('whole seconds still carry .000', () {
      expect(
        encode(<String, Object?>{
          'at': DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        })['at'],
        '1970-01-01T00:00:00.000Z',
      );
    });

    test('microseconds are cut, not rounded', () {
      final DateTime at = DateTime.fromMicrosecondsSinceEpoch(
        1761560130123999,
        isUtc: true,
      );
      expect(
        encode(<String, Object?>{'at': at})['at'],
        '2025-10-27T10:15:30.123Z',
      );
    });

    test('before the epoch, microseconds are cut toward the earlier ms', () {
      // -456 us is 23:59:59.999544, so the cut value is .999.
      expect(
        encode(<String, Object?>{
          'at': DateTime.fromMicrosecondsSinceEpoch(-456, isUtc: true),
        })['at'],
        '1969-12-31T23:59:59.999Z',
      );
      expect(
        encode(<String, Object?>{
          'at': DateTime.fromMicrosecondsSinceEpoch(-1000456, isUtc: true),
        })['at'],
        '1969-12-31T23:59:58.999Z',
      );
    });
  });

  group('top-level values that cannot be sent', () {
    for (final MapEntry<String, double> entry in <String, double>{
      'NaN': double.nan,
      'Infinity': double.infinity,
      '-Infinity': double.negativeInfinity,
    }.entries) {
      test('${entry.key} is dropped with one warning, the rest is sent', () {
        final Map<String, Object?> out = encode(<String, Object?>{
          'price': entry.value,
          'keep': 'yes',
        });
        expect(out, <String, Object?>{'keep': 'yes'});
        expect(warnings, hasLength(1));
        expect(warnings.single, contains('checkout'));
        expect(warnings.single, contains('price'));
      });
    }

    test('an unsupported object is dropped with one warning', () {
      final Map<String, Object?> out = encode(<String, Object?>{
        'thing': _Thing(),
        'keep': 'yes',
      });
      expect(out, <String, Object?>{'keep': 'yes'});
      expect(warnings, hasLength(1));
      expect(warnings.single, contains('thing'));
    });

    test('binary data (typed lists) is unsupported', () {
      final Map<String, Object?> out = encode(<String, Object?>{
        'bytes': Uint8List.fromList(<int>[1, 2]),
        'floats': Float32List.fromList(<double>[0.1]),
        'keep': 'yes',
      });
      expect(out, <String, Object?>{'keep': 'yes'});
      expect(warnings, hasLength(2));
    });

    test('a BigInt, a Set and a Duration are unsupported', () {
      final Map<String, Object?> out = encode(<String, Object?>{
        'big': BigInt.parse('12345678901234567890'),
        'set': <int>{1},
        'span': const Duration(seconds: 1),
      });
      expect(out, isEmpty);
      expect(warnings, hasLength(3));
    });

    test('a value that throws while being read is dropped, never thrown', () {
      final Map<String, Object?> out = encode(<String, Object?>{
        'nested': <Object?, Object?>{_BadKey(): 1},
        'keep': 'yes',
      });
      expect(out, <String, Object?>{'keep': 'yes'});
      expect(warnings, hasLength(1));
      expect(warnings.single, contains('nested'));
    });
  });

  group('null', () {
    test('a top-level null leaves the key out, with no warning', () {
      expect(
        encode(<String, Object?>{'gone': null, 'keep': 'yes'}),
        <String, Object?>{'keep': 'yes'},
      );
      expect(warnings, isEmpty);
    });

    test('a nested null stays null', () {
      expect(
        encode(<String, Object?>{
          'list': <Object?>['a', null],
          'map': <String, Object?>{'v': null},
        }),
        <String, Object?>{
          'list': <Object?>['a', null],
          'map': <String, Object?>{'v': null},
        },
      );
      expect(warnings, isEmpty);
    });
  });

  group('lists and maps', () {
    test(
      'values inside follow the same rules; unsendable ones become null',
      () {
        final Map<String, Object?> out = encode(<String, Object?>{
          'list': <Object?>[
            1,
            double.nan,
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            _Thing(),
          ],
          'map': <String, Object?>{
            'inf': double.infinity,
            'at': DateTime.fromMillisecondsSinceEpoch(
              1761560130123,
              isUtc: true,
            ),
            'deep': <String, Object?>{'b': '007', 'bytes': Uint8List(1)},
          },
        });
        expect(out, <String, Object?>{
          'list': <Object?>[1, null, '1970-01-01T00:00:00.000Z', null],
          'map': <String, Object?>{
            'inf': null,
            'at': '2025-10-27T10:15:30.123Z',
            'deep': <String, Object?>{'b': '007', 'bytes': null},
          },
        });
        // Only top-level drops warn.
        expect(warnings, isEmpty);
      },
    );

    test('nested map keys that are not text are sent as text', () {
      expect(
        encode(<String, Object?>{
          'map': <Object?, Object?>{1: 'a', true: 'b'},
        }),
        <String, Object?>{
          'map': <String, Object?>{'1': 'a', 'true': 'b'},
        },
      );
    });

    test('a list that contains itself does not loop forever', () {
      final List<Object?> loop = <Object?>[1];
      loop.add(loop);
      expect(encode(<String, Object?>{'loop': loop}), <String, Object?>{
        'loop': <Object?>[1, null],
      });
    });

    test('the app\'s map is not changed', () {
      final Map<String, Object?> input = <String, Object?>{
        'at': DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        'gone': null,
      };
      encode(input);
      expect(input.keys, <String>['at', 'gone']);
      expect(input['at'], isA<DateTime>());
    });
  });

  group('plain values pass through', () {
    test('text, numbers and booleans keep their JSON type', () {
      final Map<String, Object?> input = <String, Object?>{
        'text': '007',
        'empty': '',
        'int': 7,
        'zero': 0,
        'one': 1,
        'double': 9.99,
        'whole': 7.0,
        'big': 9007199254740991,
        'yes': true,
        'no': false,
      };
      final Map<String, Object?> out = encode(input);
      expect(out, input);
      expect(out['zero'], isA<int>());
      expect(out['one'], isA<int>());
      expect(out['yes'], isA<bool>());
      expect(warnings, isEmpty);
    });
  });

  group('reserved names', () {
    test('a __ key warns and is still sent', () {
      expect(encode(<String, Object?>{'__mine': 'x'}), <String, Object?>{
        '__mine': 'x',
      });
      expect(warnings, hasLength(1));
      expect(warnings.single, contains('__mine'));
      expect(warnings.single, contains('checkout'));
    });

    test('Linkzly\'s own keys warn and are still sent', () {
      final Map<String, Object?> input = <String, Object?>{
        'bot_score': 1,
        'device_data': <String, Object?>{'a': 1},
        'traffic_channel': 'x',
      };
      expect(encode(input), input);
      expect(warnings, hasLength(3));
    });

    test('a reserved key whose value is dropped warns once', () {
      expect(encode(<String, Object?>{'__x': double.nan}), isEmpty);
      expect(warnings, hasLength(1));
    });
  });

  test('the output always passes the message codec and JSON', () {
    final Map<String, Object?> out = encode(<String, Object?>{
      'at': DateTime.now(),
      'nan': double.nan,
      'thing': _Thing(),
      'list': <Object?>[DateTime.now(), double.infinity, _Thing()],
      'map': <Object?, Object?>{1: DateTime.now()},
    });
    expect(
      () => const StandardMethodCodec().encodeMethodCall(
        MethodCall('trackEvent', <String, Object?>{'parameters': out}),
      ),
      returnsNormally,
    );
    expect(() => jsonEncode(out), returnsNormally);
  });
}
