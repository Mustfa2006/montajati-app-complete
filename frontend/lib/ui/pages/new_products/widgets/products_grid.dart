import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/product.dart';
import '../../../../providers/products_provider.dart';
import 'product_card.dart';
import 'products_empty_state.dart';
import 'products_error_state.dart';
import 'products_loading.dart';
import 'bouncing_dots_loader.dart';

/// شبكة عرض المنتجات - تُستخدم داخل CustomScrollView خارجي
class ProductsGrid extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onRefresh;

  const ProductsGrid({super.key, required this.isDark, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductsProvider>(
      builder: (context, provider, _) {
        // حالة التحميل الأولي
        if (provider.isLoading && provider.products.isEmpty) {
          return const ProductsLoading();
        }

        // حالة الخطأ
        if (provider.hasError && provider.products.isEmpty) {
          return ProductsErrorState(message: provider.errorMessage, onRetry: provider.retry);
        }

        // حالة القائمة الفارغة
        if (provider.isEmpty) {
          return ProductsEmptyState(onRetry: () => provider.loadProducts(forceRefresh: true));
        }

        // عرض المنتجات
        return _buildProductsGrid(context, provider.products, provider);
      },
    );
  }

  Widget _buildProductsGrid(BuildContext context, List<Product> products, ProductsProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columnCount = ProductCard.getSmartColumnCount(screenWidth);
    final aspectRatio = ProductCard.calculateOptimalAspectRatio(context, columnCount);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 200) {
            provider.loadMore();
          }
        }
        return false;
      },
      child: Column(
        children: [
          // الشبكة الأساسية
          Padding(
            padding: _getGridPadding(screenWidth),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnCount,
                childAspectRatio: aspectRatio,
                crossAxisSpacing: _getCrossAxisSpacing(screenWidth),
                mainAxisSpacing: _getMainAxisSpacing(screenWidth),
              ),
              itemBuilder: (context, index) => ProductCard(product: products[index], isDark: isDark),
            ),
          ),
          // مؤشر التحميل المزيد
          if (provider.isLoadingMore)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: BouncingDotsLoader(isDark: isDark)),
            ),
        ],
      ),
    );
  }

  EdgeInsets _getGridPadding(double screenWidth) {
    if (screenWidth > 600) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    } else if (screenWidth > 400) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
    return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
  }

  double _getCrossAxisSpacing(double screenWidth) {
    if (screenWidth > 600) return 14.0;
    if (screenWidth > 400) return 10.0;
    return 6.0;
  }

  double _getMainAxisSpacing(double screenWidth) {
    if (screenWidth > 600) return 14.0;
    if (screenWidth > 400) return 10.0;
    return 6.0;
  }
}
