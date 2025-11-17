import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';

class CompetitionsPage extends StatelessWidget {
  const CompetitionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    const competitions = _dummyCompetitions;

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
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton.icon(
                onPressed: () => context.push('/battle-arena'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD700),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: const Icon(Icons.sports_martial_arts_outlined, size: 20),
                label: Text('ساحة المعركة', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
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

class _Competition {
  final String name;
  final String type;
  final String product;
  final double progress;

  const _Competition({required this.name, required this.type, required this.product, required this.progress});
}

const List<_Competition> _dummyCompetitions = <_Competition>[
  _Competition(name: 'مسابقة أفضل بائع هذا الشهر', type: 'شهرية', product: 'حقيبة ظهر جلد فاخرة', progress: 0.65),
  _Competition(name: 'تحدي 100 طلب في أسبوع', type: 'أسبوعية', product: 'ساعة يد ذكية', progress: 0.4),
  _Competition(name: 'مسابقة إطلاق منتج جديد', type: 'خاصة', product: 'سماعات بلوتوث احترافية', progress: 0.8),
];

class _CompetitionCard extends StatelessWidget {
  final _Competition competition;
  final bool isDark;

  const _CompetitionCard({required this.competition, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ThemeColors.cardBorder(isDark)),
        boxShadow: [BoxShadow(color: ThemeColors.shadowColor(isDark), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            competition.name,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700, color: ThemeColors.textColor(isDark)),
          ),
          const SizedBox(height: 4),
          Text(
            competition.type,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ThemeColors.secondaryTextColor(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'المنتج: ${competition.product}',
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: ThemeColors.textColor(isDark)),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: LinearProgressIndicator(
                value: competition.progress,
                backgroundColor: ThemeColors.cardBorder(isDark),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(competition.progress * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ThemeColors.secondaryTextColor(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
