plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // ✅ Giữ lại đúng NDK version cao nhất mà Firebase yêu cầu
    ndkVersion = "27.0.12077973"

    namespace = "com.example.music_app"
    compileSdk = 35 // hoặc flutter.compileSdkVersion nếu bạn muốn dùng biến tự động

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.music_app"

        // ⚠️ Firebase yêu cầu minSdk >= 23
        minSdk = 23

        // Bạn có thể để targetSdk là 34 (API mới nhất)
        targetSdk = 34

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}


flutter {
    source = "../.."
}
