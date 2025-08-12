plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // Google Services plugin for Firebase
    id("dev.flutter.flutter-gradle-plugin") // Flutter Gradle plugin
}

android {
    namespace = "com.isaac.shift_cover" // Change this to your actual app ID
    compileSdk = 33

    defaultConfig {
        applicationId = "com.isaac.shift_cover" // Change to your app ID
        minSdk = 21
        targetSdk = 33
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("com.google.firebase:firebase-auth-ktx:22.1.1")
    implementation("com.google.android.gms:play-services-auth:20.6.0")
}

flutter {
    source = "../.."
}
