import 'package:flutter/material.dart';

class CustomIcons {
  // أيقونة المنزل
  static Widget homeIcon({Color color = Colors.white, double size = 24}) {
    return Icon(
      Icons.home_outlined,
      color: color,
      size: size,
    );
  }

  // أيقونة الإحصائيات
  static Widget chartIcon({Color color = Colors.white, double size = 24}) {
    return Icon(
      Icons.pie_chart_outline,
      color: color,
      size: size,
    );
  }

  // أيقونة الوقت (ساعة)
  static Widget clockIcon({Color color = Colors.white, double size = 24}) {
    return Icon(
      Icons.access_time,
      color: color,
      size: size,
    );
  }

  // أيقونة الإشعارات
  static Widget notificationIcon({Color color = Colors.white, double size = 24}) {
    return Icon(
      Icons.notifications_outlined,
      color: color,
      size: size,
    );
  }
}
