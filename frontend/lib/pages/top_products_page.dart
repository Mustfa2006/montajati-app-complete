import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/theme_provider.dart';
import '../utils/theme_colors.dart';
import '../widgets/app_background.dart';

class TopProductsPage extends StatefulWidget {
  const TopProductsPage({super.key});

  @override
  State<TopProductsPage> createState() => _TopProductsPageState();
}

class _TopProductsPageState extends State<TopProductsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _topProducts = [];

  @override
  void initState() {
    super.initState();
    _loadTopProducts();
  }

  Future<void> _loadTopProducts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final currentUserPhone = prefs.getString('current_user_phone');

      if (currentUserPhone == null) {
        debugPrint('⚠️ لا يوجد رقم مستخدم');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      debugPrint('🔍 جلب المنتجات الأكثر مبيعاً للمستخدم: $currentUserPhone');

      // استخدام RPC أو استعلام مباشر للحصول على المنتجات من order_items
      // نستخدم استعلام SQL مباشر لأنه أكثر كفاءة
      final response = await Supabase.instance.client.rpc(
        'get_top_products_for_user',
        params: {'p_user_phone': currentUserPhone},
      );

      debugPrint('📦 عدد المنتجات المسترجعة: ${response.length}');

      if (response == null || response.isEmpty) {
        debugPrint('⚠️ لا توجد منتجات');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // تحويل النتائج إلى قائمة
      final List<Map<String, dynamic>> products = [];
      for (var item in response) {
        products.add({
          'product_id': item['product_id'],
          'product_name': item['product_name'],
          'product_image': item['product_image'],
          'total_orders': item['total_orders'],
          'total_quantity': item['total_quantity'],
          'delivered_orders': item['delivered_orders'],
          'cancelled_orders': item['cancelled_orders'],
          'total_profit': (item['total_profit'] ?? 0).toDouble(),
        });
      }

      debugPrint('✅ تم جلب ${products.length} منتج');

      setState(() {
        _topProducts = products;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في جلب المنتجات الأكثر مبيعاً: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: const SizedBox(height: 25)),
            SliverToBoxAdapter(child: _buildHeader(isDark)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),

            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Color(0xFFffd700))),
              )
            else if (_topProducts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'لا توجد منتجات',
                    style: GoogleFonts.cairo(fontSize: 18, color: ThemeColors.textColor(isDark)),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = _topProducts[index];
                  return _buildProductCard(product, index, isDark);
                }, childCount: _topProducts.length),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFffd700).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 1),
              ),
              child: const Icon(FontAwesomeIcons.arrowRight, color: Color(0xFFffd700), size: 18),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              'أكثر المنتجات مبيعاً',
              style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: ThemeColors.textColor(isDark)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 55),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index, bool isDark) {
    final productName = product['product_name'] ?? 'منتج غير معروف';
    final productImage = product['product_image'];
    final totalOrders = product['total_orders'] ?? 0;
    final deliveredOrders = product['delivered_orders'] ?? 0;
    final cancelledOrders = product['cancelled_orders'] ?? 0;
    final totalProfit = (product['total_profit'] ?? 0.0).toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: index == 0 ? const Color(0xFFffd700) : const Color(0xFFffd700).withValues(alpha: 0.3),
          width: index == 0 ? 2 : 1,
        ),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // صورة المنتج واسمه
          Row(
            children: [
              // صورة المنتج
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFffd700).withValues(alpha: 0.3), width: 1),
                ),
                child: productImage != null && productImage.toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          productImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(FontAwesomeIcons.image, color: Color(0xFFffd700), size: 30);
                          },
                        ),
                      )
                    : const Icon(FontAwesomeIcons.image, color: Color(0xFFffd700), size: 30),
              ),
              const SizedBox(width: 15),
              // اسم المنتج
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index == 0)
                      Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.trophy, color: Color(0xFFffd700), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'الأكثر مبيعاً',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFffd700),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 5),
                    Text(
                      productName,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.textColor(isDark),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // الإحصائيات
          Row(
            children: [
              // عدد الطلبات
              Expanded(
                child: _buildStatBox(
                  label: 'عدد الطلبات',
                  value: totalOrders.toString(),
                  color: const Color(0xFFffd700),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              // الواصل
              Expanded(
                child: _buildStatBox(
                  label: 'الواصل',
                  value: deliveredOrders.toString(),
                  color: Colors.green,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // الملغي
              Expanded(
                child: _buildStatBox(
                  label: 'ملغي',
                  value: cancelledOrders.toString(),
                  color: Colors.red,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              // الربح الإجمالي
              Expanded(
                child: _buildStatBox(
                  label: 'الربح',
                  value: '${_formatNumber(totalProfit)} د.ع',
                  color: const Color(0xFF4CAF50),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // دالة لتنسيق الأرقام بفواصل
  String _formatNumber(double number) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(number.round());
  }

  Widget _buildStatBox({required String label, required String value, required Color color, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 11, color: ThemeColors.secondaryTextColor(isDark))),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
