import java.util.Properties
import java.io.FileInputStream

// إعدادات Kotlin متوافقة مع Flutter
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    kotlinOptions {
        jvmTarget = "11"
        freeCompilerArgs += listOf(
            "-Xjvm-default=all",
            "-Xopt-in=kotlin.RequiresOptIn"
        )
    }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services plugin for Firebase
    id("com.google.gms.google-services")
}

// تحميل إعدادات التوقيع
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.montajati.app"
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.montajati.app"
        minSdk = 21 // Android 5.0 كحد أدنى للإنتاج
        targetSdk = 35 // Android 15 - أحدث إصدار
        versionCode = 2
        versionName = "2.0.0"

        // إعدادات التطبيق للإنتاج
        resValue("string", "app_name", "منتجاتي")
        manifestPlaceholders["appName"] = "منتجاتي"

        // إعدادات الأمان
        multiDexEnabled = true
        vectorDrawables.useSupportLibrary = true

        // إعدادات Architecture - دعم 32-bit فقط للتوافق مع الأجهزة القديمة
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "x86"))
        }
    }

    // إعدادات التوقيع
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it.toString()) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
                "r8-rules.pro"
            )
            // إعدادات تحسين إضافية
            isDebuggable = false
            isJniDebuggable = false
            // isRenderscriptDebuggable removed in AGP 9.0+
            // renderscriptOptimLevel removed in AGP 9.0+

            // تحسين APK
            ndk {
                debugSymbolLevel = "NONE"
            }
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // إعدادات Splits لتحسين حجم APK - 32-bit فقط
    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "x86")
            isUniversalApk = true // إنشاء APK شامل يدعم المعمارات 32-bit
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")



    // Google Play Core for Flutter (fixes missing classes)
    implementation("com.google.android.play:core:1.10.3")
    implementation("com.google.android.play:core-ktx:1.8.1")

    // Firebase BoM للإشعارات
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-analytics")
}
