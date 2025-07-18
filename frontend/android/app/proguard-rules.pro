# قواعد ProGuard لتطبيق منتجاتي

# إبقاء Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# إبقاء Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# إبقاء Supabase classes
-keep class io.supabase.** { *; }

# إبقاء HTTP classes
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# إبقاء JSON classes
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# إبقاء model classes
-keep class com.montajati.app.models.** { *; }

# تجنب تحذيرات
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
