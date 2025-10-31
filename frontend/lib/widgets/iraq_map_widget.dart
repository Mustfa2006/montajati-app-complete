import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// خريطة تحويل الأسماء من الإنجليزية إلى العربية - شاملة لجميع الاحتمالات
const Map<String, String> provinceNamesMap = {
  // الأنبار
  'Al-Anbar': 'الأنبار',
  'Anbar': 'الأنبار',

  // بغداد
  'Baghdad': 'بغداد',

  // صلاح الدين
  'Salah al-Din': 'صلاح الدين',
  'Salah ad-Din': 'صلاح الدين',
  'Saladin': 'صلاح الدين',

  // كربلاء
  'Karbala': 'كربلاء',
  "Karbala'": 'كربلاء',

  // النجف
  'An-Najaf': 'النجف',
  'Najaf': 'النجف',

  // بابل
  'Babil': 'بابل',
  'Babylon': 'بابل',

  // القادسية
  'Al-Qadisiyah': 'القادسية',
  'Al-Qadisiyyah': 'القادسية',
  'Al-Qādisiyyah': 'القادسية',

  // المثنى
  'Al-Muthanna': 'المثنى',
  'Al-Muthannia': 'المثنى',

  // ذي قار
  'Dhi Qar': 'ذي قار',
  'Dhi-Qar': 'ذي قار',
  'Thi Qar': 'ذي قار',

  // البصرة
  'Al-Basrah': 'البصرة',
  'Basra': 'البصرة',

  // ميسان
  'Maysan': 'ميسان',

  // واسط
  'Wasit': 'واسط',

  // ديالى
  'Diyala': 'ديالى',

  // كركوك
  'Kirkuk': 'كركوك',
  'Kirkūk': 'كركوك',

  // نينوى
  'Nineveh': 'نينوى',
  'Ninawa': 'نينوى',
  'Ninewa': 'نينوى',

  // أربيل
  'Erbil': 'أربيل',
  'Arbil': 'أربيل',
  'Irbil': 'أربيل',

  // السليمانية
  'Sulaymaniyah': 'السليمانية',
  'Al-Sulaimaniyah': 'السليمانية',
  'As-Sulaymaniyah': 'السليمانية',
  'Sulaimaniyah': 'السليمانية',

  // دهوك
  'Dohuk': 'دهوك',
  'Duhok': 'دهوك',
  'Dahuk': 'دهوك',
  'Dihok': 'دهوك',
};

class IraqMapWidget extends StatefulWidget {
  final Map<String, dynamic> geoJsonData;
  final Map<String, int> provinceOrders;
  final String? selectedProvince;
  final Function(String provinceName, Offset center) onProvinceSelected;

  const IraqMapWidget({
    super.key,
    required this.geoJsonData,
    required this.provinceOrders,
    required this.selectedProvince,
    required this.onProvinceSelected,
  });

  @override
  State<IraqMapWidget> createState() => _IraqMapWidgetState();
}

class _IraqMapWidgetState extends State<IraqMapWidget> {
  final Map<String, Offset> _provinceCenters = {};
  final Map<String, Path> _provincePaths = {};
  int _maxOrders = 1;
  String? _hoveredProvince;

  @override
  void initState() {
    super.initState();
    _calculateMaxOrders();
    _calculateProvinceCenters();
  }

  @override
  void didUpdateWidget(IraqMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provinceOrders != widget.provinceOrders) {
      _calculateMaxOrders();
    }
  }

  void _calculateMaxOrders() {
    if (widget.provinceOrders.isNotEmpty) {
      _maxOrders = widget.provinceOrders.values.reduce(math.max);
      if (_maxOrders == 0) _maxOrders = 1;
      debugPrint('🔢 Max Orders Calculated: $_maxOrders');
      debugPrint('📊 Province Orders: ${widget.provinceOrders}');
    } else {
      debugPrint('⚠️ Province Orders is empty!');
    }
  }

  void _calculateProvinceCenters() {
    final features = widget.geoJsonData['features'] as List;
    for (var feature in features) {
      final properties = feature['properties'];
      final geometry = feature['geometry'];

      if (geometry['type'] == 'Polygon' || geometry['type'] == 'MultiPolygon') {
        final provinceNameEn = properties['shapeName'] ?? properties['shape1'] ?? properties['name'] ?? '';
        final provinceNameAr = provinceNamesMap[provinceNameEn] ?? provinceNameEn;
        if (provinceNameAr.isNotEmpty) {
          final center = _calculateGeometryCenter(geometry);
          _provinceCenters[provinceNameAr] = center;
          debugPrint('📍 Center for $provinceNameAr: $center');
        }
      }
    }
    debugPrint('📊 Total centers calculated: ${_provinceCenters.length}');
  }

  Offset _calculateGeometryCenter(Map<String, dynamic> geometry) {
    List<List<dynamic>> allCoordinates = [];

    if (geometry['type'] == 'Polygon') {
      allCoordinates = (geometry['coordinates'][0] as List).cast<List<dynamic>>();
    } else if (geometry['type'] == 'MultiPolygon') {
      // للمحافظات ذات الأجزاء المتعددة، نأخذ جميع النقاط
      for (var polygon in geometry['coordinates']) {
        final coords = (polygon[0] as List).cast<List<dynamic>>();
        allCoordinates.addAll(coords);
      }
    }

    if (allCoordinates.isEmpty) {
      return Offset.zero;
    }

    // حساب المركز الهندسي (Centroid) باستخدام خوارزمة أكثر دقة
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var coord in allCoordinates) {
      final x = coord[0] as double;
      final y = coord[1] as double;

      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    // المركز = نقطة المنتصف بين أقصى وأدنى نقطة
    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;

    return Offset(centerX, centerY);
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على ارتفاع الشاشة
    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = screenHeight * 0.7; // 70% من ارتفاع الشاشة

    debugPrint('🗺️ Map Height: $mapHeight');
    debugPrint('📊 Province Orders: ${widget.provinceOrders}');

    return SizedBox(
      height: mapHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              GestureDetector(
                onTapUp: (details) => _handleTap(details.localPosition, constraints.biggest),
                child: MouseRegion(
                  onHover: (event) => _handleHover(event.localPosition, constraints.biggest),
                  child: CustomPaint(
                    size: constraints.biggest,
                    painter: IraqMapPainter(
                      geoJsonData: widget.geoJsonData,
                      provinceOrders: widget.provinceOrders,
                      selectedProvince: widget.selectedProvince,
                      hoveredProvince: _hoveredProvince,
                      maxOrders: _maxOrders,
                      provinceCenters: _provinceCenters,
                      provincePaths: _provincePaths,
                    ),
                  ),
                ),
              ),

              // معلومات المحافظة المختارة
              if (widget.selectedProvince != null) Positioned(top: 20, right: 20, child: _buildProvinceInfoCard()),
            ],
          );
        },
      ),
    );
  }

  void _handleTap(Offset position, Size size) {
    debugPrint('🖱️ Tap at: $position, Size: $size');
    debugPrint('📍 Province paths count: ${_provincePaths.length}');

    for (var entry in _provincePaths.entries) {
      if (entry.value.contains(position)) {
        debugPrint('✅ Found province: ${entry.key}');
        final center = _provinceCenters[entry.key] ?? Offset.zero;
        widget.onProvinceSelected(entry.key, center);
        return;
      }
    }
    debugPrint('❌ No province found at this position');
  }

  void _handleHover(Offset position, Size size) {
    String? newHovered;
    for (var entry in _provincePaths.entries) {
      if (entry.value.contains(position)) {
        newHovered = entry.key;
        break;
      }
    }
    if (newHovered != _hoveredProvince) {
      setState(() {
        _hoveredProvince = newHovered;
      });
    }
  }

  Widget _buildProvinceInfoCard() {
    final orders = widget.provinceOrders[widget.selectedProvince] ?? 0;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFffd700).withValues(alpha: 0.95),
                  const Color(0xFFffa500).withValues(alpha: 0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: const Color(0xFFffd700).withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.selectedProvince!,
                  style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.shopping_bag, color: Colors.black87, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '$orders طلب',
                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// رسام الخريطة
class IraqMapPainter extends CustomPainter {
  final Map<String, dynamic> geoJsonData;
  final Map<String, int> provinceOrders;
  final String? selectedProvince;
  final String? hoveredProvince;
  final int maxOrders;
  final Map<String, Offset> provinceCenters;
  final Map<String, Path> provincePaths;

  IraqMapPainter({
    required this.geoJsonData,
    required this.provinceOrders,
    required this.selectedProvince,
    required this.hoveredProvince,
    required this.maxOrders,
    required this.provinceCenters,
    required this.provincePaths,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final features = geoJsonData['features'] as List;

    // مسح المسارات القديمة
    provincePaths.clear();

    // حساب حدود الخريطة
    double minLon = double.infinity;
    double maxLon = double.negativeInfinity;
    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;

    for (var feature in features) {
      final geometry = feature['geometry'];
      _updateBounds(geometry, (lon, lat) {
        minLon = math.min(minLon, lon);
        maxLon = math.max(maxLon, lon);
        minLat = math.min(minLat, lat);
        maxLat = math.max(maxLat, lat);
      });
    }

    // رسم كل محافظة
    for (var feature in features) {
      final properties = feature['properties'];
      final geometry = feature['geometry'];
      final provinceNameEn = properties['shapeName'] ?? properties['shape1'] ?? properties['name'] ?? '';
      final provinceNameAr = provinceNamesMap[provinceNameEn] ?? provinceNameEn;

      if (provinceNameAr.isEmpty) {
        debugPrint('⚠️ Empty province name for: $properties');
        continue;
      }

      final orders = provinceOrders[provinceNameAr] ?? 0;
      final isSelected = provinceNameAr == selectedProvince;
      final isHovered = provinceNameAr == hoveredProvince;

      debugPrint('🎨 Drawing: $provinceNameAr (EN: $provinceNameEn) - Orders: $orders');

      _drawGeometry(
        canvas,
        size,
        geometry,
        minLon,
        maxLon,
        minLat,
        maxLat,
        orders,
        isSelected,
        isHovered,
        provinceNameAr,
      );
    }

    debugPrint('🗺️ Total provinces drawn: ${provincePaths.length}');
  }

  void _updateBounds(Map<String, dynamic> geometry, Function(double lon, double lat) callback) {
    if (geometry['type'] == 'Polygon') {
      final coords = geometry['coordinates'][0] as List;
      for (var coord in coords) {
        callback(coord[0], coord[1]);
      }
    } else if (geometry['type'] == 'MultiPolygon') {
      final polygons = geometry['coordinates'] as List;
      for (var polygon in polygons) {
        final coords = polygon[0] as List;
        for (var coord in coords) {
          callback(coord[0], coord[1]);
        }
      }
    }
  }

  void _drawGeometry(
    Canvas canvas,
    Size size,
    Map<String, dynamic> geometry,
    double minLon,
    double maxLon,
    double minLat,
    double maxLat,
    int orders,
    bool isSelected,
    bool isHovered,
    String provinceName,
  ) {
    final color = _getProvinceColor(orders, isSelected);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    Path? provincePath;

    if (geometry['type'] == 'Polygon') {
      provincePath = _drawPolygon(
        canvas,
        size,
        geometry['coordinates'][0],
        minLon,
        maxLon,
        minLat,
        maxLat,
        paint,
        borderPaint,
      );
    } else if (geometry['type'] == 'MultiPolygon') {
      final polygons = geometry['coordinates'] as List;
      for (var polygon in polygons) {
        final path = _drawPolygon(canvas, size, polygon[0], minLon, maxLon, minLat, maxLat, paint, borderPaint);
        if (provincePath == null) {
          provincePath = path;
        } else {
          provincePath.addPath(path, Offset.zero);
        }
      }
    }

    // حفظ المسار للتفاعل
    if (provincePath != null) {
      provincePaths[provinceName] = provincePath;
      debugPrint('✅ Saved path for: $provinceName');
    }

    // رسم عدد الطلبات - حتى لو كان 0
    if (provinceCenters.containsKey(provinceName)) {
      final center = provinceCenters[provinceName]!;
      var screenPoint = _projectPoint(center.dx, center.dy, size, minLon, maxLon, minLat, maxLat);

      // تعديلات خاصة لموقع الأرقام في بعض المحافظات
      screenPoint = _adjustNumberPosition(screenPoint, provinceName, size);

      _drawOrderCount(canvas, screenPoint, orders, isSelected);
      debugPrint('🔢 Drawing number $orders at $screenPoint for $provinceName');
    } else {
      debugPrint('⚠️ No center found for: $provinceName');
    }
  }

  // تعديل موقع الأرقام لبعض المحافظات لتكون في أفضل مكان
  Offset _adjustNumberPosition(Offset point, String provinceName, Size size) {
    // تعديلات خاصة لكل محافظة
    switch (provinceName) {
      case 'البصرة':
        // رفع الرقم للأعلى قليلاً
        return Offset(point.dx, point.dy - 13);

      case 'القادسية':
        // رفع الرقم للأعلى قليلاً
        return Offset(point.dx, point.dy - 10);

      case 'ذي قار':
        // تعديل بسيط للأعلى
        return Offset(point.dx - 5, point.dy - 3);

      case 'المثنى':
        // تعديل بسيط للأعلى
        return Offset(point.dx, point.dy - 0);

      case 'ميسان':
        // تعديل بسيط للأعلى
        return Offset(point.dx, point.dy - 0);

      case 'واسط':
        // تعديل بسيط للأعلى
        return Offset(point.dx, point.dy - 5);

      default:
        return point;
    }
  }

  Path _drawPolygon(
    Canvas canvas,
    Size size,
    List<dynamic> coordinates,
    double minLon,
    double maxLon,
    double minLat,
    double maxLat,
    Paint fillPaint,
    Paint borderPaint,
  ) {
    final path = Path();
    bool first = true;

    for (var coord in coordinates) {
      final point = _projectPoint(coord[0], coord[1], size, minLon, maxLon, minLat, maxLat);
      if (first) {
        path.moveTo(point.dx, point.dy);
        first = false;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    return path;
  }

  Offset _projectPoint(double lon, double lat, Size size, double minLon, double maxLon, double minLat, double maxLat) {
    final padding = 40.0;
    final availableWidth = size.width - (padding * 2);
    final availableHeight = size.height - (padding * 2);

    final x = padding + ((lon - minLon) / (maxLon - minLon)) * availableWidth;
    final y = padding + ((maxLat - lat) / (maxLat - minLat)) * availableHeight;

    return Offset(x, y);
  }

  Color _getProvinceColor(int orders, bool isSelected) {
    if (isSelected) {
      // لون ذهبي فاتح للمحافظة المختارة
      return const Color(0xFFffd700).withValues(alpha: 0.85);
    }

    // لون بني داكن للمحافظات بدون طلبات
    const baseColor = Color(0xFF5a2e2e); // بني داكن

    if (orders == 0) {
      return baseColor.withValues(alpha: 0.3);
    }

    // حساب النسبة المئوية من أعلى عدد طلبات
    final intensity = (orders / maxOrders).clamp(0.0, 1.0);

    // 🎨 نظام تدرج ذكي جداً - تدرج تربيعي (quadratic) لجعل الفرق أكثر وضوحاً
    // مثال: إذا كان لدينا محافظة بـ 1 طلب ومحافظة بـ 4 طلبات:
    // - المحافظة بـ 1: intensity = 0.25 → intensity² = 0.0625 (6.25%) → أحمر خفيف جداً
    // - المحافظة بـ 4: intensity = 1.0 → intensity² = 1.0 (100%) → أحمر داكن بارز
    // الفرق الآن: 6.25% vs 100% بدلاً من 25% vs 100% - فرق واضح جداً! 🔥
    final quadraticIntensity = intensity * intensity;

    return Color.lerp(
      const Color(0xFFFFCDD2), // أحمر خفيف جداً جداً (للأقل) - شبه شفاف
      const Color(0xFFC62828), // أحمر داكن بارز جداً (للأعلى)
      quadraticIntensity, // تدرج تربيعي من 0% إلى 100%
    )!.withValues(alpha: 0.65 + (quadraticIntensity * 0.3)); // شفافية من 65% إلى 95%
  }

  void _drawOrderCount(Canvas canvas, Offset center, int orders, bool isSelected) {
    // رسم الرقم بتصميم مثل الصورة
    final textPainter = TextPainter(
      text: TextSpan(
        text: orders.toString(),
        style: GoogleFonts.cairo(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isSelected ? const Color(0xFFffd700) : Colors.white,
          shadows: [const Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(2, 2))],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // رسم الرقم في منتصف المحافظة
    final offset = Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2);

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(IraqMapPainter oldDelegate) {
    return oldDelegate.selectedProvince != selectedProvince ||
        oldDelegate.provinceOrders != provinceOrders ||
        oldDelegate.hoveredProvince != hoveredProvince;
  }
}
