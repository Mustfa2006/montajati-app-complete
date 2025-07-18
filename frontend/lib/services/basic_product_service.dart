import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة أساسية لإضافة المنتجات بدون الحقول الجديدة
class BasicProductService {
  static final _supabase = Supabase.instance.client;
  static const String _bucketName = 'product-images';

  /// إضافة منتج جديد بطريقة أساسية (بدون الحقول الجديدة)
  static Future<Map<String, dynamic>> addProduct({
    required String name,
    required String description,
    required double wholesalePrice,
    required double minPrice,
    required double maxPrice,
    required List<XFile> images,
    String category = 'عام',
    int stockQuantity = 100,
  }) async {
    try {
      debugPrint('🚀 بدء إضافة المنتج: $name');

      // 1. رفع الصور أولاً
      List<String> imageUrls = [];
      
      if (images.isNotEmpty) {
        debugPrint('📸 رفع ${images.length} صورة...');
        
        for (int i = 0; i < images.length; i++) {
          final imageFile = images[i];
          debugPrint('📤 رفع الصورة ${i + 1}/${images.length}');
          
          final imageUrl = await _uploadImage(imageFile);
          if (imageUrl != null) {
            imageUrls.add(imageUrl);
            debugPrint('✅ تم رفع الصورة ${i + 1}: $imageUrl');
          } else {
            debugPrint('❌ فشل في رفع الصورة ${i + 1}');
          }
        }
      }

      if (imageUrls.isEmpty) {
        // استخدام صورة افتراضية إذا فشل رفع جميع الصور
        imageUrls.add('https://picsum.photos/400/400?random=${DateTime.now().millisecondsSinceEpoch}');
        debugPrint('⚠️ استخدام صورة افتراضية');
      }

      debugPrint('📊 تم رفع ${imageUrls.length} صورة بنجاح');

      // 2. إضافة المنتج إلى قاعدة البيانات (الحقول الأساسية فقط)
      debugPrint('💾 إضافة المنتج إلى قاعدة البيانات...');

      final productData = <String, dynamic>{
        'name': name,
        'description': description,
        'wholesale_price': wholesalePrice,
        'min_price': minPrice,
        'max_price': maxPrice,
        'image_url': imageUrls.first, // الصورة الرئيسية
        'category': category,
        'available_quantity': stockQuantity,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      debugPrint('📝 بيانات المنتج: $productData');

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
      debugPrint('❌ خطأ في إضافة المنتج: $e');
      
      // معالجة أخطاء مختلفة
      String errorMessage = 'فشل في إضافة المنتج';
      
      if (e.toString().contains('permission')) {
        errorMessage = 'ليس لديك صلاحية لإضافة المنتجات';
      } else if (e.toString().contains('network')) {
        errorMessage = 'مشكلة في الاتصال بالإنترنت';
      } else if (e.toString().contains('storage')) {
        errorMessage = 'فشل في رفع الصور';
      } else if (e.toString().contains('duplicate')) {
        errorMessage = 'اسم المنتج موجود مسبقاً';
      }
      
      return {
        'success': false,
        'message': errorMessage,
        'error': e.toString(),
      };
    }
  }

  /// رفع صورة واحدة
  static Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      
      debugPrint('📤 رفع الصورة: $fileName');
      
      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(fileName, bytes);
      
      final imageUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fileName);
      
      debugPrint('✅ تم رفع الصورة: $imageUrl');
      return imageUrl;
      
    } catch (e) {
      debugPrint('❌ خطأ في رفع الصورة: $e');
      return null;
    }
  }
}
