import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
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

      // 🚀 استخدام الباك اند بدلاً من الاتصال المباشر بقاعدة البيانات
      final response = await http
          .post(
            Uri.parse('${ApiConfig.usersUrl}/top-products'),
            headers: ApiConfig.defaultHeaders,
            body: jsonEncode({'phone': currentUserPhone}),
          )
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode != 200) {
        debugPrint('❌ فشل في جلب المنتجات: ${response.statusCode}');
        debugPrint('📥 Response body: ${response.body}');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      debugPrint('✅ استجابة ناجحة من الخادم');

      final jsonData = jsonDecode(response.body);
      debugPrint('📥 Response: $jsonData');

      if (jsonData['success'] != true) {
        debugPrint('⚠️ فشل الطلب: ${jsonData['error'] ?? 'خطأ غير معروف'}');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      if (jsonData['data'] == null) {
        debugPrint('⚠️ لا توجد منتجات');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final List<dynamic> data = jsonData['data'] ?? [];
      debugPrint('📦 عدد المنتجات المسترجعة: ${data.length}');

      if (data.isEmpty) {
        debugPrint('⚠️ لا توجد منتجات - القائمة فارغة');
        if (mounted) {
          setState(() {
            _topProducts = [];
            _isLoading = false;
          });
        }
        return;
      }

      // تحويل النتائج إلى قائمة
      final List<Map<String, dynamic>> products = [];
      for (var item in data) {
        debugPrint('📦 معالجة منتج: ${item['product_name']}');
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

      debugPrint('✅ تم جلب ${products.length} منتج بنجاح');

      if (mounted) {
        setState(() {
          _topProducts = products;
          _isLoading = false;
        });
      }
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
              SliverFillRemaining(
                child: Center(
                  child: BouncingBallsLoader(color: isDark ? const Color(0xFFffd700) : Colors.black87, size: 16.0),
                ),
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
                color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFFffd700).withValues(alpha: 0.3) : Colors.black87,
                  width: 1,
                ),
              ),
              child: Icon(
                FontAwesomeIcons.arrowRight,
                color: isDark ? const Color(0xFFffd700) : Colors.black87,
                size: 18,
              ),
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
                            return Icon(
                              FontAwesomeIcons.image,
                              color: isDark ? const Color(0xFFffd700) : Colors.black87,
                              size: 30,
                            );
                          },
                        ),
                      )
                    : Icon(FontAwesomeIcons.image, color: isDark ? const Color(0xFFffd700) : Colors.black87, size: 30),
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
                          FaIcon(
                            FontAwesomeIcons.trophy,
                            color: isDark ? const Color(0xFFffd700) : Colors.black87,
                            size: 16,
                          ),
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

// 🎨 Widget للـ Loading الرهيب - كرات تقفز بتصميم احترافي
class BouncingBallsLoader extends StatefulWidget {
  final Color color;
  final double size;

  const BouncingBallsLoader({super.key, this.color = const Color(0xFFFFD700), this.size = 12.0});

  @override
  State<BouncingBallsLoader> createState() => _BouncingBallsLoaderState();
}

class _BouncingBallsLoaderState extends State<BouncingBallsLoader> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(vsync: this, duration: const Duration(milliseconds: 600)),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: -10.0, // تقليل الارتفاع إلى 50% فقط
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    // تشغيل الأنيميشن بتأخير متتالي
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
