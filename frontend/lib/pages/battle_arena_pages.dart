import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';

/// 🏟️ صفحة ساحة المعارك الرئيسية
class BattleArenaHomePage extends StatelessWidget {
  const BattleArenaHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'ساحة معارك التجار',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ThemeColors.appBarTextColor(isDark),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BattleHeaderBanner(isDark: isDark),
                const SizedBox(height: 16),
                _GroupCard(
                  groupName: 'المجموعة A',
                  subtitle: 'دوري التحدي',
                  playersCount: 8,
                  currentRound: 'Round 1',
                  color: const Color(0xFF1E2A3A),
                  onTap: () => Navigator.of(context).pushNamed('/battle-arena/group/A'),
                ),
                const SizedBox(height: 12),
                _GroupCard(
                  groupName: 'المجموعة B',
                  subtitle: 'دوري الأبطال',
                  playersCount: 8,
                  currentRound: 'Round 1',
                  color: const Color(0xFF261C2C),
                  onTap: () => Navigator.of(context).pushNamed('/battle-arena/group/B'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: ThemeColors.cardBorder(isDark)),
                          foregroundColor: ThemeColors.textColor(isDark),
                        ),
                        onPressed: () => Navigator.of(context).pushNamed('/battle-arena/bracket'),
                        icon: const Icon(Icons.timeline_outlined, size: 18),
                        label: const Text('خريطة البطولة'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: ThemeColors.cardBorder(isDark)),
                          foregroundColor: ThemeColors.textColor(isDark),
                        ),
                        onPressed: () => Navigator.of(context).pushNamed('/battle-arena/settings'),
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: const Text('إعدادات المسابقات'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BattleHeaderBanner extends StatelessWidget {
  final bool isDark;

  const _BattleHeaderBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF020617)],
        ),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_martial_arts_outlined, color: Color(0xFFFFD700), size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ساحة معارك التجار',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تنافس على عدد الطلبات المسلّمة فقط خلال كل جولة.',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مدة المباراة', style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70)),
                  Text(
                    '3 أيام • 72 ساعة',
                    style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('نظام الفوز', style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70)),
                  Text(
                    'أكثر عدد طلبات تم تسليمها',
                    style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFFFD700)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String groupName;
  final String subtitle;
  final int playersCount;
  final String currentRound;
  final Color color;
  final VoidCallback onTap;

  const _GroupCard({
    required this.groupName,
    required this.subtitle,
    required this.playersCount,
    required this.currentRound,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.7)],
          ),
          border: Border.all(color: ThemeColors.cardBorder(isDark)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(child: Icon(Icons.shield_outlined, color: Colors.black, size: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    groupName,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text('$playersCount لاعبين', style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.black.withValues(alpha: 0.25),
                        ),
                        child: Text(
                          currentRound,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFFD700),
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
      ),
    );
  }
}
