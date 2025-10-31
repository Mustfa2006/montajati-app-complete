import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IraqMapPainter extends CustomPainter {
  final Map<String, dynamic> geoJsonData;
  final Map<String, int> provinceOrders;
  final String? selectedProvince;
  final Function(String) onProvinceClick;
  final Color Function(String) getProvinceColor;
  final String Function(String) getArabicName;

  IraqMapPainter({
    required this.geoJsonData,
    required this.provinceOrders,
    this.selectedProvince,
    required this.onProvinceClick,
    required this.getProvinceColor,
    required this.getArabicName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final features = geoJsonData['features'] as List<dynamic>;

    // حساب الحدود الجغرافية للعراق
    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;

    // العثور على الحدود
    for (final feature in features) {
      final geometry = feature['geometry'];
      final coordinates = geometry['coordinates'] as List<dynamic>;

      _findBounds(coordinates, (lat, lng) {
        minLat = math.min(minLat, lat);
        maxLat = math.max(maxLat, lat);
        minLng = math.min(minLng, lng);
        maxLng = math.max(maxLng, lng);
      });
    }

    // رسم كل محافظة
    for (final feature in features) {
      final properties = feature['properties'];
      final provinceName = properties['NAME_1'] as String;
      final arabicName = getArabicName(provinceName);
      final geometry = feature['geometry'];
      final coordinates = geometry['coordinates'] as List<dynamic>;

      final isSelected = selectedProvince == provinceName;
      final color = getProvinceColor(arabicName);

      // رسم المحافظة
      _drawProvince(canvas, size, coordinates, color, isSelected, minLat, maxLat, minLng, maxLng);

      // رسم اسم المحافظة والعدد
      _drawProvinceLabel(
        canvas,
        size,
        coordinates,
        arabicName,
        provinceOrders[arabicName] ?? 0,
        minLat,
        maxLat,
        minLng,
        maxLng,
      );
    }
  }

  void _findBounds(List<dynamic> coordinates, Function(double, double) callback) {
    if (coordinates.isEmpty) return;

    if (coordinates[0] is List) {
      for (final coord in coordinates) {
        _findBounds(coord, callback);
      }
    } else if (coordinates.length >= 2) {
      final lng = coordinates[0] as double;
      final lat = coordinates[1] as double;
      callback(lat, lng);
    }
  }

  void _drawProvince(
    Canvas canvas,
    Size size,
    List<dynamic> coordinates,
    Color color,
    bool isSelected,
    double minLat,
    double maxLat,
    double minLng,
    double maxLng,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isSelected ? Color(0xFFD4AF37) : Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 1;

    _drawCoordinates(canvas, size, coordinates, paint, borderPaint, minLat, maxLat, minLng, maxLng);
  }

  void _drawCoordinates(
    Canvas canvas,
    Size size,
    List<dynamic> coordinates,
    Paint fillPaint,
    Paint borderPaint,
    double minLat,
    double maxLat,
    double minLng,
    double maxLng,
  ) {
    if (coordinates.isEmpty) return;

    if (coordinates[0] is List && coordinates[0][0] is List) {
      // MultiPolygon
      for (final polygon in coordinates) {
        _drawCoordinates(canvas, size, polygon, fillPaint, borderPaint, minLat, maxLat, minLng, maxLng);
      }
    } else if (coordinates[0] is List) {
      // Polygon
      for (int i = 0; i < coordinates.length; i++) {
        final ring = coordinates[i] as List<dynamic>;
        final path = _createPath(ring, size, minLat, maxLat, minLng, maxLng);

        if (i == 0) {
          // الحلقة الخارجية
          canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, borderPaint);
        } else {
          // الحلقات الداخلية (ثقوب)
          canvas.drawPath(
            path,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill,
          );
        }
      }
    }
  }

  Path _createPath(List<dynamic> ring, Size size, double minLat, double maxLat, double minLng, double maxLng) {
    final path = Path();
    bool isFirst = true;

    for (final coord in ring) {
      if (coord is List && coord.length >= 2) {
        final lng = coord[0] as double;
        final lat = coord[1] as double;

        final x = ((lng - minLng) / (maxLng - minLng)) * size.width;
        final y = size.height - ((lat - minLat) / (maxLat - minLat)) * size.height;

        if (isFirst) {
          path.moveTo(x, y);
          isFirst = false;
        } else {
          path.lineTo(x, y);
        }
      }
    }

    path.close();
    return path;
  }

  void _drawProvinceLabel(
    Canvas canvas,
    Size size,
    List<dynamic> coordinates,
    String arabicName,
    int orderCount,
    double minLat,
    double maxLat,
    double minLng,
    double maxLng,
  ) {
    // حساب مركز المحافظة
    final center = _calculateCenter(coordinates, size, minLat, maxLat, minLng, maxLng);
    if (center == null) return;

    // رسم اسم المحافظة
    final nameTextPainter = TextPainter(
      text: TextSpan(
        text: arabicName,
        style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      textDirection: TextDirection.rtl,
    );
    nameTextPainter.layout();
    nameTextPainter.paint(canvas, Offset(center.dx - nameTextPainter.width / 2, center.dy - 25));

    // رسم عدد الطلبات
    final countContainer = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 50, height: 30),
      Radius.circular(15),
    );

    // رسم خلفية العدد
    canvas.drawRRect(countContainer, Paint()..color = Colors.white);
    canvas.drawRRect(
      countContainer,
      Paint()
        ..color = Color(0xFFD4AF37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // رسم العدد
    final countTextPainter = TextPainter(
      text: TextSpan(
        text: '$orderCount',
        style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A365D)),
      ),
      textDirection: TextDirection.ltr,
    );
    countTextPainter.layout();
    countTextPainter.paint(
      canvas,
      Offset(center.dx - countTextPainter.width / 2, center.dy - countTextPainter.height / 2),
    );
  }

  Offset? _calculateCenter(
    List<dynamic> coordinates,
    Size size,
    double minLat,
    double maxLat,
    double minLng,
    double maxLng,
  ) {
    double sumX = 0;
    double sumY = 0;
    int count = 0;

    _collectPoints(coordinates, (lat, lng) {
      final x = ((lng - minLng) / (maxLng - minLng)) * size.width;
      final y = size.height - ((lat - minLat) / (maxLat - minLat)) * size.height;
      sumX += x;
      sumY += y;
      count++;
    });

    if (count == 0) return null;
    return Offset(sumX / count, sumY / count);
  }

  void _collectPoints(List<dynamic> coordinates, Function(double, double) callback) {
    if (coordinates.isEmpty) return;

    if (coordinates[0] is List && coordinates[0][0] is List) {
      // MultiPolygon
      for (final polygon in coordinates) {
        _collectPoints(polygon, callback);
      }
    } else if (coordinates[0] is List) {
      // Polygon - استخدم الحلقة الخارجية فقط
      if (coordinates.isNotEmpty) {
        final ring = coordinates[0] as List<dynamic>;
        for (final coord in ring) {
          if (coord is List && coord.length >= 2) {
            final lng = coord[0] as double;
            final lat = coord[1] as double;
            callback(lat, lng);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  @override
  bool hitTest(Offset position) {
    return true;
  }
}
