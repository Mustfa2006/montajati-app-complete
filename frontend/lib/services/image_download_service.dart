// 🖼️ خدمة تحميل الصور
// مسؤول عن حفظ الصور للجهاز (ويب + موبايل)

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:universal_html/html.dart' as html;

/// نتيجة حفظ مجموعة صور
class ImagesSaveResult {
  final int successCount;
  final int failCount;
  final List<String> errors;

  ImagesSaveResult({
    required this.successCount,
    required this.failCount,
    this.errors = const [],
  });

  bool get isSuccess => failCount == 0;
  bool get hasPartialSuccess => successCount > 0 && failCount > 0;
}

/// خدمة تحميل وحفظ الصور
class ImageDownloadService {
  /// 💾 حفظ صورة واحدة
  Future<bool> saveSingleImage({
    required String imageUrl,
    required String fileName,
  }) async {
    try {
      if (kIsWeb) {
        return await _saveImageWeb(imageUrl, fileName);
      } else {
        return await _saveImageMobile(imageUrl, fileName);
      }
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الصورة: $e');
      return false;
    }
  }

  /// 🖼️ حفظ مجموعة صور
  Future<ImagesSaveResult> saveAllImages(List<String> imageUrls) async {
    int successCount = 0;
    int failCount = 0;
    final errors = <String>[];

    for (int i = 0; i < imageUrls.length; i++) {
      final url = imageUrls[i];
      final fileName = 'image_${i + 1}_${DateTime.now().millisecondsSinceEpoch}';

      try {
        final success = await saveSingleImage(imageUrl: url, fileName: fileName);
        if (success) {
          successCount++;
        } else {
          failCount++;
          errors.add('فشل في حفظ الصورة ${i + 1}');
        }
      } catch (e) {
        failCount++;
        errors.add('خطأ في الصورة ${i + 1}: $e');
      }
    }

    return ImagesSaveResult(
      successCount: successCount,
      failCount: failCount,
      errors: errors,
    );
  }

  /// 🌐 حفظ الصورة على الويب
  Future<bool> _saveImageWeb(String imageUrl, String fileName) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      // تحديد الامتداد والنوع
      final lower = imageUrl.toLowerCase();
      String ext = '.jpg';
      String mime = 'image/jpeg';
      if (lower.endsWith('.png')) {
        ext = '.png';
        mime = 'image/png';
      } else if (lower.endsWith('.webp')) {
        ext = '.webp';
        mime = 'image/webp';
      }

      final blob = html.Blob([response.bodyBytes], mime);
      final objUrl = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: objUrl)
        ..download = '$fileName$ext'
        ..style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(objUrl);

      return true;
    } catch (e) {
      // محاولة بديلة: فتح الرابط مباشرة
      try {
        final anchor = html.AnchorElement(href: imageUrl)
          ..download = fileName
          ..target = '_blank'
          ..rel = 'noopener'
          ..style.display = 'none';
        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
        return true;
      } catch (err) {
        debugPrint('❌ تعذّر تنزيل الصورة على الويب: $e / $err');
        return false;
      }
    }
  }

  /// 📱 حفظ الصورة على الموبايل
  Future<bool> _saveImageMobile(String imageUrl, String fileName) async {
    try {
      // طلب الصلاحيات
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('لا توجد صلاحية للوصول للتخزين');
      }

      // تحميل الصورة
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('فشل في تحميل الصورة');
      }

      // حفظ الصورة في الاستوديو
      final result = await SaverGallery.saveImage(
        response.bodyBytes,
        quality: 100,
        fileName: fileName,
        androidRelativePath: "Pictures/منتجاتي/images",
        skipIfExists: false,
      );

      if (result.isSuccess != true) {
        throw Exception('فشل في حفظ الصورة في الاستوديو');
      }

      debugPrint('✅ تم حفظ الصورة: $fileName');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الصورة: $e');
      return false;
    }
  }
}

