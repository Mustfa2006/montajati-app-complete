import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// خدمة اختبار رفع الصور المستقلة
class ImageUploadTestService {
  static final SupabaseClient _supabase = SupabaseConfig.client;
  static const String _bucketName = 'product-images';

  /// اختبار رفع صورة تجريبية
  static Future<Map<String, dynamic>> testImageUpload() async {
    final results = <String, dynamic>{
      'success': false,
      'url': null,
      'error': null,
      'steps': <String>[],
    };

    try {
      results['steps'].add('🔄 بدء اختبار رفع الصورة...');
      debugPrint('🔄 بدء اختبار رفع الصورة...');

      // إنشاء بيانات صورة تجريبية (1x1 pixel PNG)
      final testImageData = _createTestImageData();
      final fileName = 'test_image_${DateTime.now().millisecondsSinceEpoch}.png';

      results['steps'].add('📝 إنشاء ملف تجريبي: $fileName');
      debugPrint('📝 إنشاء ملف تجريبي: $fileName');

      // محاولة رفع الصورة
      results['steps'].add('📤 محاولة رفع الصورة...');
      debugPrint('📤 محاولة رفع الصورة...');

      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(fileName, testImageData);

      results['steps'].add('✅ تم رفع الصورة بنجاح');
      debugPrint('✅ تم رفع الصورة بنجاح');

      // الحصول على الرابط العام
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fileName);

      results['success'] = true;
      results['url'] = publicUrl;
      results['steps'].add('🔗 تم الحصول على الرابط: $publicUrl');
      debugPrint('🔗 تم الحصول على الرابط: $publicUrl');

      // محاولة حذف الملف التجريبي
      try {
        await _supabase.storage.from(_bucketName).remove([fileName]);
        results['steps'].add('🗑️ تم حذف الملف التجريبي');
        debugPrint('🗑️ تم حذف الملف التجريبي');
      } catch (deleteError) {
        results['steps'].add('⚠️ فشل في حذف الملف التجريبي: $deleteError');
        debugPrint('⚠️ فشل في حذف الملف التجريبي: $deleteError');
      }

    } catch (e) {
      results['error'] = e.toString();
      results['steps'].add('❌ فشل في رفع الصورة: $e');
      debugPrint('❌ فشل في رفع الصورة: $e');
    }

    return results;
  }

  /// اختبار رفع صورة حقيقية من XFile
  static Future<Map<String, dynamic>> testRealImageUpload(XFile imageFile) async {
    final results = <String, dynamic>{
      'success': false,
      'url': null,
      'error': null,
      'steps': <String>[],
      'file_info': <String, dynamic>{},
    };

    try {
      results['steps'].add('🔄 بدء اختبار رفع صورة حقيقية...');
      debugPrint('🔄 بدء اختبار رفع صورة حقيقية...');

      // معلومات الملف
      final fileSize = await imageFile.length();
      results['file_info'] = {
        'name': imageFile.name,
        'path': imageFile.path,
        'size': fileSize,
        'size_mb': (fileSize / (1024 * 1024)).toStringAsFixed(2),
      };

      results['steps'].add('📋 معلومات الملف:');
      results['steps'].add('   - الاسم: ${imageFile.name}');
      results['steps'].add('   - الحجم: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
      
      debugPrint('📋 معلومات الملف:');
      debugPrint('   - الاسم: ${imageFile.name}');
      debugPrint('   - الحجم: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');

      // التحقق من حجم الملف
      if (fileSize > 50 * 1024 * 1024) { // 50MB
        throw Exception('حجم الملف كبير جداً: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
      }

      // التحقق من نوع الملف
      if (!_isValidImageType(imageFile.name)) {
        throw Exception('نوع الملف غير مدعوم: ${imageFile.name}');
      }

      // قراءة بيانات الصورة
      results['steps'].add('📖 قراءة بيانات الصورة...');
      debugPrint('📖 قراءة بيانات الصورة...');

      final imageBytes = await imageFile.readAsBytes();
      
      // إنشاء اسم فريد
      final fileName = 'real_${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      
      results['steps'].add('📝 اسم الملف الجديد: $fileName');
      debugPrint('📝 اسم الملف الجديد: $fileName');

      // رفع الصورة
      results['steps'].add('📤 رفع الصورة...');
      debugPrint('📤 رفع الصورة...');

      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(fileName, imageBytes);

      results['steps'].add('✅ تم رفع الصورة بنجاح');
      debugPrint('✅ تم رفع الصورة بنجاح');

      // الحصول على الرابط العام
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fileName);

      results['success'] = true;
      results['url'] = publicUrl;
      results['steps'].add('🔗 الرابط العام: $publicUrl');
      debugPrint('🔗 الرابط العام: $publicUrl');

    } catch (e) {
      results['error'] = e.toString();
      results['steps'].add('❌ فشل في رفع الصورة: $e');
      debugPrint('❌ فشل في رفع الصورة: $e');
    }

    return results;
  }

  /// إنشاء بيانات صورة تجريبية (1x1 pixel PNG)
  static Uint8List _createTestImageData() {
    // PNG header + 1x1 transparent pixel
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, // IHDR chunk size
      0x49, 0x48, 0x44, 0x52, // IHDR
      0x00, 0x00, 0x00, 0x01, // width: 1
      0x00, 0x00, 0x00, 0x01, // height: 1
      0x08, 0x06, 0x00, 0x00, 0x00, // bit depth, color type, compression, filter, interlace
      0x1F, 0x15, 0xC4, 0x89, // CRC
      0x00, 0x00, 0x00, 0x0A, // IDAT chunk size
      0x49, 0x44, 0x41, 0x54, // IDAT
      0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, // compressed data
      0xE2, 0x21, 0xBC, 0x33, // CRC
      0x00, 0x00, 0x00, 0x00, // IEND chunk size
      0x49, 0x45, 0x4E, 0x44, // IEND
      0xAE, 0x42, 0x60, 0x82, // CRC
    ]);
  }

  /// التحقق من نوع الصورة
  static bool _isValidImageType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// طباعة تقرير مفصل
  static void printTestReport(Map<String, dynamic> results) {
    debugPrint('\n${'=' * 50}');
    debugPrint('📊 تقرير اختبار رفع الصور');
    debugPrint('=' * 50);

    debugPrint('🎯 النتيجة: ${results['success'] ? '✅ نجح' : '❌ فشل'}');
    
    if (results['url'] != null) {
      debugPrint('🔗 الرابط: ${results['url']}');
    }
    
    if (results['error'] != null) {
      debugPrint('❌ الخطأ: ${results['error']}');
    }

    if (results['file_info'] != null) {
      final info = results['file_info'] as Map<String, dynamic>;
      debugPrint('📋 معلومات الملف:');
      debugPrint('   - الاسم: ${info['name']}');
      debugPrint('   - الحجم: ${info['size_mb']} MB');
    }

    debugPrint('\n📝 خطوات التنفيذ:');
    for (final step in results['steps']) {
      debugPrint('   $step');
    }

    debugPrint('=' * 50 + '\n');
  }
}
