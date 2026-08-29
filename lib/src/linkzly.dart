import 'dart:async';

import 'linkzly_method_channel.dart';
import 'models.dart';

class Linkzly {
  Linkzly._({LinkzlyMethodChannel? channel})
      : _channel = channel ?? LinkzlyMethodChannel();

  static final Linkzly instance = Linkzly._();

  final LinkzlyMethodChannel _channel;

  Stream<DeepLinkData> get deepLinkStream => _channel.deepLinkStream;

  Stream<UniversalLinkEvent> get universalLinkStream =>
      _channel.universalLinkStream;

  Future<void> configure(LinkzlyConfig config) async {
    await _channel.configure(config);
    if (config.autoTrackAppOpens) {
      unawaited(trackOpen());
    }
  }

  Future<DeepLinkData?> handleUniversalLink(String url) =>
      _channel.handleUniversalLink(url);

  Future<DeepLinkData?> trackInstall() => _channel.trackInstall();

  Future<DeepLinkData?> trackOpen() => _channel.trackOpen();

  Future<void> trackEvent(
    String eventName, [
    Map<String, Object?> parameters = const <String, Object?>{},
  ]) =>
      _channel.trackEvent(eventName, parameters);

  Future<bool> trackPurchase([
    Map<String, Object?> parameters = const <String, Object?>{},
  ]) =>
      _channel.trackPurchase(parameters);

  /// Track a refund of a prior purchase (pass the original transactionId).
  Future<bool> trackRefund([
    Map<String, Object?> parameters = const <String, Object?>{},
  ]) =>
      _channel.trackRefund(parameters);

  Future<bool> trackEventBatch(List<BatchEvent> events) =>
      _channel.trackEventBatch(events);

  Future<bool> flushEvents() => _channel.flushEvents();

  Future<int> getPendingEventCount() => _channel.getPendingEventCount();

  Future<void> setUserId(String userId) => _channel.setUserId(userId);

  Future<String?> getUserId() => _channel.getUserId();

  /// Register a push notification device token (APNs on iOS, FCM on Android)
  /// with Linkzly's device registry. Safe to call on every launch — the native
  /// SDK throttles network calls and only registers when something changed.
  ///
  /// This is also what enables **broadcast** ("send to All") campaigns: a
  /// successful registration returns the device's per-(Smart App, platform) FCM
  /// topic and subscribes to it. Initialize Firebase before calling this, or the
  /// subscribe is deferred to the next launch.
  Future<void> setNotificationToken(String token) =>
      _channel.setNotificationToken(token);

  /// The currently stored push notification token, if any.
  Future<String?> getNotificationToken() => _channel.getNotificationToken();

  /// Whether a push notification token is currently stored.
  Future<bool> hasNotificationToken() => _channel.hasNotificationToken();

  /// Clear the stored push token locally and revoke it server-side
  /// (e.g. on logout or when notifications are disabled).
  Future<void> clearNotificationToken() => _channel.clearNotificationToken();

  Future<void> setTrackingEnabled(bool enabled) =>
      _channel.setTrackingEnabled(enabled);

  Future<bool> isTrackingEnabled() => _channel.isTrackingEnabled();

  Future<String> getVisitorId() => _channel.getVisitorId();

  Future<void> resetVisitorId() => _channel.resetVisitorId();

  Future<bool> updateConversionValue(int value) =>
      _channel.updateConversionValue(value);

  Future<String?> requestTrackingPermission() =>
      _channel.requestTrackingPermission();

  Future<void> setAdvertisingTrackingEnabled(bool enabled) =>
      _channel.setAdvertisingTrackingEnabled(enabled);

  Future<bool> isAdvertisingTrackingEnabled() =>
      _channel.isAdvertisingTrackingEnabled();

  Future<String?> getAttStatus() => _channel.getAttStatus();

  Future<String?> getIdfa() => _channel.getIdfa();

  /// Re-subscribe to this device's Linkzly broadcast FCM topic.
  ///
  /// **Most apps never need to call this.** [setNotificationToken] already
  /// subscribes on a successful registration, and the native SDK re-subscribes on
  /// every launch.
  ///
  /// It re-subscribes to the topic stored by the last successful
  /// [setNotificationToken] registration (`linkzly_broadcast_<smartAppId>_<platform>`),
  /// which makes it a recovery call for two situations:
  ///
  /// - you unsubscribed from the topic yourself (e.g. via [disablePush]);
  /// - registration succeeded while Firebase Messaging was not yet live, so the
  ///   topic was stored but the subscribe itself failed.
  ///
  /// If registration has never succeeded there is no stored topic and this returns
  /// false — fix the registration instead. FCM-only, via reflection in the native
  /// SDK; also returns false when Firebase Messaging is unavailable.
  Future<bool> initializePush() => _channel.initializePush();

  /// Unsubscribe from this device's broadcast topic (and the legacy global one).
  ///
  /// **Session-scoped, not a durable opt-out.** The stored topic and token are
  /// kept, so the next launch re-subscribes. For a permanent opt-out (logout,
  /// "turn off notifications") call [clearNotificationToken] instead — it revokes
  /// the token server-side and clears the stored topic.
  Future<bool> disablePush() => _channel.disablePush();

  Future<bool> captureAffiliateAttribution(String url) =>
      _channel.captureAffiliateAttribution(url);

  Future<AffiliateAttribution> getAffiliateAttribution() =>
      _channel.getAffiliateAttribution();

  Future<String?> getAffiliateClickId() => _channel.getAffiliateClickId();

  Future<bool> hasAffiliateAttribution() => _channel.hasAffiliateAttribution();

  Future<void> clearAffiliateAttribution() =>
      _channel.clearAffiliateAttribution();

  Future<void> configureGamingTracking({
    required String apiKey,
    required String organizationId,
    required String gameId,
    LinkzlyEnvironment environment = LinkzlyEnvironment.production,
    GamingTrackingOptions options = const GamingTrackingOptions(),
  }) =>
      _channel.configureGamingTracking(
        apiKey: apiKey,
        organizationId: organizationId,
        gameId: gameId,
        environment: environment,
        options: options,
      );

  Future<void> identifyGamingPlayer(
    String playerId, [
    Map<String, Object?> traits = const <String, Object?>{},
  ]) =>
      _channel.identifyGamingPlayer(playerId, traits);

  Future<void> trackGamingEvent(
    String eventType, {
    Map<String, Object?> data = const <String, Object?>{},
    bool immediate = false,
  }) =>
      _channel.trackGamingEvent(
        eventType,
        data: data,
        immediate: immediate,
      );

  Future<void> flushGamingEvents() => _channel.flushGamingEvents();

  Future<void> startGamingSession() => _channel.startGamingSession();

  Future<void> endGamingSession() => _channel.endGamingSession();

  Future<void> setGamingAttribution({
    String? clickId,
    String? deferredDeepLink,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) =>
      _channel.setGamingAttribution(
        clickId: clickId,
        deferredDeepLink: deferredDeepLink,
        metadata: metadata,
      );

  Future<void> clearGamingAttribution() => _channel.clearGamingAttribution();

  Future<void> resetGamingTracking() => _channel.resetGamingTracking();

  Future<GamingTrackingStatus> getGamingStatus() => _channel.getGamingStatus();

  Future<void> debugSetBatchingStrategy(String strategy) =>
      _channel.debugSetBatchingStrategy(strategy);

  Future<void> debugSetBatchSize(int size) => _channel.debugSetBatchSize(size);

  Future<void> debugSetFlushInterval(double intervalSeconds) =>
      _channel.debugSetFlushInterval(intervalSeconds);

  Future<void> debugResetConfig() => _channel.debugResetConfig();

  Future<Map<String, Object?>?> debugGetConfig() => _channel.debugGetConfig();
}
