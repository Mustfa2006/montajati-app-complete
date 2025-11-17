import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';

/// صفحة تفاصيل المجموعة A/B
class BattleGroupPage extends StatelessWidget {
  final String groupId;

  const BattleGroupPage({super.key, required this.groupId});

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
            'المجموعة $groupId – Round 1',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ThemeColors.appBarTextColor(isDark),
            ),
          ),
        ),
        body: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: 4,
            itemBuilder: (context, index) {
              return _MatchCard(
                matchIndex: index + 1,
                traderA: 'تاجر ${index * 2 + 1}',
                traderB: 'تاجر ${index * 2 + 2}',
                aDelivered: 3 + index,
                bDelivered: 1 + index,
                totalTarget: 10,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final int matchIndex;
  final String traderA;
  final String traderB;
  final int aDelivered;
  final int bDelivered;
  final int totalTarget;

  const _MatchCard({
    required this.matchIndex,
    required this.traderA,
    required this.traderB,
    required this.aDelivered,
    required this.bDelivered,
    required this.totalTarget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aProgress = aDelivered / totalTarget;
    final bProgress = bDelivered / totalTarget;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: ThemeColors.cardBackground(isDark),
        border: Border.all(color: ThemeColors.cardBorder(isDark)),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.shadowColor(isDark),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المواجهة $matchIndex', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: ThemeColors.secondaryTextColor(isDark))),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFFFD700)),
                  const SizedBox(width: 4),
                  Text('متبقي 2 يوم و 4 ساعات', style: GoogleFonts.cairo(fontSize: 11, color: ThemeColors.secondaryTextColor(isDark))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _TraderMiniCard(name: traderA, delivered: aDelivered, isLeading: aDelivered >= bDelivered),
              const SizedBox(width: 8),
              _TraderMiniCard(name: traderB, delivered: bDelivered, isLeading: bDelivered > aDelivered),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: aProgress.clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: ThemeColors.cardBorder(isDark),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: bProgress.clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: ThemeColors.cardBorder(isDark),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'الهدف: أول من يسلم $totalTarget طلب',
              style: GoogleFonts.cairo(fontSize: 11, color: ThemeColors.secondaryTextColor(isDark)),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/battle-arena/match'),
              icon: const Icon(Icons.sports_martial_arts_outlined, size: 18),
              label: const Text('عرض المواجهة'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TraderMiniCard extends StatelessWidget {
  final String name;
  final int delivered;
  final bool isLeading;

  const _TraderMiniCard({required this.name, required this.delivered, required this.isLeading});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isLeading ? const Color(0xFF14532D) : Colors.black.withValues(alpha: 0.25),
          border: Border.all(color: isLeading ? const Color(0xFF4ADE80) : Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  child: Text(name.characters.first, style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'طلبات مسلّمة: $delivered',
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

/// صفحة المواجهة 1 ضد 1
class BattleMatchPage extends StatelessWidget {
  const BattleMatchPage({super.key});

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
            'مواجهة تاجر ضد تاجر',
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
              children: [
                Row(
                  children: const [
                    Expanded(child: _MatchTraderPanel(name: 'تاجر A', delivered: 5, color: Color(0xFF4ADE80))),
                    SizedBox(width: 12),
                    Expanded(child: _MatchTraderPanel(name: 'تاجر B', delivered: 3, color: Color(0xFF60A5FA))),
                  ],
                ),
                const SizedBox(height: 16),
                _MatchCenterInfo(isDark: isDark),
                const SizedBox(height: 16),
                Expanded(child: _MatchRecentOrdersList(isDark: isDark)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    label: const Text('عودة للمجموعة'),
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

class _MatchTraderPanel extends StatelessWidget {
  final String name;
  final int delivered;
  final Color color;

  const _MatchTraderPanel({required this.name, required this.delivered, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0.25)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.black.withValues(alpha: 0.2),
                child: Text(name.characters.first, style: GoogleFonts.cairo(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('طلبات مسلّمة: $delivered', style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _MatchCenterInfo extends StatelessWidget {
  final bool isDark;

  const _MatchCenterInfo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: ThemeColors.cardBackground(isDark),
        border: Border.all(color: ThemeColors.cardBorder(isDark)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.timer_outlined, size: 18, color: Color(0xFFFFD700)),
                  SizedBox(width: 4),
                  Text('متبقي 1 يوم و 6 ساعات'),
                ],
              ),
              Text('الهدف: 10 طلبات', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.6,
              minHeight: 8,
              backgroundColor: ThemeColors.cardBorder(isDark),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchRecentOrdersList extends StatelessWidget {
  final bool isDark;

  const _MatchRecentOrdersList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dummy = [
      'زيد سلّم طلب الآن (المجموع: 4)',
      'علي وصل إلى 5 طلبات',
      'زيد سلّم طلب جديد (المجموع: 5)',
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: ThemeColors.cardBackground(isDark),
        border: Border.all(color: ThemeColors.cardBorder(isDark)),
      ),
      padding: const EdgeInsets.all(12),
      child: ListView.separated(
        itemCount: dummy.length,
        itemBuilder: (context, index) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.bolt, size: 18, color: index == 0 ? const Color(0xFFFFD700) : ThemeColors.secondaryTextColor(isDark)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dummy[index],
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(fontSize: 12, color: ThemeColors.textColor(isDark)),
                ),
              ),
            ],
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 12),
      ),
    );
  }
}

