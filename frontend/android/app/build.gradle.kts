import java.util.Properties
import java.io.FileInputStream

// إعدادات Kotlin محسنة لتجنب مشاكل daemon
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    kotlinOptions {
        jvmTarget = "1.8"
        freeCompilerArgs = listOf(
            "-Xno-call-assertions",
            "-Xno-param-assertions",
            "-Xno-receiver-assertions"
        )
    }
    // تعطيل incremental compilation
    incremental = false
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
    compileSdk = 35  // مطلوب للمكونات الإضافية
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.montajati.app"
        minSdk = 21 // Android 5.0 كحد أدنى للإنتاج
        targetSdk = 35 // Android 15 - مطلوب للمكونات الإضافية
        versionCode = 8
        versionName = "2.2.0"

        // إعدادات التطبيق للإنتاج
        resValue("string", "app_name", "منتجاتي")
        manifestPlaceholders["appName"] = "منتجاتي"

        // إعدادات الأمان
        multiDexEnabled = true
        vectorDrawables.useSupportLibrary = true

        // إعدادات Architecture - دعم جميع المعماريات للتطوير والاختبار
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64"))
        }
    }

    // إعدادات التوقيع
    signingConfigs {
        getByName("debug") {
            keyAlias = "androiddebugkey"
            keyPassword = "android"
            storeFile = file("debug.keystore")
            storePassword = "android"
        }
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

    // إعدادات Splits لتحسين حجم APK - دعم جميع المعماريات
    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
            isUniversalApk = true // إنشاء APK شامل يدعم جميع المعماريات
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

    // Firebase BoM للإشعارات - إصدار متوافق مع Kotlin 1.9.25
    implementation(platform("com.google.firebase:firebase-bom:32.8.1"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-analytics")
}
