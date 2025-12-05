import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system.dart';
import '../../../../models/banner_model.dart';
import '../../../../providers/banners_provider.dart';
import '../../../../providers/theme_provider.dart';
import 'bouncing_dots_loader.dart';

/// سلايدر البانرات الإعلانية
class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BannersProvider>().setPageController(_pageController);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Consumer<BannersProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return _buildLoading(isDark);
        }

        if (provider.isEmpty) {
          return _buildEmpty(isDark);
        }

        return _buildSlider(context, provider, isDark);
      },
    );
  }

  Widget _buildLoading(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      height: 180,
      decoration: _bannerDecoration(isDark),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFffd700).withValues(alpha: 0.3)),
                  ),
                ),
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFffd700),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFffd700).withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2),
                    ],
                  ),
                  child: const Icon(Icons.image, color: Colors.white, size: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'جاري تحميل ...',
              style: GoogleFonts.cairo(
                color: const Color(0xFFffd700).withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      height: 180,
      decoration: _bannerDecoration(isDark),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFffd700).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.image_outlined, color: Color(0xFFffd700), size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد إعلانات متاحة',
              style: GoogleFonts.cairo(
                color: const Color(0xFFffd700).withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(BuildContext context, BannersProvider provider, bool isDark) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: provider.banners.length,
            physics: const BouncingScrollPhysics(),
            pageSnapping: true,
            onPageChanged: (index) {
              provider.updateCurrentIndex(index);
              provider.pauseAutoSlide();
            },
            itemBuilder: (context, index) => _buildBannerItem(provider.banners[index], isDark),
          ),
        ),
        if (provider.hasMultipleBanners) _buildDots(provider),
      ],
    );
  }

  Widget _buildBannerItem(BannerModel banner, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFffd700).withValues(alpha: isDark ? 0.4 : 0.3), width: 1.5),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))]
            : [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: 2,
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CachedNetworkImage(
          imageUrl: banner.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => _bannerPlaceholder(isDark),
          errorWidget: (context, url, error) => _bannerPlaceholder(isDark),
        ),
      ),
    );
  }

  Widget _bannerPlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? null : Colors.white,
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppDesignSystem.primaryBackground,
                  const Color(0xFF2D3748).withValues(alpha: 0.8),
                  const Color(0xFF1A202C).withValues(alpha: 0.9),
                ],
              )
            : null,
      ),
      child: Center(child: BouncingDotsLoader(isDark: isDark)),
    );
  }

  Widget _buildDots(BannersProvider provider) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          provider.banners.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: provider.currentIndex == index ? 12 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: provider.currentIndex == index
                  ? const Color(0xFFffd700)
                  : const Color(0xFFffd700).withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _bannerDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? null : Colors.white,
      gradient: isDark
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppDesignSystem.primaryBackground,
                const Color(0xFF2D3748).withValues(alpha: 0.8),
                const Color(0xFF1A202C).withValues(alpha: 0.9),
              ],
            )
          : null,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: const Color(0xFFffd700).withValues(alpha: isDark ? 0.4 : 0.5),
        width: isDark ? 1.5 : 2,
      ),
      boxShadow: isDark
          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))]
          : [BoxShadow(color: Colors.grey.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
    );
  }
}
