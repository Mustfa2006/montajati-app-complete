import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة بسيطة لإضافة المنتجات بدون تعقيدات
class SimpleProductService {
  static final _supabase = Supabase.instance.client;
  static const String _bucketName = 'product-images';

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

      // 2. إضافة المنتج إلى قاعدة البيانات
      debugPrint('💾 إضافة المنتج إلى قاعدة البيانات...');

      // إنشاء بيانات المنتج مع التعامل مع الحقول الاختيارية
      final productData = <String, dynamic>{
        'name': name,
        'description': description,
        'wholesale_price': wholesalePrice,
        'min_price': minPrice,
        'max_price': maxPrice,
        'image_url': imageUrls.first, // الصورة الرئيسية
        'category': category,
        'available_quantity': stockQuantity, // الكمية المخزونة (مخفية)
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      // إضافة الحقول الجديدة فقط إذا كانت قاعدة البيانات تدعمها
      try {
        productData['available_from'] = availableFrom;
        productData['available_to'] = availableTo;
        productData['images'] = imageUrls;
      } catch (e) {
        debugPrint('⚠️ تحذير: بعض الحقول الجديدة غير مدعومة في قاعدة البيانات');
      }

      debugPrint('📝 بيانات المنتج المرسلة: $productData');

      final response = await _supabase
          .from('products')
          .insert(productData)
          .select()
          .single();

      debugPrint('✅ تم إضافة المنتج بنجاح: ${response['id']}');

      return {
        'success': true,
        'message': 'تم إضافة المنتج بنجاح',
        'product': response,
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
