import Flutter
import Foundation
import LinkzlySDK
import StoreKit
import UIKit

public class LinkzlyFlutterSdkPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
    private let deepLinkEvents = BufferedEventSink()
    private let universalLinkEvents = BufferedEventSink()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = LinkzlyFlutterSdkPlugin()

        let methodChannel = FlutterMethodChannel(
            name: "linkzly_flutter_sdk/methods",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        FlutterEventChannel(
            name: "linkzly_flutter_sdk/deep_links",
            binaryMessenger: registrar.messenger()
        ).setStreamHandler(instance.deepLinkEvents)

        FlutterEventChannel(
            name: "linkzly_flutter_sdk/universal_links",
            binaryMessenger: registrar.messenger()
        ).setStreamHandler(instance.universalLinkEvents)

        // Dual-register so hosts on either lifecycle receive URL callbacks.
        // LinkzlySDK.handleUniversalLink is idempotent, so handling the same
        // URL through both delegates is safe.
        registrar.addApplicationDelegate(instance)
        registrar.addSceneDelegate(instance)
        instance.observeNativeEvents()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]

        switch call.method {
        case "configure":
            guard let sdkKey = args["sdkKey"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "sdkKey is required", details: nil))
                return
            }
            LinkzlySDK.configure(sdkKey: sdkKey, environment: environment(from: args["environment"]))
            result(successMap())

        case "handleUniversalLink":
            guard let urlText = args["url"] as? String, let url = URL(string: urlText) else {
                result(FlutterError(code: "INVALID_URL", message: "Invalid URL provided", details: nil))
                return
            }
            _ = LinkzlySDK.handleUniversalLink(url)
            result(nil)

        case "trackInstall":
            LinkzlySDK.trackInstall { response in result(Self.deepLinkResult(response)) }

        case "trackOpen":
            LinkzlySDK.trackOpen { response in result(Self.deepLinkResult(response)) }

        case "trackEvent":
            guard let eventName = args["eventName"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "eventName is required", details: nil))
                return
            }
            LinkzlySDK.trackEvent(eventName, parameters: args["parameters"] as? [String: Any])
            result(successMap())

        case "trackPurchase":
            LinkzlySDK.trackPurchase(parameters: args["parameters"] as? [String: Any] ?? [:]) { response in
                switch response {
                case .success:
                    result(successMap())
                case .failure(let error):
                    result(FlutterError(code: "TRACK_PURCHASE_ERROR", message: error.localizedDescription, details: nil))
                }
            }

        case "trackEventBatch":
            LinkzlySDK.trackEventBatch(args["events"] as? [[String: Any]] ?? []) { success, error in
                if success {
                    result(successMap())
                } else {
                    result(FlutterError(code: "TRACK_BATCH_ERROR", message: error?.localizedDescription ?? "Batch tracking failed", details: nil))
                }
            }

        case "flushEvents":
            LinkzlySDK.flushEvents { success, error in
                if success {
                    result(successMap())
                } else {
                    result(FlutterError(code: "FLUSH_ERROR", message: error?.localizedDescription ?? "Flush failed", details: nil))
                }
            }

        case "getPendingEventCount":
            result(LinkzlySDK.getPendingEventCount())

        case "setUserID":
            LinkzlySDK.setUserID(requiredString(args, "userID"))
            result(successMap())

        case "getUserID":
            result(LinkzlySDK.getUserID())

        case "setTrackingEnabled":
            LinkzlySDK.setTrackingEnabled(requiredBool(args, "enabled"))
            result(successMap())

        case "isTrackingEnabled":
            result(LinkzlySDK.isTrackingEnabled())

        case "getVisitorID":
            result(LinkzlySDK.getVisitorID())

        case "resetVisitorID":
            LinkzlySDK.resetVisitorID()
            result(successMap())

        case "updateConversionValue":
            updateConversionValue(args, result: result)

        case "requestTrackingPermission":
            requestTrackingPermission(result)

        case "setAdvertisingTrackingEnabled":
            LinkzlySDK.setAdvertisingTrackingEnabled(requiredBool(args, "enabled"))
            result(successMap())

        case "isAdvertisingTrackingEnabled":
            result(LinkzlySDK.isAdvertisingTrackingEnabled())

        case "getIDFA":
            result(LinkzlySDK.getIDFA())

        case "getATTStatus":
            result(LinkzlySDK.getATTStatus())

        case "initializePush":
            result(LinkzlySDK.initializePush())

        case "disablePush":
            result(LinkzlySDK.disablePush())

        case "captureAffiliateAttribution":
            guard let urlText = args["url"] as? String, let url = URL(string: urlText) else {
                result(false)
                return
            }
            result(LinkzlySDK.captureAffiliateAttribution(from: url))

        case "getAffiliateAttribution":
            let attribution = LinkzlySDK.getAffiliateAttribution()
            result([
                "clickId": attribution.clickId as Any? ?? NSNull(),
                "programId": attribution.programId as Any? ?? NSNull(),
                "affiliateId": attribution.affiliateId as Any? ?? NSNull(),
                "timestamp": attribution.timestamp as Any? ?? NSNull(),
                "hasAttribution": attribution.hasAttribution,
                "source": attribution.source.rawValue
            ])

        case "getAffiliateClickId":
            result(LinkzlySDK.getAffiliateClickId())

        case "hasAffiliateAttribution":
            result(LinkzlySDK.hasAffiliateAttribution())

        case "clearAffiliateAttribution":
            LinkzlySDK.clearAffiliateAttribution()
            result(successMap())

        case "configureGamingTracking":
            configureGamingTracking(args, result: result)

        case "identifyGamingPlayer":
            LinkzlySDK.identifyGamingPlayer(
                requiredString(args, "playerId"),
                traits: args["traits"] as? [String: Any]
            )
            result(successMap())

        case "trackGamingEvent":
            let eventType = requiredString(args, "eventType")
            if args["immediate"] as? Bool == true {
                LinkzlySDK.trackGamingEventImmediate(eventType, data: args["data"] as? [String: Any])
            } else {
                LinkzlySDK.trackGamingEvent(eventType, data: args["data"] as? [String: Any])
            }
            result(successMap())

        case "flushGamingEvents":
            LinkzlySDK.flushGamingEvents(.manualFlush) { success, error in
                if success {
                    result(successMap())
                } else {
                    result(FlutterError(code: "GAMING_FLUSH_ERROR", message: error?.localizedDescription ?? "Gaming flush failed", details: nil))
                }
            }

        case "startGamingSession":
            LinkzlySDK.startGamingSession()
            result(successMap())

        case "endGamingSession":
            LinkzlySDK.endGamingSession()
            result(successMap())

        case "setGamingAttribution":
            LinkzlySDK.setGamingAttribution(
                clickId: args["clickId"] as? String,
                deferredDeepLink: args["deferredDeepLink"] as? String,
                metadata: args["metadata"] as? [String: Any]
            )
            result(successMap())

        case "clearGamingAttribution":
            LinkzlySDK.clearGamingAttribution()
            result(successMap())

        case "resetGamingTracking":
            LinkzlySDK.resetGamingTracking()
            result(successMap())

        case "getGamingStatus":
            LinkzlySDK.getGamingStatus { status in
                result([
                    "pendingEventCount": status.pendingEventCount,
                    "hasInflightBatch": status.hasInflightBatch
                ])
            }

        case "debugSetBatchingStrategy":
            #if DEBUG
            LinkzlySDKDebug.setBatchingStrategy(requiredString(args, "strategy"))
            result(successMap())
            #else
            result(FlutterError(code: "DEBUG_ONLY", message: "Debug methods are only available in DEBUG builds", details: nil))
            #endif

        case "debugSetBatchSize":
            #if DEBUG
            LinkzlySDKDebug.setBatchSize(requiredInt(args, "size"))
            result(successMap())
            #else
            result(FlutterError(code: "DEBUG_ONLY", message: "Debug methods are only available in DEBUG builds", details: nil))
            #endif

        case "debugSetFlushInterval":
            #if DEBUG
            LinkzlySDKDebug.setFlushInterval(args["interval"] as? Double ?? 0)
            result(successMap())
            #else
            result(FlutterError(code: "DEBUG_ONLY", message: "Debug methods are only available in DEBUG builds", details: nil))
            #endif

        case "debugResetConfig":
            #if DEBUG
            LinkzlySDKDebug.resetDebugConfig()
            result(successMap())
            #else
            result(FlutterError(code: "DEBUG_ONLY", message: "Debug methods are only available in DEBUG builds", details: nil))
            #endif

        case "debugGetConfig":
            #if DEBUG
            var config: [String: Any] = [:]
            if let strategy = UserDefaults.standard.string(forKey: "linkzly_debug_batching_strategy") {
                config["strategy"] = strategy
            }
            if let batchSize = UserDefaults.standard.object(forKey: "linkzly_debug_batch_size") as? Int {
                config["batchSize"] = batchSize
            }
            if let flushInterval = UserDefaults.standard.object(forKey: "linkzly_debug_flush_interval") as? Double {
                config["flushInterval"] = flushInterval
            }
            if config.isEmpty {
                result(nil)
            } else {
                result(config)
            }
            #else
            result(FlutterError(code: "DEBUG_ONLY", message: "Debug methods are only available in DEBUG builds", details: nil))
            #endif

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return LinkzlySDK.handleUniversalLink(url)
    }

    public func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        return LinkzlySDK.handleUniversalLink(userActivity)
    }

    // MARK: - FlutterSceneLifeCycleDelegate (Flutter 3.38+)

    public func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) -> Bool {
        var handled = false
        for context in URLContexts {
            if LinkzlySDK.handleUniversalLink(context.url) {
                handled = true
            }
        }
        return handled
    }

    public func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> Bool {
        return LinkzlySDK.handleUniversalLink(userActivity)
    }

    private func observeNativeEvents() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDeepLink(_:)),
            name: .linkzlyDeepLinkDataReceived,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onUniversalLink(_:)),
            name: .linkzlyUniversalLinkReceived,
            object: nil
        )
    }

    @objc private func onDeepLink(_ notification: Notification) {
        guard let data = notification.userInfo?["deepLinkData"] as? DeepLinkData else { return }
        var payload = Self.mapDeepLinkData(data)
        if let url = notification.userInfo?["url"] as? String {
            payload["url"] = url
        }
        deepLinkEvents.emit(payload)
    }

    @objc private func onUniversalLink(_ notification: Notification) {
        guard let url = notification.userInfo?["url"] as? URL else { return }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var parameters: [String: Any] = [:]
        components?.queryItems?.forEach { item in
            parameters[item.name] = item.value
        }
        universalLinkEvents.emit([
            "url": url.absoluteString,
            "path": url.path,
            "parameters": parameters,
            "attributionData": notification.userInfo?["attributionData"] as? [String: Any] ?? [:]
        ])
    }

    private func updateConversionValue(_ args: [String: Any], result: @escaping FlutterResult) {
        guard let value = intValue(args["value"]) else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "value is required", details: nil))
            return
        }
        if #available(iOS 14.0, *) {
            LinkzlySDK.updateConversionValue(value) { success in
                result(["success": success])
            }
        } else {
            result(["success": false])
        }
    }

    private func requestTrackingPermission(_ result: @escaping FlutterResult) {
        if #available(iOS 14.5, *) {
            LinkzlySDK.requestTrackingPermissionObjC { status, error in
                if let error = error {
                    result(FlutterError(code: "ATT_ERROR", message: error.localizedDescription, details: nil))
                } else {
                    result(status)
                }
            }
        } else {
            result(nil)
        }
    }

    private func configureGamingTracking(_ args: [String: Any], result: FlutterResult) {
        guard
            let apiKey = args["apiKey"] as? String, !apiKey.isEmpty,
            let organizationId = args["organizationId"] as? String, !organizationId.isEmpty,
            let gameId = args["gameId"] as? String, !gameId.isEmpty
        else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "apiKey, organizationId, and gameId are required", details: nil))
            return
        }

        let options = args["options"] as? [String: Any] ?? [:]
        let config = LinkzlyGamingOptions()

        if let baseURL = options["baseUrl"] as? String { config.baseURL = baseURL }
        if let endpointPath = options["endpointPath"] as? String { config.endpointPath = endpointPath }
        if let sdkVersion = options["sdkVersion"] as? String { config.sdkVersion = sdkVersion }
        if let gameVersion = options["gameVersion"] as? String { config.gameVersion = gameVersion }
        if let includeTraits = boolValue(options["includeTraits"]) { config.includeTraits = includeTraits }
        if let debug = boolValue(options["debug"]) { config.debug = debug }
        if let maxBatchSize = intValue(options["maxBatchSize"]) { config.maxBatchSize = maxBatchSize }
        if let maxBatchBytes = intValue(options["maxBatchBytes"]) { config.maxBatchBytes = maxBatchBytes }
        if let flushIntervalMs = intValue(options["flushIntervalMs"]) { config.flushIntervalMs = flushIntervalMs }
        if let maxRetries = intValue(options["maxRetries"]) { config.maxRetries = maxRetries }
        if let retryDelayMs = intValue(options["retryDelayMs"]) { config.retryDelayMs = retryDelayMs }
        if let maxQueueSize = intValue(options["maxQueueSize"]) { config.maxQueueSize = maxQueueSize }
        if let sessionTimeoutMs = intValue(options["sessionTimeoutMs"]) { config.sessionTimeoutMs = sessionTimeoutMs }
        if let autoSessionTracking = boolValue(options["autoSessionTracking"]) { config.autoSessionTracking = autoSessionTracking }
        if let signingSecret = options["signingSecret"] as? String { config.signingSecret = signingSecret }

        LinkzlySDK.configureGamingTracking(
            apiKey: apiKey,
            organizationId: organizationId,
            gameId: gameId,
            environment: environment(from: args["environment"]),
            options: config
        )

        result(successMap())
    }

    private static func deepLinkResult(_ response: Result<DeepLinkData?, Error>) -> Any? {
        switch response {
        case .success(let data):
            guard let data = data else { return nil }
            return mapDeepLinkData(data)
        case .failure(let error):
            return FlutterError(code: "ATTRIBUTION_ERROR", message: error.localizedDescription, details: nil)
        }
    }

    private static func mapDeepLinkData(_ data: DeepLinkData) -> [String: Any] {
        [
            "url": data.url as Any? ?? NSNull(),
            "path": data.path as Any? ?? NSNull(),
            "parameters": data.parameters,
            "smartLinkId": data.smartLinkId as Any? ?? NSNull(),
            "clickId": data.clickId as Any? ?? NSNull()
        ]
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

private final class BufferedEventSink: NSObject, FlutterStreamHandler {
    private var sink: FlutterEventSink?
    private var pendingEvents: [Any] = []

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        pendingEvents.forEach { events($0) }
        pendingEvents.removeAll()
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }

    func emit(_ event: Any) {
        DispatchQueue.main.async {
            if let sink = self.sink {
                sink(event)
            } else {
                self.pendingEvents.append(event)
            }
        }
    }
}

private func environment(from value: Any?) -> Environment {
    switch intValue(value) ?? 0 {
    case 1:
        return .staging
    case 2:
        return .development
    default:
        return .production
    }
}

private func successMap() -> [String: Bool] {
    ["success": true]
}

// Best-effort coercion. Returns a safe default when the key is missing or wrong type.
// Use explicit `guard let arg = args["key"] as? Type` at call sites where missing input must fail.
private func requiredString(_ args: [String: Any], _ key: String) -> String {
    args[key] as? String ?? ""
}

private func requiredBool(_ args: [String: Any], _ key: String) -> Bool {
    args[key] as? Bool ?? false
}

private func requiredInt(_ args: [String: Any], _ key: String) -> Int {
    intValue(args[key]) ?? 0
}

private func intValue(_ value: Any?) -> Int? {
    if let intValue = value as? Int { return intValue }
    if let number = value as? NSNumber { return number.intValue }
    if let text = value as? String { return Int(text) }
    return nil
}

private func boolValue(_ value: Any?) -> Bool? {
    if let boolValue = value as? Bool { return boolValue }
    if let number = value as? NSNumber { return number.boolValue }
    if let text = value as? String {
        switch text.lowercased() {
        case "true", "1", "yes":
            return true
        case "false", "0", "no":
            return false
        default:
            return nil
        }
    }
    return nil
}
