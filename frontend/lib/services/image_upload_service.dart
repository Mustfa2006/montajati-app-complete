import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadService {
  static final _supabase = Supabase.instance.client;
  static const String _bucketName = 'product-images';

  /// رفع صورة واحدة إلى Supabase Storage
  static Future<String?> uploadSingleImage(XFile imageFile) async {
    try {
      // التأكد من وجود bucket أولاً
      await _ensureBucketExists();

      // قراءة بيانات الصورة
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // إنشاء اسم فريد للصورة
      final String fileName =
          'product_${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';

      // رفع الصورة إلى Supabase Storage
      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(fileName, imageBytes);

      // الحصول على الرابط العام للصورة
      final String publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fileName);

      debugPrint('✅ تم رفع الصورة بنجاح: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ خطأ في رفع الصورة: $e');

      // محاولة إنشاء bucket وإعادة المحاولة
      try {
        debugPrint('🔄 محاولة إنشاء bucket وإعادة الرفع...');
        await _createBucketAndRetry();

        // إعادة المحاولة
        final Uint8List imageBytes = await imageFile.readAsBytes();
        final String fileName =
            'product_${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';

        await _supabase.storage
            .from(_bucketName)
            .uploadBinary(fileName, imageBytes);

        final String publicUrl = _supabase.storage
            .from(_bucketName)
            .getPublicUrl(fileName);

        debugPrint('✅ تم رفع الصورة بنجاح (المحاولة الثانية): $publicUrl');
        return publicUrl;
      } catch (retryError) {
        debugPrint('❌ فشل في المحاولة الثانية: $retryError');
        return null;
      }
    }
  }

  /// رفع عدة صور إلى Supabase Storage
  static Future<List<String>> uploadMultipleImages(
    List<XFile> imageFiles,
  ) async {
    final List<String> uploadedUrls = [];

    for (final imageFile in imageFiles) {
      final String? url = await uploadSingleImage(imageFile);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }

  /// حذف صورة من Supabase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // استخراج اسم الملف من الرابط
      final Uri uri = Uri.parse(imageUrl);
      final String fileName = uri.pathSegments.last;

      // حذف الصورة من Storage
      await _supabase.storage.from(_bucketName).remove([fileName]);

      debugPrint('✅ تم حذف الصورة بنجاح: $fileName');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حذف الصورة: $e');
      return false;
    }
  }

  /// التحقق من وجود bucket وإنشاؤه إذا لم يكن موجوداً
  static Future<bool> ensureBucketExists() async {
    try {
      // محاولة الحصول على معلومات الـ bucket
      await _supabase.storage.getBucket(_bucketName);
      debugPrint('✅ Bucket موجود: $_bucketName');
      return true;
    } catch (e) {
      debugPrint('⚠️ Bucket غير موجود، محاولة إنشاؤه: $e');

      try {
        // إنشاء bucket جديد إذا لم يكن موجوداً
        await _supabase.storage.createBucket(
          _bucketName,
          BucketOptions(
            public: true,
            allowedMimeTypes: [
              'image/jpeg',
              'image/png',
              'image/webp',
              'image/gif',
            ],
            fileSizeLimit: '52428800', // 50MB
          ),
        );
        debugPrint('✅ تم إنشاء bucket جديد: $_bucketName');
        return true;
      } catch (createError) {
        debugPrint('❌ خطأ في إنشاء bucket: $createError');

        // محاولة أخيرة - التحقق من وجود bucket مرة أخرى
        try {
          await _supabase.storage.getBucket(_bucketName);
          debugPrint('✅ Bucket موجود الآن');
          return true;
        } catch (finalError) {
          debugPrint('❌ فشل نهائي في الوصول للـ bucket: $finalError');
          return false;
        }
      }
    }
  }

  /// ضغط الصورة قبل الرفع (اختياري)
  static Future<Uint8List> compressImage(Uint8List imageBytes) async {
    // يمكن إضافة مكتبة ضغط الصور هنا مثل flutter_image_compress
    // لكن الآن سنرجع الصورة كما هي
    return imageBytes;
  }

  /// التحقق من صحة نوع الصورة
  static bool isValidImageType(String fileName) {
    final String extension = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'webp'].contains(extension);
  }

  /// التحقق من حجم الصورة
  static bool isValidImageSize(int sizeInBytes) {
    const int maxSize = 5 * 1024 * 1024; // 5MB
    return sizeInBytes <= maxSize;
  }

  /// رفع صورة مع التحقق من الصحة
  static Future<String?> uploadImageWithValidation(XFile imageFile) async {
    try {
      debugPrint('🔄 بدء رفع الصورة: ${imageFile.name}');

      // إذا كانت الصورة رابط، أرجعها مباشرة
      if (imageFile.path.startsWith('http')) {
        debugPrint('✅ استخدام رابط الصورة مباشرة: ${imageFile.path}');
        return imageFile.path;
      }

      // التحقق من نوع الصورة
      if (!isValidImageType(imageFile.name)) {
        debugPrint('❌ نوع الصورة غير مدعوم: ${imageFile.name}');
        return null;
      }

      // التحقق من حجم الصورة
      final int fileSize = await imageFile.length();
      if (!isValidImageSize(fileSize)) {
        debugPrint('❌ حجم الصورة كبير جداً: ${fileSize / (1024 * 1024)} MB');
        return null;
      }

      // التأكد من وجود bucket
      final bucketExists = await ensureBucketExists();
      if (!bucketExists) {
        debugPrint('❌ فشل في إنشاء أو الوصول للـ bucket');
        return null;
      }

      // رفع الصورة
      final result = await uploadSingleImage(imageFile);
      debugPrint('✅ تم رفع الصورة بنجاح: $result');
      return result;
    } catch (e) {
      debugPrint('❌ خطأ في رفع الصورة مع التحقق: $e');
      return null;
    }
  }

  /// دالة مساعدة للتأكد من وجود bucket
  static Future<void> _ensureBucketExists() async {
    await ensureBucketExists();
  }

  /// دالة مساعدة لإنشاء bucket وإعادة المحاولة
  static Future<void> _createBucketAndRetry() async {
    await ensureBucketExists();
  }
}
