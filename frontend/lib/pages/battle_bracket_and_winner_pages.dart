import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';

/// صفحة خريطة البطولة (Bracket)
class TournamentBracketPage extends StatelessWidget {
  const TournamentBracketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'خريطة البطولة',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ThemeColors.appBarTextColor(isDark),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 100),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: 900, child: _BracketContent(isDark: isDark)),
            ),
          ),
        ),
      ),
    );
  }
}

class _BracketContent extends StatelessWidget {
  final bool isDark;

  const _BracketContent({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFFFD700);
    final textColor = ThemeColors.textColor(isDark);

    Widget buildPlayerCircle(String label) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: accentColor, width: 1.5),
          color: Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.w700, color: textColor),
        ),
      );
    }

    /// عمود من 8 كرات مع خطوط ربط بين كل لاعبين (Match)
    Widget buildSide({required String groupLabel, required bool alignRight}) {
      const double verticalGap = 40;
      const double circleSize = 20;
      const double sideHeight = verticalGap * 7 + circleSize;

      final children = <Widget>[];

      double topForIndex(int i) => i * verticalGap;

      // الكرات الثمانية (A1..A8 أو B1..B8)
      for (int i = 0; i < 8; i++) {
        final top = topForIndex(i);
        children.add(
          Positioned(
            top: top,
            right: alignRight ? 0 : null,
            left: alignRight ? null : 0,
            child: buildPlayerCircle('$groupLabel${i + 1}'),
          ),
        );
      }

      // خطوط الربط لكل مباراتين
      for (int pair = 0; pair < 4; pair++) {
        final int first = pair * 2;
        final int second = first + 1;

        final double firstCenterY = topForIndex(first) + circleSize / 2;
        final double secondCenterY = topForIndex(second) + circleSize / 2;
        final double midY = (firstCenterY + secondCenterY) / 2;

        final double lineXOffset = circleSize + 6;

        // خط عمودي بين اللاعب الأول والثاني
        children.add(
          Positioned(
            top: firstCenterY,
            right: alignRight ? lineXOffset : null,
            left: alignRight ? null : lineXOffset,
            child: Container(
              width: 2,
              height: secondCenterY - firstCenterY,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );

        // خط أفقي يخرج من منتصف المباراة باتجاه منتصف الساحة
        children.add(
          Positioned(
            top: midY,
            right: alignRight ? lineXOffset : null,
            left: alignRight ? null : lineXOffset,
            child: Container(
              width: 40,
              height: 2,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }

      return SizedBox(
        width: 110,
        height: sideHeight,
        child: Stack(children: children),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ساحة المعركة - خريطة البطولة',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Center(
            child: SizedBox(
              height: 360,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // المجموعة B (يسار)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المجموعة B',
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      buildSide(groupLabel: 'B', alignRight: false),
                    ],
                  ),
                  // عمود الكأس والنهائي في المنتصف
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text('فائز المجموعة B', style: GoogleFonts.cairo(fontSize: 11, color: textColor)),
                          const SizedBox(height: 8),
                          buildPlayerCircle('B★'),
                        ],
                      ),
                      Column(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: accentColor, width: 2),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: const Icon(Icons.emoji_events, size: 40, color: accentColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'النهائي',
                            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text('فائز المجموعة A', style: GoogleFonts.cairo(fontSize: 11, color: textColor)),
                          const SizedBox(height: 8),
                          buildPlayerCircle('A★'),
                        ],
                      ),
                    ],
                  ),
                  // المجموعة A (يمين)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'المجموعة A',
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      buildSide(groupLabel: 'A', alignRight: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// صفحة الاحتفال بالفائز
class WinnerCelebrationPage extends StatelessWidget {
  const WinnerCelebrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, size: 96, color: Color(0xFFFFD700)),
                  const SizedBox(height: 16),
                  Text(
                    'مبروك يا تاجر النجوم',
                    style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'بطل الجولة الحالية بعد تحقيق 24 طلبًا مسلّمًا.',
                    style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('عرض تاريخ البطولات'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// صفحة إعدادات نظام المسابقات (للأدمن)
class CompetitionSettingsPage extends StatelessWidget {
  const CompetitionSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'إعدادات نظام المسابقات',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ThemeColors.appBarTextColor(isDark),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SettingsField(label: 'عدد الطلبات المطلوب للفوز في الجولة', hint: 'مثال: 10'),
                const SizedBox(height: 12),
                _SettingsField(label: 'مدة الجولة (بالساعات)', hint: 'مثال: 72'),
                const SizedBox(height: 12),
                _SettingsField(
                  label: 'تعيين المجموعات A و B (ID التجار)',
                  hint: 'مثال: user_1, user_2, user_3...',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: const Text('بدء جولة جديدة'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.delete_forever_outlined, size: 20),
                    label: const Text('طرد لاعب يدويًا (لاحقًا بالباك إند)'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  final String label;
  final String hint;
  final int maxLines;

  const _SettingsField({required this.label, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeColors.textColor(isDark)),
        ),
        const SizedBox(height: 6),
        TextField(
          maxLines: maxLines,
          textAlign: TextAlign.right,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
