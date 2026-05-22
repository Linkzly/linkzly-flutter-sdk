package com.linkzly.flutter

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.linkzly.sdk.LinkzlySDK
import com.linkzly.sdk.gaming.LinkzlyGamingTracking
import com.linkzly.sdk.models.DeepLinkData
import com.linkzly.sdk.models.Environment
import com.linkzly.sdk.utils.LinkzlySDKDebug
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.double
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.int
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.long
import kotlinx.serialization.json.longOrNull

class LinkzlyFlutterPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.NewIntentListener {

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private var activityBinding: ActivityPluginBinding? = null
    private var activity: Activity? = null
    private var deepLinkSink: EventChannel.EventSink? = null
    private var universalLinkSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)

        EventChannel(binding.binaryMessenger, DEEP_LINK_EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    deepLinkSink = events
                }

                override fun onCancel(arguments: Any?) {
                    deepLinkSink = null
                }
            }
        )

        EventChannel(binding.binaryMessenger, UNIVERSAL_LINK_EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    universalLinkSink = events
                }

                override fun onCancel(arguments: Any?) {
                    universalLinkSink = null
                }
            }
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        deepLinkSink = null
        universalLinkSink = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "configure" -> configure(call, result)
                "handleUniversalLink" -> handleUniversalLink(call, result)
                "trackInstall" -> LinkzlySDK.trackInstall { resolveDeepLink(result, it) }
                "trackOpen" -> LinkzlySDK.trackOpen { resolveDeepLink(result, it) }
                "trackEvent" -> trackEvent(call, result)
                "trackPurchase" -> trackPurchase(call, result)
                "trackEventBatch" -> trackEventBatch(call, result)
                "flushEvents" -> flushEvents(result)
                "getPendingEventCount" -> result.success(LinkzlySDK.getPendingEventCount())
                "setUserID" -> {
                    LinkzlySDK.setUserID(call.requireArgument("userID"))
                    result.success(successMap())
                }
                "getUserID" -> result.success(LinkzlySDK.getUserID())
                "setTrackingEnabled" -> {
                    LinkzlySDK.setTrackingEnabled(call.requireArgument("enabled"))
                    result.success(successMap())
                }
                "isTrackingEnabled" -> result.success(LinkzlySDK.isTrackingEnabled())
                "getVisitorID" -> result.success(LinkzlySDK.getVisitorID())
                "resetVisitorID" -> {
                    LinkzlySDK.resetVisitorID()
                    result.success(successMap())
                }
                "updateConversionValue" -> result.success(
                    mapOf("success" to false, "message" to "SKAdNetwork is iOS only")
                )
                "requestTrackingPermission" -> result.success("unsupported")
                "setAdvertisingTrackingEnabled" -> {
                    LinkzlySDK.setAdvertisingTrackingEnabled(call.requireArgument("enabled"))
                    result.success(successMap())
                }
                "isAdvertisingTrackingEnabled" -> result.success(
                    LinkzlySDK.isAdvertisingTrackingEnabled()
                )
                "getIDFA", "getATTStatus" -> result.success(null)
                "initializePush" -> result.success(LinkzlySDK.initializePush())
                "disablePush" -> result.success(LinkzlySDK.disablePush())
                "captureAffiliateAttribution" -> captureAffiliateAttribution(call, result)
                "getAffiliateAttribution" -> getAffiliateAttribution(result)
                "getAffiliateClickId" -> result.success(LinkzlySDK.getAffiliateClickId())
                "hasAffiliateAttribution" -> result.success(LinkzlySDK.hasAffiliateAttribution())
                "clearAffiliateAttribution" -> {
                    LinkzlySDK.clearAffiliateAttribution()
                    result.success(successMap())
                }
                "configureGamingTracking" -> configureGamingTracking(call, result)
                "identifyGamingPlayer" -> identifyGamingPlayer(call, result)
                "trackGamingEvent" -> trackGamingEvent(call, result)
                "flushGamingEvents" -> flushGamingEvents(result)
                "startGamingSession" -> {
                    LinkzlyGamingTracking.startSession()
                    result.success(successMap())
                }
                "endGamingSession" -> {
                    LinkzlyGamingTracking.endSession()
                    result.success(successMap())
                }
                "setGamingAttribution" -> setGamingAttribution(call, result)
                "clearGamingAttribution" -> {
                    LinkzlyGamingTracking.clearAttribution()
                    result.success(successMap())
                }
                "resetGamingTracking" -> {
                    LinkzlyGamingTracking.reset()
                    result.success(successMap())
                }
                "getGamingStatus" -> result.success(
                    mapOf(
                        "pendingEventCount" to LinkzlyGamingTracking.getPendingCount(),
                        "hasInflightBatch" to LinkzlyGamingTracking.hasInflightBatch()
                    )
                )
                "debugSetBatchingStrategy" -> debugSetBatchingStrategy(call, result)
                "debugSetBatchSize" -> debugSetBatchSize(call, result)
                "debugSetFlushInterval" -> debugSetFlushInterval(call, result)
                "debugResetConfig" -> debugResetConfig(result)
                "debugGetConfig" -> debugGetConfig(result)
                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            result.error(call.method.uppercase() + "_ERROR", error.message, null)
        }
    }

    override fun onNewIntent(intent: Intent): Boolean {
        val data = LinkzlySDK.handleAppLink(intent) ?: return false
        emitDeepLink(data.toFlutterMap())
        return true
    }

    private fun configure(call: MethodCall, result: MethodChannel.Result) {
        val sdkKey = call.requireArgument<String>("sdkKey")
        LinkzlySDK.configure(context, sdkKey, call.environmentArgument())
        result.success(successMap())
    }

    private fun handleUniversalLink(call: MethodCall, result: MethodChannel.Result) {
        val url = call.requireArgument<String>("url")
        val intent = Intent().apply { data = Uri.parse(url) }
        val deepLinkData = LinkzlySDK.handleAppLink(intent)
        if (deepLinkData == null) {
            result.success(null)
            return
        }

        val payload = deepLinkData.toFlutterMap()
        emitDeepLink(payload)
        result.success(payload)
    }

    private fun trackEvent(call: MethodCall, result: MethodChannel.Result) {
        LinkzlySDK.trackEvent(
            call.requireArgument("eventName"),
            call.mapArgument("parameters")
        )
        result.success(successMap())
    }

    private fun trackPurchase(call: MethodCall, result: MethodChannel.Result) {
        LinkzlySDK.trackPurchase(call.mapArgument("parameters")) { response ->
            response.fold(
                onSuccess = { result.success(mapOf("success" to it)) },
                onFailure = { result.error("TRACK_PURCHASE_ERROR", it.message, null) }
            )
        }
    }

    private fun trackEventBatch(call: MethodCall, result: MethodChannel.Result) {
        val events = call.argument<List<Map<String, Any?>>>("events").orEmpty()
            .map { event ->
                val parameters = (event["parameters"] as? Map<String, Any?>)
                    ?.filterValues { it != null }
                    .orEmpty()

                mapOf<String, Any>(
                    "eventType" to "custom",
                    "eventName" to (event["eventName"] as? String).orEmpty(),
                    "parameters" to parameters,
                    "customData" to parameters
                )
            }

        LinkzlySDK.trackEventBatch(events) { response ->
            response.fold(
                onSuccess = { result.success(mapOf("success" to it)) },
                onFailure = { result.error("TRACK_BATCH_ERROR", it.message, null) }
            )
        }
    }

    private fun flushEvents(result: MethodChannel.Result) {
        LinkzlySDK.flushEvents { response ->
            response.fold(
                onSuccess = { result.success(mapOf("success" to it)) },
                onFailure = { result.error("FLUSH_ERROR", it.message, null) }
            )
        }
    }

    private fun captureAffiliateAttribution(call: MethodCall, result: MethodChannel.Result) {
        result.success(LinkzlySDK.captureAffiliateAttribution(Uri.parse(call.requireArgument("url"))))
    }

    private fun getAffiliateAttribution(result: MethodChannel.Result) {
        val attribution = LinkzlySDK.getAffiliateAttribution()
        result.success(
            mapOf(
                "clickId" to attribution.clickId,
                "programId" to attribution.programId,
                "affiliateId" to attribution.affiliateId,
                "timestamp" to attribution.timestamp,
                "hasAttribution" to attribution.hasAttribution,
                "source" to attribution.source.name.lowercase()
            )
        )
    }

    private fun configureGamingTracking(call: MethodCall, result: MethodChannel.Result) {
        val options = call.mapArgument("options")
        val baseUrl = options["baseUrl"] as? String ?: when (call.environmentArgument()) {
            Environment.STAGING -> "https://linkzly-gaming-tracking-staging.webmaster-linkzly.workers.dev"
            Environment.DEVELOPMENT -> "https://linkzly-gaming-tracking-development.webmaster-linkzly.workers.dev"
            Environment.PRODUCTION -> "https://gaming.linkzly.com"
        }

        LinkzlyGamingTracking.configure(
            context,
            LinkzlyGamingTracking.GamingOptions(
                apiKey = call.requireArgument("apiKey"),
                organizationId = call.requireArgument("organizationId"),
                gameId = call.requireArgument("gameId"),
                baseUrl = baseUrl,
                endpointPath = options["endpointPath"] as? String ?: "/api/v1/gaming/events",
                sdkVersion = options["sdkVersion"] as? String ?: "1.0.0",
                gameVersion = options["gameVersion"] as? String ?: "",
                includeTraits = options.booleanValue("includeTraits", false),
                debug = options.booleanValue("debug", false),
                maxBatchSize = options.intValue("maxBatchSize", 100),
                maxBatchBytes = options.intValue("maxBatchBytes", 512 * 1024),
                flushIntervalMs = options.intValue("flushIntervalMs", 5000),
                maxRetries = options.intValue("maxRetries", 3),
                retryDelayMs = options.intValue("retryDelayMs", 1000),
                maxQueueSize = options.intValue("maxQueueSize", 10000),
                sessionTimeoutMs = options.intValue("sessionTimeoutMs", 30 * 60 * 1000),
                autoSessionTracking = options.booleanValue("autoSessionTracking", true),
                signingSecret = options["signingSecret"] as? String
            )
        )
        result.success(successMap())
    }

    private fun identifyGamingPlayer(call: MethodCall, result: MethodChannel.Result) {
        LinkzlyGamingTracking.identify(
            call.requireArgument("playerId"),
            call.mapArgument("traits")
        )
        result.success(successMap())
    }

    private fun trackGamingEvent(call: MethodCall, result: MethodChannel.Result) {
        LinkzlyGamingTracking.track(
            call.requireArgument("eventType"),
            call.mapArgument("data"),
            immediateFlush = call.argument<Boolean>("immediate") ?: false
        )
        result.success(successMap())
    }

    private fun flushGamingEvents(result: MethodChannel.Result) {
        LinkzlyGamingTracking.flush(LinkzlyGamingTracking.LinkzlyGamingFlushReason.MANUAL_FLUSH) { success, error ->
            if (success) {
                result.success(successMap())
            } else {
                result.error("GAMING_FLUSH_ERROR", error ?: "Gaming flush failed", null)
            }
        }
    }

    private fun setGamingAttribution(call: MethodCall, result: MethodChannel.Result) {
        LinkzlyGamingTracking.setAttribution(
            call.argument("clickId"),
            call.argument("deferredDeepLink"),
            call.mapArgument("metadata")
        )
        result.success(successMap())
    }

    private fun debugSetBatchingStrategy(call: MethodCall, result: MethodChannel.Result) {
        requireDebuggable()
        LinkzlySDKDebug.setBatchingStrategy(context, call.requireArgument("strategy"))
        result.success(successMap())
    }

    private fun debugSetBatchSize(call: MethodCall, result: MethodChannel.Result) {
        requireDebuggable()
        LinkzlySDKDebug.setBatchSize(context, call.requireArgument("size"))
        result.success(successMap())
    }

    private fun debugSetFlushInterval(call: MethodCall, result: MethodChannel.Result) {
        requireDebuggable()
        LinkzlySDKDebug.setFlushInterval(
            context,
            (call.argument<Double>("interval") ?: 0.0).toLong()
        )
        result.success(successMap())
    }

    private fun debugResetConfig(result: MethodChannel.Result) {
        requireDebuggable()
        LinkzlySDKDebug.resetDebugConfig(context)
        result.success(successMap())
    }

    private fun debugGetConfig(result: MethodChannel.Result) {
        requireDebuggable()
        val strategy = LinkzlySDKDebug.getDebugStrategy(context)
        val batchSize = LinkzlySDKDebug.getDebugBatchSize(context)
        val flushInterval = LinkzlySDKDebug.getDebugFlushInterval(context)
        if (strategy == null && batchSize == null && flushInterval == null) {
            result.success(null)
        } else {
            result.success(
                mapOf(
                    "strategy" to strategy,
                    "batchSize" to batchSize,
                    "flushInterval" to flushInterval
                )
            )
        }
    }

    private fun resolveDeepLink(
        result: MethodChannel.Result,
        response: Result<DeepLinkData?>
    ) {
        response.fold(
            onSuccess = { deepLinkData ->
                val payload = deepLinkData?.toFlutterMap()
                if (payload != null) {
                    emitDeepLink(payload)
                }
                result.success(payload)
            },
            onFailure = { result.error("ATTRIBUTION_ERROR", it.message, null) }
        )
    }

    private fun emitDeepLink(payload: Map<String, Any?>) {
        activity?.runOnUiThread { deepLinkSink?.success(payload) } ?: deepLinkSink?.success(payload)
    }

    private fun requireDebuggable() {
        if (!LinkzlySDKDebug.isAppDebuggable(context)) {
            throw IllegalStateException("Debug methods are only available in debuggable app builds")
        }
    }

    companion object {
        private const val METHOD_CHANNEL = "linkzly_flutter_sdk/methods"
        private const val DEEP_LINK_EVENT_CHANNEL = "linkzly_flutter_sdk/deep_links"
        private const val UNIVERSAL_LINK_EVENT_CHANNEL = "linkzly_flutter_sdk/universal_links"
    }
}

private fun DeepLinkData.toFlutterMap(): Map<String, Any?> = mapOf(
    "url" to url,
    "path" to path,
    "parameters" to parameters.toFlutterValue(),
    "smartLinkId" to smartLinkId,
    "clickId" to clickId
)

private fun JsonElement.toFlutterValue(): Any? = when (this) {
    is JsonNull -> null
    is JsonPrimitive -> when {
        isString -> content
        booleanOrNull != null -> boolean
        intOrNull != null -> int
        longOrNull != null -> long
        doubleOrNull != null -> double
        else -> content
    }
    is JsonArray -> map { it.toFlutterValue() }
    is JsonObject -> mapValues { it.value.toFlutterValue() }
}

private inline fun <reified T> MethodCall.requireArgument(name: String): T =
    argument<T>(name) ?: throw IllegalArgumentException("Missing required argument: $name")

private fun MethodCall.environmentArgument(): Environment = when (argument<Int>("environment") ?: 0) {
    1 -> Environment.STAGING
    2 -> Environment.DEVELOPMENT
    else -> Environment.PRODUCTION
}

@Suppress("UNCHECKED_CAST")
private fun MethodCall.mapArgument(name: String): Map<String, Any> =
    (argument<Map<String, Any?>>(name) ?: emptyMap()).filterValues { it != null } as Map<String, Any>

private fun Map<String, Any>.intValue(key: String, fallback: Int): Int = when (val value = this[key]) {
    is Number -> value.toInt()
    is String -> value.toIntOrNull() ?: fallback
    else -> fallback
}

private fun Map<String, Any>.booleanValue(key: String, fallback: Boolean): Boolean =
    when (val value = this[key]) {
        is Boolean -> value
        is Number -> value.toInt() != 0
        is String -> when (value.lowercase()) {
            "true", "1", "yes" -> true
            "false", "0", "no" -> false
            else -> fallback
        }
        else -> fallback
    }

private fun successMap(): Map<String, Boolean> = mapOf("success" to true)
