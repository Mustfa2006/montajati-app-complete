import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة اختبار Storage للتأكد من عمل رفع الصور
class StorageTestService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'product-images';

  /// اختبار شامل لـ Storage
  static Future<Map<String, dynamic>> runCompleteTest() async {
    final results = <String, dynamic>{
      'bucket_exists': false,
      'bucket_info': null,
      'can_list_files': false,
      'can_upload': false,
      'can_download': false,
      'can_delete': false,
      'errors': <String>[],
    };

    try {
      // 1. اختبار وجود bucket
      debugPrint('🔍 اختبار وجود bucket...');
      try {
        final bucket = await _supabase.storage.getBucket(_bucketName);
        results['bucket_exists'] = true;
        results['bucket_info'] = {
          'id': bucket.id,
          'name': bucket.name,
          'public': bucket.public,
          'file_size_limit': bucket.fileSizeLimit,
          'allowed_mime_types': bucket.allowedMimeTypes,
        };
        debugPrint('✅ Bucket موجود: ${bucket.name}');
      } catch (e) {
        results['errors'].add('Bucket غير موجود: $e');
        debugPrint('❌ Bucket غير موجود: $e');
      }

      // 2. اختبار قائمة الملفات
      debugPrint('🔍 اختبار قائمة الملفات...');
      try {
        final files = await _supabase.storage.from(_bucketName).list();
        results['can_list_files'] = true;
        debugPrint('✅ يمكن قراءة قائمة الملفات: ${files.length} ملف');
      } catch (e) {
        results['errors'].add('فشل في قراءة قائمة الملفات: $e');
        debugPrint('❌ فشل في قراءة قائمة الملفات: $e');
      }

      // 3. اختبار رفع ملف تجريبي
      debugPrint('🔍 اختبار رفع ملف تجريبي...');
      try {
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]); // بيانات تجريبية
        final fileName = 'test_${DateTime.now().millisecondsSinceEpoch}.txt';

        await _supabase.storage
            .from(_bucketName)
            .uploadBinary(fileName, testData);

        results['can_upload'] = true;
        debugPrint('✅ تم رفع الملف التجريبي بنجاح');

        // 4. اختبار تحميل الملف
        debugPrint('🔍 اختبار تحميل الملف...');
        try {
          final downloadedData = await _supabase.storage
              .from(_bucketName)
              .download(fileName);

          results['can_download'] = true;
          debugPrint('✅ تم تحميل الملف بنجاح: ${downloadedData.length} بايت');
        } catch (e) {
          results['errors'].add('فشل في تحميل الملف: $e');
          debugPrint('❌ فشل في تحميل الملف: $e');
        }

        // 5. اختبار حذف الملف
        debugPrint('🔍 اختبار حذف الملف...');
        try {
          await _supabase.storage.from(_bucketName).remove([fileName]);
          results['can_delete'] = true;
          debugPrint('✅ تم حذف الملف التجريبي بنجاح');
        } catch (e) {
          results['errors'].add('فشل في حذف الملف: $e');
          debugPrint('❌ فشل في حذف الملف: $e');
        }
      } catch (e) {
        results['errors'].add('فشل في رفع الملف التجريبي: $e');
        debugPrint('❌ فشل في رفع الملف التجريبي: $e');
      }
    } catch (e) {
      results['errors'].add('خطأ عام في الاختبار: $e');
      debugPrint('❌ خطأ عام في الاختبار: $e');
    }

    return results;
  }

  /// اختبار إنشاء bucket إذا لم يكن موجوداً
  static Future<bool> createBucketIfNotExists() async {
    try {
      // محاولة الحصول على bucket
      await _supabase.storage.getBucket(_bucketName);
      debugPrint('✅ Bucket موجود بالفعل');
      return true;
    } catch (e) {
      debugPrint('⚠️ Bucket غير موجود، محاولة إنشاؤه...');

      try {
        // إنشاء bucket جديد
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
        debugPrint('✅ تم إنشاء bucket بنجاح');
        return true;
      } catch (createError) {
        debugPrint('❌ فشل في إنشاء bucket: $createError');
        return false;
      }
    }
  }

  /// طباعة تقرير مفصل عن حالة Storage
  static void printDetailedReport(Map<String, dynamic> results) {
    debugPrint('\n${'=' * 50}');
    debugPrint('📊 تقرير اختبار Storage المفصل');
    debugPrint('=' * 50);

    debugPrint('🗂️ حالة Bucket:');
    debugPrint('   - موجود: ${results['bucket_exists']}');
    if (results['bucket_info'] != null) {
      final info = results['bucket_info'] as Map<String, dynamic>;
      debugPrint('   - الاسم: ${info['name']}');
      debugPrint('   - عام: ${info['public']}');
      debugPrint('   - حد الحجم: ${info['file_size_limit']} بايت');
      debugPrint('   - أنواع الملفات المسموحة: ${info['allowed_mime_types']}');
    }

    debugPrint('\n🔧 الصلاحيات:');
    debugPrint('   - قراءة الملفات: ${results['can_list_files']}');
    debugPrint('   - رفع الملفات: ${results['can_upload']}');
    debugPrint('   - تحميل الملفات: ${results['can_download']}');
    debugPrint('   - حذف الملفات: ${results['can_delete']}');

    if (results['errors'].isNotEmpty) {
      debugPrint('\n❌ الأخطاء:');
      for (final error in results['errors']) {
        debugPrint('   - $error');
      }
    }

    final allWorking =
        results['bucket_exists'] &&
        results['can_list_files'] &&
        results['can_upload'] &&
        results['can_download'] &&
        results['can_delete'];

    debugPrint(
      '\n🎯 النتيجة النهائية: ${allWorking ? "✅ جميع الاختبارات نجحت" : "❌ بعض الاختبارات فشلت"}',
    );
    debugPrint('=' * 50 + '\n');
  }
}
