plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // 1. Pastikan hanya ada satu baris ndkVersion dan gunakan versi 27
    ndkVersion = "27.0.12077973" 
    
    namespace = "com.example.monitor_keuangan"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        // 2. Aktifkan Desugaring untuk mendukung library notifikasi
        isCoreLibraryDesugaringEnabled = true // TAMBAH INI
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.monitor_keuangan"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// 3. Tambahkan blok dependencies di paling bawah untuk library desugaring
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

flutter {
    source = "../.."
}