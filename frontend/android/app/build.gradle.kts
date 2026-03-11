plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.horizon"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.horizon"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "device"
    productFlavors {
        create("mobile") {
            dimension = "device"
            // Default mobile app
        }
        create("wear") {
            dimension = "device"
            minSdk = 30 // Wear OS 3+ minimum
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Wear OS Tiles (wear flavor only)
    "wearImplementation"("androidx.wear.tiles:tiles:1.4.1")
    "wearImplementation"("androidx.wear.protolayout:protolayout:1.2.1")
    "wearImplementation"("androidx.wear.protolayout:protolayout-material:1.2.1")
    "wearImplementation"("androidx.wear.protolayout:protolayout-expression:1.2.1")
    "wearImplementation"("androidx.work:work-runtime-ktx:2.10.0")
    "wearImplementation"("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    "wearImplementation"("org.jetbrains.kotlinx:kotlinx-coroutines-guava:1.9.0")
}

flutter {
    source = "../.."
}
