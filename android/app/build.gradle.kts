plugins {
    id("com.android.application")

    // Firebase
    id("com.google.gms.google-services")

    // ✅ Correct Kotlin plugin (REQUIRED)
    id("org.jetbrains.kotlin.android")

    // Flutter plugin (must be last)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.hopeir.app"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13113456"

    defaultConfig {
        applicationId = "com.hopeir.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            // TODO: replace with proper signing config for production
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // ❌ REMOVE unsupported CMake 4.x
    // externalNativeBuild { ... }  ← removed safely
}

/* ✅ dependencies MUST be OUTSIDE android {} */
dependencies {
    implementation("com.google.android.material:material:1.11.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
