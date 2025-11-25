import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';
import '../models/competition.dart';
import '../providers/competitions_provider.dart';

String _two(int n) => n.toString().padLeft(2, '0');
String _fmtDate(DateTime? d) => d == null ? '-' : '${d.year}-${_two(d.month)}-${_two(d.day)}';

class CompetitionsPage extends StatelessWidget {
  const CompetitionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final competitions = context.watch<CompetitionsProvider>().competitions;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'المسابقات',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ThemeColors.appBarTextColor(isDark),
            ),
          ),
        ),
        body: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: competitions.length,
            itemBuilder: (context, index) {
              final competition = competitions[index];
              return _CompetitionCard(competition: competition, isDark: isDark);
            },
          ),
        ),
      ),
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  final Competition competition;
  final bool isDark;

  const _CompetitionCard({required this.competition, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bool achieved = competition.completed >= competition.target && competition.target > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ThemeColors.cardBorder(isDark)),
        boxShadow: [BoxShadow(color: ThemeColors.shadowColor(isDark), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ProgressCircle(completed: competition.completed, target: competition.target, isDark: isDark),
          const SizedBox(width: 36),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  competition.name,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ThemeColors.textColor(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.event, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text(
                      'من: ${_fmtDate(competition.startsAt)} • إلى: ${_fmtDate(competition.endsAt)}',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ThemeColors.secondaryTextColor(isDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(achieved ? Icons.emoji_events : Icons.card_giftcard, size: 18, color: const Color(0xFFFFD700)),
                    const SizedBox(width: 4),
                    Text(
                      competition.prize,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ThemeColors.textColor(isDark),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.flag_outlined, size: 18, color: ThemeColors.secondaryTextColor(isDark)),
                    const SizedBox(width: 4),
                    Text(
                      '${competition.target} \u0637\u0644\u0628',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ThemeColors.textColor(isDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: ThemeColors.secondaryTextColor(isDark)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        competition.product,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ThemeColors.secondaryTextColor(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCircle extends StatelessWidget {
  final int completed;
  final int target;
  final bool isDark;
  const _ProgressCircle({required this.completed, required this.target, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final double progress = target <= 0 ? 0.0 : (completed / target).clamp(0.0, 1.0);
    final bool achieved = completed >= target && target > 0;
    final Color ringColor = achieved
        ? const Color(0xFF1B5E20)
        : (progress < 0.4
              ? const Color(0xFFE53935)
              : (progress < 0.8 ? const Color(0xFFFFC107) : const Color(0xFF43A047)));

    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // نقاط زخرفية حول الدائرة
          _DecorativeDots(isDark: isDark),
          // المسار الخلفي
          SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(ThemeColors.cardBorder(isDark)),
              backgroundColor: Colors.transparent,
            ),
          ),
          // التقدم
          SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
              backgroundColor: Colors.transparent,
            ),
          ),
          // الوسط
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$completed',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ThemeColors.textColor(isDark),
                ),
              ),
              Text(
                'طلبات',
                style: GoogleFonts.cairo(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.secondaryTextColor(isDark),
                ),
              ),
            ],
          ),
          if (achieved)
            Positioned(
              top: 2,
              right: 2,
              child: Icon(
                Icons.star_rounded,
                size: 20,
                color: const Color(0xFFFFD700),
                shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
              ),
            ),
        ],
      ),
    );
  }
}

class _DecorativeDots extends StatelessWidget {
  final bool isDark;
  const _DecorativeDots({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const int count = 8;
    const double radius = 40; // نصف قطر نقاط الزينة (أصغر قليلًا)
    const double dot = 3.5;
    const double cx = 44; // مركز مساحة 88x88
    const double cy = 44;
    final List<Widget> dots = [];
    for (int i = 0; i < count; i++) {
      final double angle = (2 * math.pi / count) * i;
      final double dx = cx + radius * math.cos(angle) - dot / 2;
      final double dy = cy + radius * math.sin(angle) - dot / 2;
      dots.add(
        Positioned(
          left: dx,
          top: dy,
          child: Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: ThemeColors.secondaryTextColor(isDark).withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    return SizedBox(width: 88, height: 88, child: Stack(children: dots));
  }
}
