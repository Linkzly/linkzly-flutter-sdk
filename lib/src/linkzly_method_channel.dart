import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models.dart';

@visibleForTesting
const String methodChannelName = 'linkzly_flutter_sdk/methods';
@visibleForTesting
const String deepLinkEventChannelName = 'linkzly_flutter_sdk/deep_links';
@visibleForTesting
const String universalLinkEventChannelName =
    'linkzly_flutter_sdk/universal_links';

class LinkzlyMethodChannel {
  LinkzlyMethodChannel({
    MethodChannel? methodChannel,
    EventChannel? deepLinkEventChannel,
    EventChannel? universalLinkEventChannel,
  })  : _methodChannel =
            methodChannel ?? const MethodChannel(methodChannelName),
        _deepLinkEventChannel =
            deepLinkEventChannel ?? const EventChannel(deepLinkEventChannelName),
        _universalLinkEventChannel = universalLinkEventChannel ??
            const EventChannel(universalLinkEventChannelName);

  final MethodChannel _methodChannel;
  final EventChannel _deepLinkEventChannel;
  final EventChannel _universalLinkEventChannel;

  Stream<DeepLinkData> get deepLinkStream =>
      _deepLinkEventChannel.receiveBroadcastStream().map(
            (Object? event) => DeepLinkData.fromMap(_requireMap(event)),
          );

  Stream<UniversalLinkEvent> get universalLinkStream =>
      _universalLinkEventChannel.receiveBroadcastStream().map(
            (Object? event) => UniversalLinkEvent.fromMap(_requireMap(event)),
          );

  Future<void> configure(LinkzlyConfig config) async {
    await _methodChannel.invokeMapMethod<String, Object?>(
      'configure',
      config.toMap(),
    );
  }

  Future<DeepLinkData?> handleUniversalLink(String url) async {
    final Object? result = await _methodChannel.invokeMethod<Object?>(
      'handleUniversalLink',
      <String, Object?>{'url': url},
    );
    return _deepLinkOrNull(result);
  }

  Future<DeepLinkData?> trackInstall() async {
    final Object? result = await _methodChannel.invokeMethod<Object?>(
      'trackInstall',
    );
    return _deepLinkOrNull(result);
  }

  Future<DeepLinkData?> trackOpen() async {
    final Object? result = await _methodChannel.invokeMethod<Object?>(
      'trackOpen',
    );
    return _deepLinkOrNull(result);
  }

  Future<void> trackEvent(
    String eventName,
    Map<String, Object?> parameters,
  ) async {
    await _methodChannel.invokeMapMethod<String, Object?>(
      'trackEvent',
      <String, Object?>{
        'eventName': eventName,
        'parameters': parameters,
      },
    );
  }

  Future<bool> trackPurchase(Map<String, Object?> parameters) async {
    final Map<Object?, Object?>? result =
        await _methodChannel.invokeMapMethod<Object?, Object?>(
      'trackPurchase',
      <String, Object?>{'parameters': parameters},
    );
    return _success(result);
  }

  Future<bool> trackEventBatch(List<BatchEvent> events) async {
    final Map<Object?, Object?>? result =
        await _methodChannel.invokeMapMethod<Object?, Object?>(
      'trackEventBatch',
      <String, Object?>{
        'events': events.map((BatchEvent event) => event.toMap()).toList(),
      },
    );
    return _success(result);
  }

  Future<bool> flushEvents() async {
    final Map<Object?, Object?>? result =
        await _methodChannel.invokeMapMethod<Object?, Object?>('flushEvents');
    return _success(result);
  }

  Future<int> getPendingEventCount() async {
    final int? count = await _methodChannel.invokeMethod<int>(
      'getPendingEventCount',
    );
    return count ?? 0;
  }

  Future<void> setUserId(String userId) async {
    await _methodChannel.invokeMapMethod<String, Object?>(
      'setUserID',
      <String, Object?>{'userID': userId},
    );
  }

  Future<String?> getUserId() => _methodChannel.invokeMethod<String>(
        'getUserID',
      );

  Future<void> setTrackingEnabled(bool enabled) async {
    await _methodChannel.invokeMapMethod<String, Object?>(
      'setTrackingEnabled',
      <String, Object?>{'enabled': enabled},
    );
  }

  Future<bool> isTrackingEnabled() async =>
      await _methodChannel.invokeMethod<bool>('isTrackingEnabled') ?? true;

  Future<String> getVisitorId() async =>
      await _methodChannel.invokeMethod<String>('getVisitorID') ?? '';

  Future<void> resetVisitorId() async {
    await _methodChannel.invokeMapMethod<String, Object?>('resetVisitorID');
  }

  Future<bool> updateConversionValue(int value) async {
    final Map<Object?, Object?>? result =
        await _methodChannel.invokeMapMethod<Object?, Object?>(
      'updateConversionValue',
      <String, Object?>{'value': value},
    );
    return _success(result);
  }

  Future<String?> requestTrackingPermission() =>
      _methodChannel.invokeMethod<String>('requestTrackingPermission');

  Future<void> setAdvertisingTrackingEnabled(bool enabled) async {
    await _methodChannel.invokeMapMethod<String, Object?>(
      'setAdvertisingTrackingEnabled',
      <String, Object?>{'enabled': enabled},
    );
  }

  Future<bool> isAdvertisingTrackingEnabled() async =>
      await _methodChannel.invokeMethod<bool>('isAdvertisingTrackingEnabled') ??
      true;

  Future<String?> getAttStatus() =>
      _methodChannel.invokeMethod<String>('getATTStatus');

  Future<String?> getIdfa() => _methodChannel.invokeMethod<String>('getIDFA');

  Future<bool> initializePush() async =>
      await _methodChannel.invokeMethod<bool>('initializePush') ?? false;

  Future<bool> disablePush() async =>
      await _methodChannel.invokeMethod<bool>('disablePush') ?? false;

  Future<bool> captureAffiliateAttribution(String url) async =>
      await _methodChannel.invokeMethod<bool>(
        'captureAffiliateAttribution',
        <String, Object?>{'url': url},
      ) ??
      false;

  Future<AffiliateAttribution> getAffiliateAttribution() async {
    final Map<Object?, Object?>? result =
        await _methodChannel.invokeMapMethod<Object?, Object?>(
      'getAffiliateAttribution',
    );
    return AffiliateAttribution.fromMap(result ?? <Object?, Object?>{});
  }

  Future<String?> getAffiliateClickId() =>
      _methodChannel.invokeMethod<String>('getAffiliateClickId');

  Future<bool> hasAffiliateAttribution() async =>
      await _methodChannel.invokeMethod<bool>('hasAffiliateAttribution') ??
      false;

  Future<void> clearAffiliateAttribution() async {
    await _methodChannel.invokeMapMethod<String, Object?>(
      'clearAffiliateAttribution',
    );
  }

  Future<void> configureGamingTracking({
    required String apiKey,
    required String organizationId,
    required String gameId,
    LinkzlyEnvironment environment = LinkzlyEnvironment.production,
    GamingTrackingOptions options = const GamingTrackingOptions(),
  }) async {
    await _methodChannel.invokeMapMethod<String, Object?>(
      'configureGamingTracking',
      <String, Object?>{
        'apiKey': apiKey,
        'organizationId': organizationId,
        'gameId': gameId,
        'environment': environment.nativeValue,
        'options': options.toMap(),
      },
    );
  }

  Future<void> identifyGamingPlayer(
    String playerId, [
    Map<String, Object?> traits = const <String, Object?>{},
  ]) async {
    await _methodChannel.invokeMapMethod<String, Object?>(
      'identifyGamingPlayer',
      <String, Object?>{'playerId': playerId, 'traits': traits},
    );
  }

  Future<void> trackGamingEvent(
    String eventType, {
    Map<String, Object?> data = const <String, Object?>{},
    bool immediate = false,
  }) async {
    await _methodChannel.invokeMapMethod<String, Object?>(
      'trackGamingEvent',
      <String, Object?>{
        'eventType': eventType,
        'data': data,
        'immediate': immediate,
      },
    );
  }

  Future<void> flushGamingEvents() async {
    await _methodChannel.invokeMapMethod<String, Object?>('flushGamingEvents');
  }

  Future<void> startGamingSession() async {
    await _methodChannel.invokeMapMethod<String, Object?>('startGamingSession');
  }

  Future<void> endGamingSession() async {
    await _methodChannel.invokeMapMethod<String, Object?>('endGamingSession');
  }

  Future<void> setGamingAttribution({
    String? clickId,
    String? deferredDeepLink,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    await _methodChannel.invokeMapMethod<String, Object?>(
      'setGamingAttribution',
      <String, Object?>{
        'clickId': clickId,
        'deferredDeepLink': deferredDeepLink,
        'metadata': metadata,
      },
    );
  }

  Future<void> clearGamingAttribution() async {
    await _methodChannel.invokeMapMethod<String, Object?>(
      'clearGamingAttribution',
    );
  }

  Future<void> resetGamingTracking() async {
    await _methodChannel.invokeMapMethod<String, Object?>('resetGamingTracking');
  }

  Future<GamingTrackingStatus> getGamingStatus() async {
    final Map<Object?, Object?>? result =
        await _methodChannel.invokeMapMethod<Object?, Object?>(
      'getGamingStatus',
    );
    return GamingTrackingStatus.fromMap(result ?? <Object?, Object?>{});
  }

  Future<void> debugSetBatchingStrategy(String strategy) async {
    await _methodChannel.invokeMapMethod<String, Object?>(
      'debugSetBatchingStrategy',
      <String, Object?>{'strategy': strategy},
    );
  }

  Future<void> debugSetBatchSize(int size) async {
    await _methodChannel.invokeMapMethod<String, Object?>(
      'debugSetBatchSize',
      <String, Object?>{'size': size},
    );
  }

  Future<void> debugSetFlushInterval(double intervalSeconds) async {
    await _methodChannel.invokeMapMethod<String, Object?>(
      'debugSetFlushInterval',
      <String, Object?>{'interval': intervalSeconds},
    );
  }

  Future<void> debugResetConfig() async {
    await _methodChannel.invokeMapMethod<String, Object?>('debugResetConfig');
  }

  Future<Map<String, Object?>?> debugGetConfig() async {
    final Map<Object?, Object?>? result =
        await _methodChannel.invokeMapMethod<Object?, Object?>(
      'debugGetConfig',
    );
    if (result == null) {
      return null;
    }
    return result.map<String, Object?>(
      (Object? key, Object? value) => MapEntry<String, Object?>('$key', value),
    );
  }

  static DeepLinkData? _deepLinkOrNull(Object? value) {
    if (value == null) {
      return null;
    }
    return DeepLinkData.fromMap(_requireMap(value));
  }

  static Map<Object?, Object?> _requireMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return value;
    }
    throw ArgumentError.value(value, 'value', 'Expected a map payload.');
  }

  static bool _success(Map<Object?, Object?>? result) =>
      result?['success'] as bool? ?? false;
}
