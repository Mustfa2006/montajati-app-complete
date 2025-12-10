import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/theme_provider.dart';
import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';
import '../models/competition.dart';
import '../providers/competitions_provider.dart';
import '../widgets/competition_card_skeleton.dart';

String _fmtNumber(dynamic n) {
  if (n == null) return '0';
  final num value = n is num ? n : (num.tryParse(n.toString()) ?? 0);
  return NumberFormat('#,###', 'en_US').format(value);
}

String _fmtDate(DateTime? d) {
  if (d == null) return '-';
  return DateFormat('yyyy/MM/dd', 'ar').format(d);
}

class CompetitionsPage extends StatefulWidget {
  const CompetitionsPage({super.key});

  @override
  State<CompetitionsPage> createState() => _CompetitionsPageState();
}

class _CompetitionsPageState extends State<CompetitionsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompetitionsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final provider = context.watch<CompetitionsProvider>();
    final competitions = provider.competitions;
    final currentFilter = provider.currentFilter;
    final isLoading = !provider.isLoaded;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 12),
            _buildTabs(isDark, currentFilter, provider),
            const SizedBox(height: 12),
            if (isLoading)
              _buildLoadingState(isDark)
            else if (competitions.isEmpty)
              _buildEmptyState(isDark, currentFilter)
            else
              ...competitions.map((c) => _CompetitionCard(competition: c, isDark: isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF2D2D2D), const Color(0xFF1F1F1F)] : [Colors.white, const Color(0xFFF8F9FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: ThemeColors.shadowColor(isDark), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المسابقات',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ThemeColors.textColor(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'تابع تقدمك واربح الجوائز',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.secondaryTextColor(isDark),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.star, size: 20, color: const Color(0xFFFFD700).withValues(alpha: 0.7)),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isDark, String currentFilter, CompetitionsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTab(isDark, 'للجميع', 'all', currentFilter, provider)),
          const SizedBox(width: 6),
          Expanded(child: _buildTab(isDark, 'مسابقاتي', 'mine', currentFilter, provider)),
        ],
      ),
    );
  }

  Widget _buildTab(bool isDark, String label, String filter, String currentFilter, CompetitionsProvider provider) {
    final isActive = currentFilter == filter;
    return GestureDetector(
      onTap: () => provider.setFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [BoxShadow(color: ThemeColors.shadowColor(isDark), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? ThemeColors.textColor(isDark) : ThemeColors.secondaryTextColor(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String filter) {
    final isMine = filter == 'mine';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedEmptyIcon(isDark: isDark, isMine: isMine),
            const SizedBox(height: 24),
            Text(
              isMine ? 'لا توجد مسابقات مخصصة لك حالياً' : 'لا توجد مسابقات عامة حالياً',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700, color: ThemeColors.textColor(isDark)),
            ),
            const SizedBox(height: 8),
            Text(
              isMine ? 'ترقب! قد تُخصص لك مسابقة قريباً' : 'عد لاحقاً للاطلاع على المسابقات الجديدة',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ThemeColors.secondaryTextColor(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 3 ? 0 : 12),
          child: CompetitionCardSkeleton(isDark: isDark),
        ),
      ),
    );
  }
}

class _AnimatedEmptyIcon extends StatefulWidget {
  final bool isDark;
  final bool isMine;
  const _AnimatedEmptyIcon({required this.isDark, required this.isMine});
  @override
  State<_AnimatedEmptyIcon> createState() => _AnimatedEmptyIconState();
}

class _AnimatedEmptyIconState extends State<_AnimatedEmptyIcon> with TickerProviderStateMixin {
  late AnimationController _rotateCtrl;
  late AnimationController _bounceCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _rotateAnim;
  late Animation<double> _bounceAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _rotateAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _rotateCtrl, curve: Curves.linear));
    _bounceAnim = Tween<double>(
      begin: 0,
      end: 12,
    ).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));
    _pulseAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _bounceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isMine ? const Color(0xFF6366F1) : const Color(0xFFFFD700);
    return AnimatedBuilder(
      animation: Listenable.merge([_rotateAnim, _bounceAnim, _pulseAnim]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_bounceAnim.value),
          child: Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [baseColor.withValues(alpha: 0.15), baseColor.withValues(alpha: 0.05), Colors.transparent],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating ring
                  Transform.rotate(
                    angle: _rotateAnim.value * 6.28,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: baseColor.withValues(alpha: 0.3),
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                      child: CustomPaint(painter: _DashedCirclePainter(color: baseColor)),
                    ),
                  ),
                  // Inner glow
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [baseColor.withValues(alpha: 0.2), Colors.transparent]),
                    ),
                  ),
                  // Icon
                  Icon(
                    widget.isMine ? Icons.person_outline_rounded : Icons.emoji_events_outlined,
                    size: 48,
                    color: baseColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const dashCount = 12;
    final radius = size.width / 2;
    for (var i = 0; i < dashCount; i++) {
      final startAngle = (i * 2 * 3.14159) / dashCount;
      const sweepAngle = 3.14159 / dashCount;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CompetitionCard extends StatelessWidget {
  final Competition competition;
  final bool isDark;
  const _CompetitionCard({required this.competition, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bool achieved = competition.completed >= competition.target && competition.target > 0;
    final bool ended = competition.endsAt != null && DateTime.now().isAfter(competition.endsAt!);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (competition.productId != null && competition.productId!.isNotEmpty) {
          context.push('/products/details/${competition.productId}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: ThemeColors.cardBackground(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: achieved ? const Color(0xFFFFD700) : ThemeColors.cardBorder(isDark),
            width: achieved ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(color: ThemeColors.shadowColor(isDark), blurRadius: 8, offset: const Offset(0, 2)),
            if (achieved) BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.08), blurRadius: 6),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _ProgressCircle(
                    completed: competition.completed,
                    target: competition.target,
                    isDark: isDark,
                    achieved: achieved,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDetails()),
                ],
              ),
            ),
            if (ended) const Positioned(top: 0, left: 0, child: _EndedChip()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          competition.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: ThemeColors.textColor(isDark)),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.card_giftcard, size: 14, color: Color(0xFFFFD700)),
            const SizedBox(width: 3),
            Text(
              _fmtNumber(competition.prize.replaceAll(RegExp(r'[^\d]'), '')),
              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: ThemeColors.textColor(isDark)),
            ),
            const SizedBox(width: 10),
            Icon(Icons.flag_outlined, size: 14, color: ThemeColors.secondaryTextColor(isDark)),
            const SizedBox(width: 3),
            Text(
              '${_fmtNumber(competition.target)} طلب',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ThemeColors.secondaryTextColor(isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: 12, color: ThemeColors.secondaryTextColor(isDark)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                competition.product,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.secondaryTextColor(isDark),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.event, size: 12, color: ThemeColors.secondaryTextColor(isDark)),
            const SizedBox(width: 4),
            Text(
              'تنتهي: ${_fmtDate(competition.endsAt)}',
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ThemeColors.secondaryTextColor(isDark),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EndedChip extends StatefulWidget {
  const _EndedChip();

  @override
  State<_EndedChip> createState() => _EndedChipState();
}

class _EndedChipState extends State<_EndedChip> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomRight: Radius.circular(10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.5 + _ctrl.value * 0.5),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'منتهية',
            style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
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
  final bool achieved;

  const _ProgressCircle({required this.completed, required this.target, required this.isDark, required this.achieved});

  @override
  Widget build(BuildContext context) {
    final double progress = target > 0 ? (completed / target).clamp(0.0, 1.0) : 0.0;
    final Color progressColor = achieved ? const Color(0xFFFFD700) : (isDark ? Colors.blueAccent : Colors.blue);
    final Color trackColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08);

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          if (achieved)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.4), blurRadius: 8)],
              ),
              child: const Icon(Icons.check, size: 22, color: Colors.white),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$completed',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: ThemeColors.textColor(isDark),
                  ),
                ),
                Container(width: 16, height: 1, color: ThemeColors.secondaryTextColor(isDark).withValues(alpha: 0.3)),
                Text(
                  '$target',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.secondaryTextColor(isDark),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
