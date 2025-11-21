import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../utils/theme_colors.dart';

/// نص مع دعم الوضع الليلي/النهاري
class ThemedText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final bool isSecondary;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ThemedText(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.isSecondary = false,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final defaultColor = isSecondary ? ThemeColors.secondaryTextColor(isDark) : ThemeColors.textColor(isDark);

    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? defaultColor,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// أيقونة مع دعم الوضع الليلي/النهاري
class ThemedIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final bool isSecondary;

  const ThemedIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final defaultColor = isSecondary ? ThemeColors.secondaryIconColor(isDark) : ThemeColors.iconColor(isDark);

    return Icon(
      icon,
      size: size,
      color: color ?? defaultColor,
    );
  }
}

/// Container مع دعم الوضع الليلي/النهاري
class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;

  const ThemedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? ThemeColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(borderRadius ?? 15),
        border: Border.all(
          color: borderColor ?? ThemeColors.cardBorder(isDark),
          width: borderWidth ?? 1,
        ),
      ),
      child: child,
    );
  }
}

