enum LinkzlyEnvironment {
  production,
  staging,
  development;

  int get nativeValue => index;
}

class LinkzlyConfig {
  const LinkzlyConfig({
    required this.sdkKey,
    this.environment = LinkzlyEnvironment.production,
    this.autoTrackAppOpens = true,
  });

  final String sdkKey;
  final LinkzlyEnvironment environment;
  final bool autoTrackAppOpens;

  Map<String, Object?> toMap() => <String, Object?>{
        'sdkKey': sdkKey,
        'environment': environment.nativeValue,
      };
}

class DeepLinkData {
  const DeepLinkData({
    this.url,
    this.path,
    this.smartLinkId,
    this.clickId,
    this.parameters = const <String, Object?>{},
  });

  final String? url;
  final String? path;
  final String? smartLinkId;
  final String? clickId;
  final Map<String, Object?> parameters;

  factory DeepLinkData.fromMap(Map<Object?, Object?> map) => DeepLinkData(
        url: map['url'] as String?,
        path: map['path'] as String?,
        smartLinkId: map['smartLinkId'] as String?,
        clickId: map['clickId'] as String?,
        parameters: _stringObjectMap(map['parameters']),
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'url': url,
        'path': path,
        'smartLinkId': smartLinkId,
        'clickId': clickId,
        'parameters': parameters,
      };
}

class UniversalLinkEvent {
  const UniversalLinkEvent({
    required this.url,
    this.path,
    this.parameters = const <String, Object?>{},
    this.attributionData = const <String, Object?>{},
  });

  final String url;
  final String? path;
  final Map<String, Object?> parameters;
  final Map<String, Object?> attributionData;

  factory UniversalLinkEvent.fromMap(Map<Object?, Object?> map) =>
      UniversalLinkEvent(
        url: map['url'] as String? ?? '',
        path: map['path'] as String?,
        parameters: _stringObjectMap(map['parameters']),
        attributionData: _stringObjectMap(map['attributionData']),
      );
}

class BatchEvent {
  const BatchEvent(
    this.eventName, {
    this.parameters = const <String, Object?>{},
  });

  final String eventName;
  final Map<String, Object?> parameters;

  Map<String, Object?> toMap() => <String, Object?>{
        'eventName': eventName,
        'parameters': parameters,
      };
}

class AffiliateAttribution {
  const AffiliateAttribution({
    this.clickId,
    this.programId,
    this.affiliateId,
    this.timestamp,
    required this.hasAttribution,
    required this.source,
  });

  final String? clickId;
  final String? programId;
  final String? affiliateId;
  final int? timestamp;
  final bool hasAttribution;
  final String source;

  factory AffiliateAttribution.fromMap(Map<Object?, Object?> map) {
    final timestamp = map['timestamp'];
    return AffiliateAttribution(
      clickId: map['clickId'] as String?,
      programId: map['programId'] as String?,
      affiliateId: map['affiliateId'] as String?,
      timestamp: timestamp is int
          ? timestamp
          : timestamp is num
              ? timestamp.toInt()
              : null,
      hasAttribution: map['hasAttribution'] as bool? ?? false,
      source: map['source'] as String? ?? 'none',
    );
  }
}

class GamingTrackingOptions {
  const GamingTrackingOptions({
    this.baseUrl,
    this.endpointPath,
    this.sdkVersion,
    this.gameVersion,
    this.includeTraits,
    this.debug,
    this.maxBatchSize,
    this.maxBatchBytes,
    this.flushIntervalMs,
    this.maxRetries,
    this.retryDelayMs,
    this.maxQueueSize,
    this.sessionTimeoutMs,
    this.autoSessionTracking,
    this.signingSecret,
  });

  final String? baseUrl;
  final String? endpointPath;
  final String? sdkVersion;
  final String? gameVersion;
  final bool? includeTraits;
  final bool? debug;
  final int? maxBatchSize;
  final int? maxBatchBytes;
  final int? flushIntervalMs;
  final int? maxRetries;
  final int? retryDelayMs;
  final int? maxQueueSize;
  final int? sessionTimeoutMs;
  final bool? autoSessionTracking;
  final String? signingSecret;

  Map<String, Object?> toMap() => <String, Object?>{
        if (baseUrl != null) 'baseUrl': baseUrl,
        if (endpointPath != null) 'endpointPath': endpointPath,
        if (sdkVersion != null) 'sdkVersion': sdkVersion,
        if (gameVersion != null) 'gameVersion': gameVersion,
        if (includeTraits != null) 'includeTraits': includeTraits,
        if (debug != null) 'debug': debug,
        if (maxBatchSize != null) 'maxBatchSize': maxBatchSize,
        if (maxBatchBytes != null) 'maxBatchBytes': maxBatchBytes,
        if (flushIntervalMs != null) 'flushIntervalMs': flushIntervalMs,
        if (maxRetries != null) 'maxRetries': maxRetries,
        if (retryDelayMs != null) 'retryDelayMs': retryDelayMs,
        if (maxQueueSize != null) 'maxQueueSize': maxQueueSize,
        if (sessionTimeoutMs != null) 'sessionTimeoutMs': sessionTimeoutMs,
        if (autoSessionTracking != null)
          'autoSessionTracking': autoSessionTracking,
        if (signingSecret != null) 'signingSecret': signingSecret,
      };
}

class GamingTrackingStatus {
  const GamingTrackingStatus({
    required this.pendingEventCount,
    required this.hasInflightBatch,
  });

  final int pendingEventCount;
  final bool hasInflightBatch;

  factory GamingTrackingStatus.fromMap(Map<Object?, Object?> map) =>
      GamingTrackingStatus(
        pendingEventCount: (map['pendingEventCount'] as num?)?.toInt() ?? 0,
        hasInflightBatch: map['hasInflightBatch'] as bool? ?? false,
      );
}

Map<String, Object?> _stringObjectMap(Object? value) {
  if (value is Map<Object?, Object?>) {
    final result = <String, Object?>{};
    value.forEach((Object? key, Object? item) {
      result['$key'] = item;
    });
    return result;
  }
  return <String, Object?>{};
}
