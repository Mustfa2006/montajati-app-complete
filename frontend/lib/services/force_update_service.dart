import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

/// خدمة التحديث الإجباري
class ForceUpdateService {
  static const String updateCheckUrl = 'https://montajati-official-backend-production.up.railway.app/api/notifications/app-version';
  
  /// فحص وجود تحديث
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // الحصول على معلومات التطبيق الحالي
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.parse(packageInfo.buildNumber);

      // إرسال رقم الإصدار الحالي للخادم
      final url = Uri.parse('$updateCheckUrl?build_number=$currentBuildNumber');
      final response = await http.get(url);

      debugPrint('🔍 فحص التحديث - الإصدار الحالي: $currentBuildNumber');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final serverBuildNumber = data['buildNumber'] as int;
        final downloadUrl = data['downloadUrl'] as String;
        final forceUpdate = data['forceUpdate'] as bool? ?? false;

        debugPrint('📊 إصدار الخادم: $serverBuildNumber, تحديث إجباري: $forceUpdate');

        // عرض نافذة التحديث فقط إذا كان هناك تحديث فعلي
        if (forceUpdate && serverBuildNumber > currentBuildNumber) {
          debugPrint('🚨 يوجد تحديث متاح - عرض نافذة التحديث');
          // التحقق من أن context ما زال صالحاً
          if (context.mounted) {
            _showForceUpdateDialog(context, downloadUrl);
          }
        } else {
          debugPrint('✅ التطبيق محدث - لا حاجة للتحديث');
          debugPrint('📊 تفاصيل: forceUpdate=$forceUpdate, serverBuild=$serverBuildNumber, currentBuild=$currentBuildNumber');
        }
      }
    } catch (e) {
      debugPrint('خطأ في فحص التحديث: $e');
    }
  }
  
  /// عرض شاشة التحديث الإجباري
  static void _showForceUpdateDialog(BuildContext context, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false, // لا يمكن إغلاقها
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // منع الإغلاق بزر الرجوع
          child: ForceUpdateDialog(downloadUrl: downloadUrl),
        );
      },
    );
  }
}

/// شاشة التحديث الإجباري
class ForceUpdateDialog extends StatefulWidget {
  final String downloadUrl;

  const ForceUpdateDialog({super.key, required this.downloadUrl});
  
  @override
  State<ForceUpdateDialog> createState() => _ForceUpdateDialogState();
}

class _ForceUpdateDialogState extends State<ForceUpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusText = '';
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة التحديث
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.system_update,
                size: 40,
                color: Colors.blue.shade700,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // العنوان
            Text(
              'يوجد تحديث جديد',
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // الوصف
            Text(
              'يرجى تحديث التطبيق للتمتع بأحدث المميزات',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 30),
            
            // شريط التقدم (يظهر أثناء التحميل)
            if (_isDownloading) ...[
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _downloadProgress,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                _statusText,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
            ],
            
            // زر التحديث
            if (!_isDownloading)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _startUpdate(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'تحديث الآن',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  /// بدء عملية التحديث
  Future<void> _startUpdate() async {
    setState(() {
      _isDownloading = true;
      _statusText = 'جاري التحميل...';
      _downloadProgress = 0.0;
    });
    
    try {
      // تحميل الملف
      await _downloadAndInstallAPK();
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusText = 'حدث خطأ، يرجى المحاولة مرة أخرى';
      });
    }
  }
  
  /// تحميل وتثبيت APK مع التحميل في الخلفية
  Future<void> _downloadAndInstallAPK() async {
    try {
      setState(() {
        _statusText = 'بدء التحميل...';
        _downloadProgress = 0.0;
      });

      // تحميل الملف مع عرض التقدم الحقيقي
      final request = http.Request('GET', Uri.parse(widget.downloadUrl));
      final response = await request.send();

      if (response.statusCode != 200) {
        throw Exception('فشل في الاتصال بالخادم');
      }

      final contentLength = response.contentLength ?? 0;
      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/montajati_update.apk';
      final file = File(filePath);

      // إنشاء sink للكتابة
      final sink = file.openWrite();
      int downloadedBytes = 0;

      // تحميل البيانات مع عرض التقدم
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (contentLength > 0) {
          final progress = downloadedBytes / contentLength;
          setState(() {
            _downloadProgress = progress;
            _statusText = 'جاري التحميل... ${(progress * 100).toInt()}%';
          });
        }
      }

      await sink.close();

      setState(() {
        _statusText = 'تم التحميل، جاري التثبيت...';
        _downloadProgress = 1.0;
      });

      // انتظار قصير قبل فتح التثبيت
      await Future.delayed(const Duration(milliseconds: 500));

      // فتح ملف APK للتثبيت التلقائي
      final result = await OpenFile.open(filePath);

      if (result.type == ResultType.done) {
        setState(() {
          _statusText = 'جاري التثبيت... يرجى المتابعة في شاشة التثبيت';
        });

        // إغلاق التطبيق بعد فتح التثبيت لإتمام العملية
        await Future.delayed(const Duration(seconds: 3));
        exit(0);
      } else {
        throw Exception('فشل في فتح ملف التثبيت');
      }

    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusText = 'حدث خطأ: ${e.toString()}';
      });
      throw Exception('فشل في التحميل: $e');
    }
  }
}
