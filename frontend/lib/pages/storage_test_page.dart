import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_test_service.dart';
import '../services/image_upload_test_service.dart';

class StorageTestPage extends StatefulWidget {
  const StorageTestPage({super.key});

  @override
  State<StorageTestPage> createState() => _StorageTestPageState();
}

class _StorageTestPageState extends State<StorageTestPage> {
  bool _isLoading = false;
  String _testResults = '';
  final List<XFile> _selectedImages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf5f5f5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'اختبار Storage',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1a1a2e),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTestButtons(),
            const SizedBox(height: 20),
            _buildImageSection(),
            const SizedBox(height: 20),
            _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'اختبارات Storage',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1a1a2e),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testSupabaseConnection,
                  icon: const Icon(FontAwesomeIcons.database),
                  label: Text(
                    'اختبار Supabase',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testImageUpload,
                  icon: const Icon(FontAwesomeIcons.upload),
                  label: Text(
                    'اختبار رفع صورة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'اختبار صور حقيقية',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1a1a2e),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickImages,
            icon: const Icon(FontAwesomeIcons.images),
            label: Text(
              'اختيار صور',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFffd700),
              foregroundColor: const Color(0xFF1a1a2e),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            ),
          ),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(
              'تم اختيار ${_selectedImages.length} صورة',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testRealImageUpload,
              icon: const Icon(FontAwesomeIcons.cloudArrowUp),
              label: Text(
                'اختبار رفع الصور المختارة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نتائج الاختبار',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFffd700)),
            )
          else
            Container(
              width: double.infinity,
              height: 300,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _testResults.isEmpty ? 'لا توجد نتائج بعد...' : _testResults,
                  style: GoogleFonts.firaCode(
                    fontSize: 12,
                    color: Colors.green,
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _testSupabaseConnection() async {
    setState(() {
      _isLoading = true;
      _testResults = 'جاري اختبار Supabase...\n';
    });

    try {
      final results = await SupabaseTestService.runCompleteTest();

      setState(() {
        _testResults += '\n=== نتائج اختبار Supabase ===\n';
        _testResults += 'الاتصال: ${results['connection'] ? '✅' : '❌'}\n';
        _testResults += 'قاعدة البيانات: ${results['database'] ? '✅' : '❌'}\n';
        _testResults += 'Storage: ${results['storage'] ? '✅' : '❌'}\n';
        _testResults +=
            'Bucket موجود: ${results['bucket_exists'] ? '✅' : '❌'}\n';
        _testResults +=
            'صلاحيات Bucket: ${results['bucket_permissions'] ? '✅' : '❌'}\n';
        _testResults += 'اختبار الرفع: ${results['upload_test'] ? '✅' : '❌'}\n';

        if (results['errors'].isNotEmpty) {
          _testResults += '\nالأخطاء:\n';
          for (final error in results['errors']) {
            _testResults += '❌ $error\n';
          }
        }

        _testResults += '\n';
      });
    } catch (e) {
      setState(() {
        _testResults += 'خطأ في الاختبار: $e\n';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testImageUpload() async {
    setState(() {
      _isLoading = true;
      _testResults += '\nجاري اختبار رفع صورة تجريبية...\n';
    });

    try {
      final results = await ImageUploadTestService.testImageUpload();

      setState(() {
        _testResults += '\n=== نتائج اختبار رفع الصورة ===\n';
        _testResults += 'النتيجة: ${results['success'] ? '✅ نجح' : '❌ فشل'}\n';

        if (results['url'] != null) {
          _testResults += 'الرابط: ${results['url']}\n';
        }

        if (results['error'] != null) {
          _testResults += 'الخطأ: ${results['error']}\n';
        }

        _testResults += '\nخطوات التنفيذ:\n';
        for (final step in results['steps']) {
          _testResults += '$step\n';
        }

        _testResults += '\n';
      });
    } catch (e) {
      setState(() {
        _testResults += 'خطأ في اختبار رفع الصورة: $e\n';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      setState(() {
        _selectedImages.clear();
        _selectedImages.addAll(images);
      });
    } catch (e) {
      setState(() {
        _testResults += 'خطأ في اختيار الصور: $e\n';
      });
    }
  }

  Future<void> _testRealImageUpload() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isLoading = true;
      _testResults += '\nجاري اختبار رفع الصور الحقيقية...\n';
    });

    try {
      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];

        setState(() {
          _testResults += '\nاختبار الصورة ${i + 1}: ${image.name}\n';
        });

        final results = await ImageUploadTestService.testRealImageUpload(image);

        setState(() {
          _testResults +=
              'النتيجة: ${results['success'] ? '✅ نجح' : '❌ فشل'}\n';

          if (results['url'] != null) {
            _testResults += 'الرابط: ${results['url']}\n';
          }

          if (results['error'] != null) {
            _testResults += 'الخطأ: ${results['error']}\n';
          }

          if (results['file_info'] != null) {
            final info = results['file_info'] as Map<String, dynamic>;
            _testResults += 'الحجم: ${info['size_mb']} MB\n';
          }
        });
      }
    } catch (e) {
      setState(() {
        _testResults += 'خطأ في اختبار الصور الحقيقية: $e\n';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }
}
