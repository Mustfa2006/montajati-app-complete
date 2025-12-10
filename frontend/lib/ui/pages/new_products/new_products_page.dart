import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/banners_provider.dart';
import '../../../providers/products_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/favorites_service.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/drawer_menu.dart';
import '../../../widgets/sliding_drawer.dart';
import 'widgets/banner_slider.dart';
import 'widgets/products_header.dart';
import 'widgets/products_search_bar.dart';
import 'widgets/products_grid.dart';

/// صفحة المنتجات الجديدة - Clean Architecture
/// مطابقة 100% للملف القديم من حيث التصميم والأنيميشن
class NewProductsPage extends StatefulWidget {
  const NewProductsPage({super.key});

  @override
  State<NewProductsPage> createState() => _NewProductsPageState();
}

class _NewProductsPageState extends State<NewProductsPage> {
  final SlidingDrawerController _drawerController = SlidingDrawerController();
  // 🎯 PageStorageKey للحفاظ على موقع التمرير عند الرجوع
  final ScrollController _scrollController = ScrollController();

  // 🔑 مفتاح فريد لحفظ موقع التمرير
  static const _scrollKey = PageStorageKey<String>('products_scroll_position');

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsProvider>().loadProducts();
      context.read<BannersProvider>().loadBanners();
      context.read<FavoritesService>().loadFavorites();
    });
  }

  /// إعداد listener للـ scroll لتحميل المزيد من المنتجات
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (!mounted) return;
      try {
        if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
          final provider = context.read<ProductsProvider>();
          if (!provider.isLoading && !provider.isLoadingMore && provider.hasMore) {
            provider.loadMore();
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<ProductsProvider>().loadProducts(forceRefresh: true),
      context.read<BannersProvider>().loadBanners(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Selector<ThemeProvider, bool>(
      selector: (_, provider) => provider.isDarkMode,
      builder: (context, isDark, _) {
        // ترتيب مطابق للملف القديم:
        // SlidingDrawer → Scaffold → AppBackground → Stack → [خلفية بيضاء + RefreshIndicator]
        return SlidingDrawer(
          controller: _drawerController,
          // معاملات الأنيميشن مطابقة تماماً للملف القديم
          menuWidthFactor: 0.68,
          endScale: 0.85,
          rotationDegrees: -3,
          backgroundColor: isDark ? const Color(0xFF1a1a2e) : const Color(0xFF2c3e50),
          shadowColor: const Color(0xFFffd700),
          menu: DrawerMenu(onClose: () => _drawerController.toggle()),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            body: AppBackground(
              child: Stack(
                children: [
                  // خلفية بيضاء للوضع النهاري (مثل الملف القديم)
                  if (!isDark) Container(color: const Color(0xFFF5F5F7)),
                  RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: const Color(0xFFffd700),
                    backgroundColor: isDark ? const Color(0xFF1a1a2e) : Colors.white,
                    child: CustomScrollView(
                      key: _scrollKey, // 🔑 مفتاح لحفظ موقع التمرير
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      slivers: [
                        // مسافة علوية
                        const SliverToBoxAdapter(child: SizedBox(height: 25)),
                        // Header مع زر القائمة
                        SliverToBoxAdapter(
                          child: ProductsHeader(isDark: isDark, onMenuTap: () => _drawerController.toggle()),
                        ),
                        // البانر الإعلاني
                        const SliverToBoxAdapter(child: BannerSlider()),
                        // شريط البحث
                        SliverToBoxAdapter(child: ProductsSearchBar(isDark: isDark)),
                        // شبكة المنتجات
                        SliverToBoxAdapter(
                          child: ProductsGrid(isDark: isDark, onRefresh: _onRefresh),
                        ),
                        // مسافة سفلية للـ bottom nav
                        const SliverToBoxAdapter(child: SizedBox(height: 160)),
                      ],
                    ),
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
