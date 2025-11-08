import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IraqSimpleMap extends StatefulWidget {
  final Map<String, int> provinceOrderCounts;
  final Function(String provinceName, int orderCount)? onProvinceClick;

  const IraqSimpleMap({super.key, required this.provinceOrderCounts, this.onProvinceClick});

  @override
  State<IraqSimpleMap> createState() => _IraqSimpleMapState();
}

class _IraqSimpleMapState extends State<IraqSimpleMap> {
  String? selectedProvince;

  // خريطة المحافظات مع مواقعها التقريبية (نسب مئوية) - محسنة لتشبه شكل العراق الحقيقي
  final Map<String, Map<String, dynamic>> provinces = {
    // الشمال
    'دهوك': {'top': 0.05, 'left': 0.35, 'width': 0.15, 'height': 0.08},
    'نينوى': {'top': 0.12, 'left': 0.25, 'width': 0.20, 'height': 0.12},
    'أربيل': {'top': 0.15, 'left': 0.45, 'width': 0.18, 'height': 0.10},
    'السليمانية': {'top': 0.18, 'left': 0.63, 'width': 0.15, 'height': 0.12},
    'كركوك': {'top': 0.28, 'left': 0.45, 'width': 0.15, 'height': 0.08},
    'ديالى': {'top': 0.35, 'left': 0.60, 'width': 0.15, 'height': 0.12},

    // الوسط
    'الأنبار': {'top': 0.30, 'left': 0.15, 'width': 0.25, 'height': 0.20},
    'صلاح الدين': {'top': 0.32, 'left': 0.40, 'width': 0.12, 'height': 0.10},
    'بغداد': {'top': 0.42, 'left': 0.45, 'width': 0.10, 'height': 0.08},
    'كربلاء': {'top': 0.50, 'left': 0.35, 'width': 0.10, 'height': 0.06},
    'بابل': {'top': 0.48, 'left': 0.45, 'width': 0.10, 'height': 0.06},
    'واسط': {'top': 0.52, 'left': 0.55, 'width': 0.12, 'height': 0.08},

    // الجنوب
    'النجف': {'top': 0.56, 'left': 0.30, 'width': 0.15, 'height': 0.10},
    'الديوانية': {'top': 0.60, 'left': 0.40, 'width': 0.12, 'height': 0.08},
    'المثنى': {'top': 0.66, 'left': 0.25, 'width': 0.15, 'height': 0.12},
    'ذي قار': {'top': 0.68, 'left': 0.40, 'width': 0.15, 'height': 0.10},
    'ميسان': {'top': 0.62, 'left': 0.55, 'width': 0.12, 'height': 0.10},
    'البصرة': {'top': 0.75, 'left': 0.45, 'width': 0.20, 'height': 0.12},
  };

  Color _getProvinceColor(String provinceName) {
    final orderCount = widget.provinceOrderCounts[provinceName] ?? 0;

    if (orderCount == 0) {
      return Colors.grey[200]!;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0xFFD4AF37).withValues(alpha: 0.3), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // خلفية الخريطة
            Container(width: double.infinity, height: double.infinity, color: Color(0xFFF8F9FA)),

            // المحافظات
            ...provinces.entries.map((entry) {
              final provinceName = entry.key;
              final position = entry.value;
              final orderCount = widget.provinceOrderCounts[provinceName] ?? 0;
              final isSelected = selectedProvince == provinceName;

              return Positioned(
                top: position['top'] * 600,
                left: position['left'] * 800, // حجم ثابت للخريطة
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedProvince = provinceName;
                    });
                    _showProvinceDialog(provinceName, orderCount);
                  },
                  child: Container(
                    width: position['width'] * 800, // حجم ثابت للخريطة
                    height: position['height'] * 600,
                    decoration: BoxDecoration(
                      color: _getProvinceColor(provinceName),
                      border: Border.all(
                        color: isSelected ? Color(0xFFD4AF37) : Colors.grey[600]!,
                        width: isSelected ? 3 : 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: Offset(0, 3)),
                        if (isSelected)
                          BoxShadow(
                            color: Color(0xFFD4AF37).withValues(alpha: 0.6),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // اسم المحافظة
                        Positioned(
                          top: 4,
                          left: 2,
                          right: 2,
                          child: Text(
                            provinceName,
                            style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // عدد الطلبات في الوسط
                        Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFFD4AF37), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '$orderCount',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A365D),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // عنوان الخريطة
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF1A365D),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Text(
                  'خريطة العراق التفاعلية',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                ),
              ),
            ),

            // مفتاح الألوان
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFD4AF37)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'عدد الطلبات',
                      style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
                    ),
                    SizedBox(height: 8),
                    _buildLegendItem('0', Colors.grey[200]!),
                    _buildLegendItem('1-10', Color(0xFFFFE4E1)),
                    _buildLegendItem('11-30', Color(0xFFFFB6C1)),
                    _buildLegendItem('31-60', Color(0xFFFF69B4)),
                    _buildLegendItem('61-100', Color(0xFFFF1493)),
                    _buildLegendItem('100+', Color(0xFFDC143C)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 8),
          Text(label, style: GoogleFonts.cairo(fontSize: 10, color: Colors.black87)),
        ],
      ),
    );
  }

  void _showProvinceDialog(String provinceName, int orderCount) {
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
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 48, color: Color(0xFFD4AF37)),
                SizedBox(height: 16),
                Text(
                  provinceName,
                  style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(color: Color(0xFFD4AF37), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    'عدد الطلبات: $orderCount',
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (widget.onProvinceClick != null) {
                      widget.onProvinceClick!(provinceName, orderCount);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD4AF37),
                    foregroundColor: Color(0xFF1A365D),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
}
