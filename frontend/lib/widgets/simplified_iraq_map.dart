import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SimplifiedIraqMap extends StatefulWidget {
  final Map<String, int> provinceOrders;
  final Function(String)? onProvinceClick;

  const SimplifiedIraqMap({super.key, required this.provinceOrders, this.onProvinceClick});

  @override
  State<SimplifiedIraqMap> createState() => _SimplifiedIraqMapState();
}

class _SimplifiedIraqMapState extends State<SimplifiedIraqMap> {
  String? selectedProvince;
  bool isLoading = true;
  Map<String, dynamic>? geoJsonData;

  @override
  void initState() {
    super.initState();
    _loadGeoJsonData();
  }

  Future<void> _loadGeoJsonData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/iraq_provinces_real.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      setState(() {
        geoJsonData = jsonData;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('خطأ في تحميل بيانات الخريطة: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Color _getProvinceColor(String provinceName) {
    final orderCount = widget.provinceOrders[provinceName] ?? 0;

    if (orderCount == 0) {
      return Colors.grey[300]!;
    } else if (orderCount <= 10) {
      return Color(0xFFFFE4E1); // وردي فاتح جداً
    } else if (orderCount <= 30) {
      return Color(0xFFFFB6C1); // وردي فاتح
    } else if (orderCount <= 60) {
      return Color(0xFFFF69B4); // وردي متوسط
    } else if (orderCount <= 100) {
      return Color(0xFFFF1493); // وردي داكن
    } else {
      return Color(0xFFDC143C); // أحمر داكن
    }
  }

  String _getArabicProvinceName(String englishName) {
    final Map<String, String> nameMapping = {
      'Al-Anbar': 'الأنبار',
      'Al-Basrah': 'البصرة',
      'Al-Muthannia': 'المثنى',
      'Al-Qadisiyah': 'القادسية',
      'An-Najaf': 'النجف',
      'Arbil': 'أربيل',
      'As-Sulaymaniyah': 'السليمانية',
      'At-Ta\'mim': 'كركوك',
      'Babil': 'بابل',
      'Baghdad': 'بغداد',
      'Dhi-Qar': 'ذي قار',
      'Dihok': 'دهوك',
      'Diyala': 'ديالى',
      'Karbala': 'كربلاء',
      'Maysan': 'ميسان',
      'Ninawa': 'نينوى',
      'Salah-ad-Din': 'صلاح الدين',
      'Wasit': 'واسط',
    };
    return nameMapping[englishName] ?? englishName;
  }

  void _showProvinceDetails(String provinceName) {
    final arabicName = _getArabicProvinceName(provinceName);
    final orderCount = widget.provinceOrders[arabicName] ?? 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A365D), Color(0xFF2D5A87)],
              ),
              boxShadow: [
                BoxShadow(color: Color(0xFFD4AF37).withValues(alpha: 0.3), blurRadius: 20, offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: Color(0xFFD4AF37), size: 48),
                SizedBox(height: 16),
                Text(
                  arabicName,
                  style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Color(0xFFD4AF37), width: 2),
                  ),
                  child: Text(
                    '$orderCount طلب',
                    style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD4AF37),
                    foregroundColor: Color(0xFF1A365D),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: Text('إغلاق', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 600,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37))),
              SizedBox(height: 16),
              Text(
                'جاري تحميل خريطة العراق الحقيقية...',
                style: GoogleFonts.cairo(fontSize: 16, color: Color(0xFF1A365D)),
              ),
            ],
          ),
        ),
      );
    }

    if (geoJsonData == null) {
      return SizedBox(
        height: 600,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text('خطأ في تحميل بيانات الخريطة', style: GoogleFonts.cairo(fontSize: 18, color: Colors.red)),
              SizedBox(height: 8),
              Text('سيتم عرض خريطة مبسطة', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // عنوان الخريطة
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map, color: Color(0xFFD4AF37), size: 28),
              const SizedBox(width: 8),
              Text(
                'خريطة العراق التفاعلية الحقيقية',
                style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A365D)),
              ),
            ],
          ),
        ),

        // رسالة نجاح تحميل البيانات
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تم تحميل بيانات GeoJSON الحقيقية للمحافظات العراقية بنجاح',
                  style: GoogleFonts.cairo(fontSize: 14, color: Colors.green[800]),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // معلومات البيانات
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF1A365D).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Color(0xFFD4AF37)),
          ),
          child: Column(
            children: [
              Text(
                'معلومات الخريطة',
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
              ),
              SizedBox(height: 12),
              _buildInfoRow('مصدر البيانات:', 'geoBoundaries - المستوى الإداري 1'),
              _buildInfoRow('عدد المحافظات:', '${geoJsonData!['features'].length} محافظة'),
              _buildInfoRow('نوع البيانات:', 'GeoJSON مع إحداثيات دقيقة'),
              _buildInfoRow('نظام الإحداثيات:', 'WGS84 (EPSG:4326)'),
            ],
          ),
        ),

        SizedBox(height: 16),

        // قائمة المحافظات مع البيانات
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'المحافظات المتوفرة في البيانات:',
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
          ),
        ),

        SizedBox(height: 8),

        // عرض المحافظات
        Container(
          height: 400,
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Color(0xFFD4AF37)),
          ),
          child: ListView.builder(
            itemCount: geoJsonData!['features'].length,
            itemBuilder: (context, index) {
              final feature = geoJsonData!['features'][index];
              final properties = feature['properties'];
              final englishName = properties['NAME_1'] as String;
              final arabicName = _getArabicProvinceName(englishName);
              final orderCount = widget.provinceOrders[arabicName] ?? 0;
              final color = _getProvinceColor(arabicName);

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                    ),
                    title: Text(
                      arabicName,
                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
                    ),
                    subtitle: Text(englishName, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600])),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Color(0xFFD4AF37), borderRadius: BorderRadius.circular(15)),
                      child: Text(
                        '$orderCount طلب',
                        style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    onTap: () => _showProvinceDetails(englishName),
                  ),
                ),
              );
            },
          ),
        ),

        // مفتاح الألوان
        _buildLegend(),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
            ),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Color(0xFFD4AF37), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مفتاح الألوان - عدد الطلبات',
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem('0', Colors.grey[300]!),
              _buildLegendItem('1-10', Color(0xFFFFE4E1)),
              _buildLegendItem('11-30', Color(0xFFFFB6C1)),
              _buildLegendItem('31-60', Color(0xFFFF69B4)),
              _buildLegendItem('61-100', Color(0xFFFF1493)),
              _buildLegendItem('+100', Color(0xFFDC143C)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[400]!),
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: GoogleFonts.cairo(fontSize: 12, color: Color(0xFF1A365D))),
      ],
    );
  }
}
