pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    id("org.jetbrains.kotlin.plugin.serialization") version "2.3.20" apply false
}

include(":app")

// ============================================================
// Linkzly Android SDK Configuration
// ============================================================
// ACTIVE: Using local Android SDK from monorepo (for development)
// Points to: 3rd-party-sdk/linkzly-android-sdk/sdk
// This allows the Flutter example app to test local SDK changes immediately.
//
// For production: Client apps can use the published Android SDK artifact instead.
include(":linkzly-android-sdk")
project(":linkzly-android-sdk").projectDir = file("../../../linkzly-android-sdk/sdk")
// ============================================================
