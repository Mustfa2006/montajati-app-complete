# قواعد R8 إضافية لحل التحذيرات
# R8 Additional Rules for Warning Resolution

# تجنب تحذيرات Google Play Services
-dontwarn com.google.vending.licensing.ILicensingService
-dontwarn com.android.vending.licensing.ILicensingService
-dontwarn com.google.android.vending.licensing.ILicensingService

# تجنب تحذيرات JavaScript Interface
-dontwarn android.webkit.JavascriptInterface

# تجنب تحذيرات Support Annotations
-dontwarn android.support.annotation.Keep

# قواعد خاصة بـ Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# قواعد خاصة بـ Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**

# قواعد خاصة بـ OkHttp
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# قواعد خاصة بـ Gson
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# قواعد خاصة بـ AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# قواعد خاصة بـ Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# تجنب تحذيرات عامة
-dontwarn javax.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn org.slf4j.**

# حفظ معلومات التصحيح المهمة
-keepattributes SourceFile,LineNumberTable
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes Signature
-keepattributes *Annotation*

# تحسين الأداء - مبسط لتجنب أخطاء R8
-dontoptimize
-dontpreverify

# قواعد خاصة بالتطبيق
-keep class com.montajati.app.** { *; }

# قواعد إضافية لحل مشاكل R8
-keep class * extends java.lang.Exception
-keep class * extends java.lang.Error
-keep class * extends java.lang.RuntimeException

# حفظ جميع الـ enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# حفظ الـ Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# قواعد خاصة بـ Supabase
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# قواعد خاصة بـ HTTP clients
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**
