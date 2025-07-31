
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// خدمة اختبار شاملة لـ Supabase
class SupabaseTestService {
  static final SupabaseClient _supabase = SupabaseConfig.client;

  /// اختبار شامل لجميع جوانب Supabase
  static Future<Map<String, dynamic>> runCompleteTest() async {
    final results = <String, dynamic>{
      'connection': false,
      'database': false,
      'storage': false,
      'bucket_exists': false,
      'bucket_permissions': false,
      'upload_test': false,
      'errors': <String>[],
      'details': <String, dynamic>{},
    };

    debugPrint('🔍 بدء اختبار Supabase الشامل...');

    try {
      // 1. اختبار الاتصال الأساسي
      debugPrint('📡 اختبار الاتصال الأساسي...');
      try {
        await _supabase.rest
            .from('products')
            .select('count')
            .limit(1);
        results['connection'] = true;
        results['database'] = true;
        debugPrint('✅ الاتصال بقاعدة البيانات ناجح');
      } catch (e) {
        results['errors'].add('فشل الاتصال بقاعدة البيانات: $e');
        debugPrint('❌ فشل الاتصال بقاعدة البيانات: $e');
      }

      // 2. اختبار Storage
      debugPrint('🗂️ اختبار Storage...');
      try {
        final buckets = await _supabase.storage.listBuckets();
        results['storage'] = true;
        results['details']['buckets'] = buckets.map((b) => b.name).toList();
        debugPrint('✅ الاتصال بـ Storage ناجح');
        debugPrint(
          '📁 Buckets الموجودة: ${buckets.map((b) => b.name).join(', ')}',
        );
      } catch (e) {
        results['errors'].add('فشل الاتصال بـ Storage: $e');
        debugPrint('❌ فشل الاتصال بـ Storage: $e');
      }

      // 3. اختبار bucket محدد
      debugPrint('🪣 اختبار bucket المنتجات...');
      try {
        final bucket = await _supabase.storage.getBucket('product-images');
        results['bucket_exists'] = true;
        results['details']['bucket_info'] = {
          'id': bucket.id,
          'name': bucket.name,
          'public': bucket.public,
          'file_size_limit': bucket.fileSizeLimit,
          'allowed_mime_types': bucket.allowedMimeTypes,
        };
        debugPrint('✅ Bucket موجود: ${bucket.name}');
        debugPrint('🔓 عام: ${bucket.public}');
        debugPrint('📏 حد الحجم: ${bucket.fileSizeLimit} بايت');
      } catch (e) {
        results['errors'].add('Bucket غير موجود: $e');
        debugPrint('❌ Bucket غير موجود: $e');
      }

      // 4. اختبار صلاحيات bucket
      if (results['bucket_exists']) {
        debugPrint('🔐 اختبار صلاحيات bucket...');
        try {
          final files = await _supabase.storage.from('product-images').list();
          results['bucket_permissions'] = true;
          results['details']['files_count'] = files.length;
          debugPrint('✅ يمكن قراءة محتويات bucket: ${files.length} ملف');
        } catch (e) {
          results['errors'].add('فشل في قراءة محتويات bucket: $e');
          debugPrint('❌ فشل في قراءة محتويات bucket: $e');
        }
      }

      // 5. اختبار رفع ملف تجريبي
      if (results['bucket_permissions']) {
        debugPrint('📤 اختبار رفع ملف تجريبي...');
        try {
          final testData =
              'test-image-data-${DateTime.now().millisecondsSinceEpoch}';
          final fileName = 'test_${DateTime.now().millisecondsSinceEpoch}.txt';

          await _supabase.storage
              .from('product-images')
              .uploadBinary(fileName, Uint8List.fromList(testData.codeUnits));

          results['upload_test'] = true;
          debugPrint('✅ رفع الملف التجريبي ناجح');

          // محاولة حذف الملف التجريبي
          try {
            await _supabase.storage.from('product-images').remove([fileName]);
            debugPrint('✅ حذف الملف التجريبي ناجح');
          } catch (e) {
            debugPrint('⚠️ فشل في حذف الملف التجريبي: $e');
          }
        } catch (e) {
          results['errors'].add('فشل في رفع الملف التجريبي: $e');
          debugPrint('❌ فشل في رفع الملف التجريبي: $e');
        }
      }
    } catch (e) {
      results['errors'].add('خطأ عام في الاختبار: $e');
      debugPrint('❌ خطأ عام في الاختبار: $e');
    }

    return results;
  }

  /// طباعة تقرير مفصل
  static void printDetailedReport(Map<String, dynamic> results) {
    debugPrint('\n${'=' * 60}');
    debugPrint('📊 تقرير اختبار Supabase الشامل');
    debugPrint('=' * 60);

    debugPrint('🔗 الاتصال: ${results['connection'] ? '✅' : '❌'}');
    debugPrint('🗄️ قاعدة البيانات: ${results['database'] ? '✅' : '❌'}');
    debugPrint('🗂️ Storage: ${results['storage'] ? '✅' : '❌'}');
    debugPrint('🪣 Bucket موجود: ${results['bucket_exists'] ? '✅' : '❌'}');
    debugPrint(
      '🔐 صلاحيات Bucket: ${results['bucket_permissions'] ? '✅' : '❌'}',
    );
    debugPrint('📤 اختبار الرفع: ${results['upload_test'] ? '✅' : '❌'}');

    if (results['details']['bucket_info'] != null) {
      final info = results['details']['bucket_info'] as Map<String, dynamic>;
      debugPrint('\n📋 معلومات Bucket:');
      debugPrint('   - الاسم: ${info['name']}');
      debugPrint('   - عام: ${info['public']}');
      debugPrint('   - حد الحجم: ${info['file_size_limit']} بايت');
      debugPrint('   - أنواع الملفات: ${info['allowed_mime_types']}');
    }

    if (results['errors'].isNotEmpty) {
      debugPrint('\n❌ الأخطاء:');
      for (final error in results['errors']) {
        debugPrint('   - $error');
      }
    }

    final allWorking =
        results['connection'] &&
        results['database'] &&
        results['storage'] &&
        results['bucket_exists'] &&
        results['bucket_permissions'] &&
        results['upload_test'];

    debugPrint(
      '\n🎯 النتيجة النهائية: ${allWorking ? '✅ جميع الاختبارات نجحت' : '❌ بعض الاختبارات فشلت'}',
    );
    debugPrint('=' * 60 + '\n');
  }

  /// إنشاء bucket إذا لم يكن موجوداً
  static Future<bool> createBucketIfNeeded() async {
    try {
      debugPrint('🔍 التحقق من وجود bucket...');
      await _supabase.storage.getBucket('product-images');
      debugPrint('✅ Bucket موجود بالفعل');
      return true;
    } catch (e) {
      debugPrint('⚠️ Bucket غير موجود، محاولة إنشاؤه...');

      try {
        await _supabase.storage.createBucket(
          'product-images',
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

        // محاولة أخيرة للتحقق من وجود bucket
        try {
          await _supabase.storage.getBucket('product-images');
          debugPrint('✅ Bucket موجود (تحقق أخير)');
          return true;
        } catch (_) {
          return false;
        }
      }
    }
  }
}
