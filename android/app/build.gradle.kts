plugins {
    id("com.android.application")

    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration

    // Flutter Gradle Plugin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.tafheel_docs"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // ============================================================
    // JAVA / CORE LIBRARY DESUGARING
    // ============================================================

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17

        // Required by flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    // ============================================================
    // DEFAULT CONFIG
    // ============================================================

    defaultConfig {
        applicationId = "com.example.tafheel_docs"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ============================================================
    // BUILD TYPES
    // ============================================================

    buildTypes {
        release {
            // Debug signing for now
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// ================================================================
// KOTLIN
// ================================================================

kotlin {
    compilerOptions {
        jvmTarget =
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// ================================================================
// DEPENDENCIES
// ================================================================

dependencies {

    // Required for flutter_local_notifications
    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.1.5"
    )
}

// ================================================================
// FLUTTER
// ================================================================

flutter {
    source = "../.."
}