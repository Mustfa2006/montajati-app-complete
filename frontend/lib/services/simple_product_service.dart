import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'smart_inventory_manager.dart';

/// خدمة بسيطة لإضافة المنتجات بدون تعقيدات
class SimpleProductService {
  static final _supabase = Supabase.instance.client;
  static const String _bucketName = 'product-images';

  /// الحصول على رقم هاتف المستخدم الحالي
  static Future<String?> _getCurrentUserPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('current_user_phone');
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على رقم هاتف المستخدم: $e');
      return null;
    }
  }

  /// إضافة منتج جديد بطريقة مبسطة
  static Future<Map<String, dynamic>> addProduct({
    required String name,
    required String description,
    required double wholesalePrice,
    required double minPrice,
    required double maxPrice,
    required List<XFile> images,
    String category = 'عام',
    int stockQuantity = 100,
    int availableFrom = 90,
    int availableTo = 80,
    List<String>? notificationTags, // 🎯 إضافة دعم التبليغات الذكية
  }) async {
    try {
      debugPrint('🚀 بدء إضافة المنتج: $name');

      // 1. رفع الصور أولاً
      List<String> imageUrls = [];

      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        debugPrint('📤 رفع الصورة ${i + 1}/${images.length}: ${image.name}');

        try {
          final imageUrl = await _uploadImage(image);
          if (imageUrl != null) {
            imageUrls.add(imageUrl);
            debugPrint('✅ تم رفع الصورة ${i + 1}: $imageUrl');
          } else {
            debugPrint('⚠️ فشل في رفع الصورة ${i + 1}');
          }
        } catch (e) {
          debugPrint('❌ خطأ في رفع الصورة ${i + 1}: $e');
        }
      }

      // إذا لم يتم رفع أي صورة، استخدم صورة افتراضية
      if (imageUrls.isEmpty) {
        imageUrls.add(
          'https://via.placeholder.com/400x300/1a1a2e/ffd700?text=منتج+جديد',
        );
        debugPrint('⚠️ لم يتم رفع أي صورة، استخدام صورة افتراضية');
      }

      // 2. إضافة المنتج باستخدام النظام الذكي للمخزون
      debugPrint('🧠 إضافة المنتج باستخدام النظام الذكي...');

      // الحصول على رقم هاتف المستخدم
      final userPhone = await _getCurrentUserPhone();
      if (userPhone == null) {
        throw Exception('لم يتم العثور على رقم هاتف المستخدم');
      }

      // استخدام النظام الذكي لإضافة المنتج
      final result = await SmartInventoryManager.addProductWithSmartInventory(
        name: name,
        description: description,
        wholesalePrice: wholesalePrice,
        minPrice: minPrice,
        maxPrice: maxPrice,
        totalQuantity: stockQuantity,
        category: category,
        userPhone: userPhone,
        images: imageUrls,
        notificationTags: notificationTags, // 🎯 تمرير التبليغات الذكية
      );

      if (!result['success']) {
        throw Exception(result['message']);
      }

      final response = result['product'];
      debugPrint('✅ تم إضافة المنتج بالنظام الذكي: ${response['id']}');
      debugPrint('🎯 النطاق الذكي: ${result['smart_range']}');

      return {
        'success': true,
        'message': 'تم إضافة المنتج بنجاح',
        'product': response,
        'product_id': response['id'], // إضافة معرف المنتج للاستخدام مع الألوان
        'uploaded_images': imageUrls.length,
      };
    } catch (e) {
      debugPrint('❌ خطأ مفصل في إضافة المنتج: $e');

      // معالجة أخطاء قاعدة البيانات المختلفة
      String errorMessage = 'فشل في إضافة المنتج';

      if (e.toString().contains('column') &&
          e.toString().contains('does not exist')) {
        errorMessage = 'خطأ في هيكل قاعدة البيانات - يرجى تحديث قاعدة البيانات';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'ليس لديك صلاحية لإضافة المنتجات';
      } else if (e.toString().contains('network')) {
        errorMessage = 'مشكلة في الاتصال بالإنترنت';
      } else if (e.toString().contains('storage')) {
        errorMessage = 'فشل في رفع الصور';
      }

      return {
        'success': false,
        'message': errorMessage,
        'error': e.toString(),
        'debug_info': 'خطأ في إضافة المنتج للقاعدة',
      };
    }
  }

  /// رفع صورة واحدة
  static Future<String?> _uploadImage(XFile imageFile) async {
    try {
      // التأكد من وجود bucket
      await _ensureBucket();

      // قراءة بيانات الصورة
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // إنشاء اسم فريد للصورة
      final String fileName =
          'product_${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';

      // رفع الصورة
      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(fileName, imageBytes);

      // الحصول على الرابط العام
      final String publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint('❌ خطأ في رفع الصورة: $e');
      return null;
    }
  }

  /// التأكد من وجود bucket
  static Future<void> _ensureBucket() async {
    try {
      // محاولة الحصول على bucket
      await _supabase.storage.getBucket(_bucketName);
    } catch (e) {
      // إذا لم يكن موجود، أنشئه
      try {
        await _supabase.storage.createBucket(
          _bucketName,
          const BucketOptions(
            public: true,
            allowedMimeTypes: [
              'image/jpeg',
              'image/jpg',
              'image/png',
              'image/gif',
              'image/webp',
            ],
            fileSizeLimit: '52428800', // 50MB
          ),
        );
        debugPrint('✅ تم إنشاء bucket جديد');
      } catch (createError) {
        debugPrint('⚠️ خطأ في إنشاء bucket: $createError');
        // المتابعة حتى لو فشل إنشاء bucket
      }
    }
  }
}
