// 📝 قسم الوصف
// Description Section Widget

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/theme_provider.dart';

/// قسم الوصف مع الروابط
class DescriptionSection extends StatefulWidget {
  final String description;
  final VoidCallback onCopy;

  const DescriptionSection({super.key, required this.description, required this.onCopy});

  @override
  State<DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<DescriptionSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final links = _extractLinks(widget.description);
    final cleanDescription = _removeLinksFromText(widget.description);
    final shortDescription = cleanDescription.length > 80
        ? '${cleanDescription.substring(0, 80)}...'
        : cleanDescription;

    return _build3DGlassCard(
      isDark: isDark,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // رأس الوصف
          GestureDetector(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
              HapticFeedback.selectionClick();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildIcon(isDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'الوصف',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  _buildCopyButton(isDark),
                  const SizedBox(width: 10),
                  _buildExpandButton(isDark),
                ],
              ),
            ),
          ),

          // المحتوى الموسع
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isExpanded ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (links.isNotEmpty) _buildLinksBox(links, isDark),
                    Text(
                      cleanDescription,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.85),
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // معاينة عند الطي
          if (!_isExpanded && links.isNotEmpty) _buildLinksPreview(links, isDark),
          if (!_isExpanded && links.isEmpty) _buildTextPreview(shortDescription, isDark),
        ],
      ),
    );
  }

  Widget _buildIcon(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
            : const Color(0xFFD4AF37).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3), width: 1),
      ),
      child: const Icon(Icons.description, color: Color(0xFFD4AF37), size: 18),
    );
  }

  Widget _buildCopyButton(bool isDark) {
    return GestureDetector(
      onTap: widget.onCopy,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFFFFD700).withValues(alpha: 0.15)
              : const Color(0xFFFFD700).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 1),
        ),
        child: const Icon(Icons.copy, color: Color(0xFFD4AF37), size: 16),
      ),
    );
  }

  Widget _buildExpandButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedRotation(
        turns: _isExpanded ? 0.5 : 0,
        duration: const Duration(milliseconds: 300),
        child: Icon(
          Icons.keyboard_arrow_down,
          color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.8),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildLinksBox(List<Map<String, String>> links, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFFFFD700).withValues(alpha: 0.08)
            : const Color(0xFFFFD700).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: Color(0xFFD4AF37), size: 16),
              const SizedBox(width: 6),
              Text(
                'الروابط',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${links.length} ${links.length == 1 ? 'رابط' : 'روابط'}',
                  style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFD4AF37)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...links.map(
            (link) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildLinkButton(link, isDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksPreview(List<Map<String, String>> links, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() => _isExpanded = true);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFFFFD700).withValues(alpha: 0.08)
                : const Color(0xFFFFD700).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.25), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.link, color: Color(0xFFD4AF37), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'الروابط',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${links.length} ${links.length == 1 ? 'رابط' : 'روابط'}',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...links
                  .take(2)
                  .map(
                    (link) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildLinkButton(link, isDark)),
                  ),
              if (links.length > 2)
                Text(
                  '... و ${links.length - 2} ${links.length - 2 == 1 ? 'رابط آخر' : 'روابط أخرى'}',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextPreview(String shortDescription, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() => _isExpanded = true);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Text(
          shortDescription,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: isDark ? Colors.white.withValues(alpha: 0.65) : Colors.black.withValues(alpha: 0.65),
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildLinkButton(Map<String, String> link, bool isDark) {
    return GestureDetector(
      onTap: () => _openUrl(link['url']!),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.open_in_new, color: Color(0xFFD4AF37), size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                link['name']!,
                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFD4AF37)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🚀 فتح الرابط بطريقة ذكية
  /// يحول روابط تلكرام للفتح المباشر في التطبيق
  Future<void> _openUrl(String url) async {
    try {
      String targetUrl = url;

      // 🔄 تحويل روابط تلكرام الويب إلى Deep Link للتطبيق
      if (_isTelegramUrl(url)) {
        targetUrl = _convertToTelegramDeepLink(url);
      }

      final uri = Uri.parse(targetUrl);

      // 🎯 محاولة فتح التطبيق مباشرة أولاً
      final launched = await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);

      // 🔄 إذا فشل، جرب فتح الرابط الأصلي في المتصفح
      if (!launched) {
        final originalUri = Uri.parse(url);
        await launchUrl(originalUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // 🔄 في حالة أي خطأ، افتح في المتصفح
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// ✅ التحقق إذا كان الرابط تلكرام
  bool _isTelegramUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('t.me') ||
        lowerUrl.contains('telegram.me') ||
        lowerUrl.contains('telegram.org') ||
        lowerUrl.contains('tg://');
  }

  /// 🔄 تحويل رابط تلكرام الويب إلى Deep Link
  String _convertToTelegramDeepLink(String url) {
    // إذا كان الرابط بالفعل deep link
    if (url.startsWith('tg://')) {
      return url;
    }

    // استخراج المسار من الرابط
    // مثال: https://t.me/channel_name/123 → tg://resolve?domain=channel_name&post=123
    // مثال: https://t.me/username → tg://resolve?domain=username

    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;

    if (pathSegments.isEmpty) {
      return url; // إرجاع الرابط الأصلي إذا لا يوجد مسار
    }

    final domain = pathSegments[0];

    // إذا كان هناك رقم منشور (post)
    if (pathSegments.length >= 2) {
      final postId = pathSegments[1];
      // التحقق إذا كان رقم
      if (int.tryParse(postId) != null) {
        return 'tg://resolve?domain=$domain&post=$postId';
      }
    }

    // فقط اسم القناة أو المستخدم
    return 'tg://resolve?domain=$domain';
  }

  List<Map<String, String>> _extractLinks(String text) {
    final List<Map<String, String>> links = [];
    final RegExp urlPattern = RegExp(r'(https?://[^\s]+)', caseSensitive: false);
    final matches = urlPattern.allMatches(text);
    int linkCounter = 1;

    for (final match in matches) {
      String url = match.group(0) ?? '';
      url = url.replaceAll(RegExp(r'[,،.]+$'), '');
      String name = ' الفيديو الإعلاني ${linkCounter++}';
      if (url.contains('instagram')) {
        name = 'إنستاغرام';
      } else if (url.contains('tiktok')) {
        name = 'تيك توك';
      } else if (url.contains('youtube') || url.contains('youtu.be')) {
        name = 'يوتيوب';
      } else if (url.contains('facebook')) {
        name = 'فيسبوك';
      } else if (url.contains('twitter') || url.contains('x.com')) {
        name = 'تويتر';
      }
      links.add({'url': url, 'name': name});
    }
    return links;
  }

  String _removeLinksFromText(String text) {
    // إزالة الروابط والسطر الذي يحتوي عليها مع الحفاظ على الأسطر الجديدة
    final RegExp urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);
    final lines = text.split('\n');
    final cleanLines = <String>[];

    for (final line in lines) {
      // إزالة الروابط من السطر
      final cleanLine = line.replaceAll(urlPattern, '').trim();
      // إضافة السطر إذا لم يكن فارغاً
      if (cleanLine.isNotEmpty) {
        cleanLines.add(cleanLine);
      }
    }

    return cleanLines.join('\n').trim();
  }

  Widget _build3DGlassCard({
    required bool isDark,
    required Widget child,
    double blurAmount = 5,
    EdgeInsets padding = const EdgeInsets.all(20),
    double borderRadius = 20,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
