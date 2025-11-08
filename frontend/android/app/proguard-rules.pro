# قواعد ProGuard محسنة لتطبيق منتجاتي
# تم تحديثها لحل تحذيرات R8

# إبقاء Flutter classes الأساسية فقط
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }



# إبقاء JSON وHTTP classes المستخدمة
-keep class com.google.gson.** { *; }
-keep class okhttp3.internal.** { *; }
-keep class retrofit2.converter.gson.** { *; }

# إبقاء Supabase classes المستخدمة
-keep class io.supabase.gotrue.** { *; }
-keep class io.supabase.postgrest.** { *; }
-keep class io.supabase.realtime.** { *; }

# إبقاء model classes التطبيق
-keep class com.montajati.app.** { *; }

# إبقاء attributes مهمة
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# تجنب تحذيرات للمكتبات الخارجية
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn kotlin.reflect.**
-dontwarn kotlinx.coroutines.**
-dontwarn org.slf4j.**

# قواعد خاصة بـ Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# قواعد خاصة بـ AndroidX
-keep class androidx.lifecycle.** { *; }
-keep class androidx.work.** { *; }

# تجنب تحذيرات R8 المحددة
-dontwarn com.google.vending.licensing.ILicensingService
-dontwarn com.android.vending.licensing.ILicensingService
-dontwarn com.google.android.vending.licensing.ILicensingService

# حل مشكلة Missing EnclosingMethod
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes Signature

# قواعد خاصة لحل مشاكل Google Play Services
-keep class com.google.android.gms.measurement.internal.** { *; }
-dontwarn com.google.android.gms.measurement.internal.**

# قواعد للحفاظ على أداء التطبيق - مبسطة
-dontoptimize
-dontpreverify

# قواعد إضافية لتجنب التحذيرات
-dontwarn org.jetbrains.annotations.**
-dontwarn javax.lang.model.element.Modifier
