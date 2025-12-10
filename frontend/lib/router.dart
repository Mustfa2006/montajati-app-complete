// router.dart - نظام التنقل لتطبيق منتجاتي
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'core/design_system.dart';
import 'pages/advanced_admin_dashboard.dart';
import 'pages/cart_page.dart';
import 'pages/competitions_page.dart';
import 'pages/edit_order_page.dart';
import 'pages/favorites_page.dart';
import 'pages/login_page.dart';
import 'pages/modern_product_details_page.dart';
import 'ui/pages/new_products/new_products_page.dart';
import 'pages/new_system_test_page.dart';
import 'pages/order_summary_page.dart';
import 'pages/orders_page.dart';
import 'pages/profits_page.dart';
import 'pages/register_page.dart';
import 'pages/scheduled_orders_main_page.dart';
import 'pages/statistics_with_tabs_page.dart';
import 'pages/storage_test_page.dart';
import 'pages/top_products_page.dart';
import 'pages/user_order_details_page.dart';
import 'pages/welcome_page.dart';
import 'pages/withdraw_page.dart';
import 'pages/withdrawal_history_page.dart';
import 'services/real_auth_service.dart';
import 'widgets/curved_navigation_bar.dart';

/// 🔙 عرض رسالة تأكيد الخروج
Future<bool> _showExitConfirmation(BuildContext context, bool isDark) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1a1a2e) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.exit_to_app_rounded, color: isDark ? const Color(0xFFFFD700) : const Color(0xFFF59E0B)),
              const SizedBox(width: 10),
              Text(
                'الخروج من التطبيق',
                style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'هل تريد الخروج من التطبيق؟',
            style: GoogleFonts.cairo(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('إلغاء', style: GoogleFonts.cairo(color: isDark ? Colors.white60 : Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFFFFD700) : const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('خروج', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ) ??
      false;
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      try {
        final currentPath = state.uri.toString();

        // التحقق من حالة تسجيل الدخول
        final token = await AuthService.getToken();
        final isLoggedIn = token != null && token.isNotEmpty;

        // إذا كان المستخدم مسجل دخول ويحاول الوصول لصفحات المصادقة
        if (isLoggedIn && (currentPath == '/welcome' || currentPath == '/login' || currentPath == '/register')) {
          return '/products'; // توجيه للمنتجات
        }

        // إذا لم يكن مسجل دخول ويحاول الوصول لصفحات محمية
        if (!isLoggedIn && currentPath != '/welcome' && currentPath != '/login' && currentPath != '/register') {
          return '/welcome'; // توجيه لصفحة الترحيب
        }

        return null; // لا توجيه
      } catch (e) {
        debugPrint('❌ خطأ في redirect: $e');
        // في حالة الخطأ، توجيه لصفحة الترحيب
        return '/welcome';
      }
    },
    routes: [
      // صفحة الترحيب
      GoRoute(path: '/welcome', name: 'welcome', builder: (context, state) => const WelcomePage()),

      // صفحة تسجيل الدخول
      GoRoute(path: '/login', name: 'login', builder: (context, state) => const LoginPage()),

      // صفحة إنشاء حساب
      GoRoute(path: '/register', name: 'register', builder: (context, state) => const RegisterPage()),

      // 📱 صفحة تفاصيل المنتج - خارج ShellRoute لإخفاء الشريط السفلي
      GoRoute(
        path: '/products/details/:productId',
        name: 'product-details',
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          return ModernProductDetailsPage(productId: productId);
        },
      ),

      // 🛒 صفحة السلة - خارج ShellRoute لإخفاء الشريط السفلي
      GoRoute(path: '/cart', name: 'cart', builder: (context, state) => const CartPage()),

      // 📋 صفحة تفاصيل الطلب للمستخدم - خارج ShellRoute لإخفاء الشريط السفلي
      GoRoute(
        path: '/orders/details/:orderId',
        name: 'user-order-details',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return UserOrderDetailsPage(orderId: orderId);
        },
      ),

      // ✏️ صفحة تعديل الطلب - خارج ShellRoute لإخفاء الشريط السفلي
      GoRoute(
        path: '/orders/edit/:orderId',
        name: 'edit-order',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return EditOrderPage(orderId: orderId);
        },
      ),

      // شيل رئيسي يحتوي على الشريط السفلي الموحد للصفحات الرئيسية فقط
      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.path;

          int currentIndex;
          if (location == '/' || location.startsWith('/products') || location.startsWith('/details')) {
            currentIndex = 0; // المنتجات
          } else if (location.startsWith('/orders')) {
            currentIndex = 1; // الطلبات
          } else if (location.startsWith('/profits')) {
            currentIndex = 2; // الأرباح
          } else if (location.startsWith('/competitions')) {
            currentIndex = 3; // المسابقات
          } else {
            currentIndex = 0;
          }

          final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

          // 🎯 التحكم في زر الرجوع
          return PopScope(
            canPop: false, // منع الخروج التلقائي
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;

              // إذا كان يمكن الرجوع في GoRouter
              if (context.canPop()) {
                context.pop();
                return;
              }

              // إذا لم نكن في صفحة المنتجات، اذهب إليها
              if (location != '/products' && location != '/') {
                context.go('/products');
                return;
              }

              // إذا كنا في صفحة المنتجات، اعرض رسالة الخروج
              final shouldExit = await _showExitConfirmation(context, isDark);
              if (shouldExit) {
                SystemNavigator.pop(); // الخروج من التطبيق
              }
            },
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBody: true,
              body: child,
              bottomNavigationBar: CurvedNavigationBar(
                index: currentIndex,
                items: <Widget>[
                  Icon(
                    Icons.storefront_rounded,
                    size: 28,
                    color: isDark ? const Color(0xFFFFD700) : const Color(0xFFF59E0B),
                  ), // shop
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 28,
                    color: isDark ? const Color(0xFFFFD700) : const Color(0xFFF59E0B),
                  ), // orders
                  Icon(
                    Icons.trending_up_rounded,
                    size: 28,
                    color: isDark ? const Color(0xFFFFD700) : const Color(0xFFF59E0B),
                  ), // profits
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 28,
                    color: isDark ? const Color(0xFFFFD700) : const Color(0xFFF59E0B),
                  ), // competitions
                ],
                color: isDark ? AppDesignSystem.bottomNavColor : Colors.white,
                // ✨ تدرج لوني متناسق للوضعين
                gradient: isDark
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2D3748), // رمادي مزرق غامق
                          const Color(0xFF1A202C), // أغمق
                          const Color(0xFF171923), // أسود تقريباً
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      )
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white,
                          const Color(0xFFF8F9FA), // رمادي فاتح جداً
                          const Color(0xFFF1F5F9), // أغمق قليلاً للعمق
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                buttonBackgroundColor: Colors.transparent, // الخلفية شفافة لأن الكرة لها تدرج خاص
                // Leave the notch transparent so الخلفية تظهر من خلال القوس
                backgroundColor: Colors.transparent,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      context.go('/products');
                      break;
                    case 1:
                      context.go('/orders');
                      break;
                    case 2:
                      context.go('/profits');
                      break;
                    case 3:
                      context.go('/competitions');
                      break;
                  }
                },
                letIndexChange: (index) => true,
              ),
            ),
          );
        },
        routes: [
          // المسار الجذر - يوجه إلى صفحة المنتجات
          GoRoute(path: '/', name: 'home', builder: (context, state) => const NewProductsPage()),

          // صفحة المنتجات
          GoRoute(path: '/products', name: 'products', builder: (context, state) => const NewProductsPage()),

          // صفحة الطلبات (بدون sub-routes لأنها خارج ShellRoute)
          GoRoute(path: '/orders', name: 'orders', builder: (context, state) => const OrdersPage()),

          // صفحة المسابقات
          GoRoute(path: '/competitions', name: 'competitions', builder: (context, state) => const CompetitionsPage()),

          // صفحة الأرباح
          GoRoute(path: '/profits', name: 'profits', builder: (context, state) => const ProfitsPage()),

          // صفحة المفضلة
          GoRoute(path: '/favorites', name: 'favorites', builder: (context, state) => const FavoritesPage()),
        ],
      ),

      // صفحة الطلبات المجدولة
      GoRoute(
        path: '/scheduled-orders',
        name: 'scheduled-orders',
        builder: (context, state) => const ScheduledOrdersMainPage(),
        routes: [
          // صفحة تعديل الطلب المجدول
          GoRoute(
            path: '/edit/:orderId',
            name: 'edit-scheduled-order',
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              return EditOrderPage(orderId: orderId, isScheduled: true);
            },
          ),
        ],
      ),

      // صفحة الإحصائيات (مع tabs للإحصائيات وأكثر المنتجات)
      GoRoute(path: '/statistics', name: 'statistics', builder: (context, state) => const StatisticsWithTabsPage()),

      // صفحة أكثر المنتجات مبيعاً
      GoRoute(path: '/top-products', name: 'top-products', builder: (context, state) => const TopProductsPage()),

      // صفحة سحب الأرباح
      GoRoute(path: '/withdraw', name: 'withdraw', builder: (context, state) => const WithdrawPage()),

      // صفحة سجل السحب
      GoRoute(
        path: '/profits/withdrawal-history',
        name: 'withdrawal-history',
        builder: (context, state) => const WithdrawalHistoryPage(),
      ),
      // صفحة اختبار Storage
      GoRoute(path: '/storage-test', name: 'storage-test', builder: (context, state) => const StorageTestPage()),

      // صفحة ملخص الطلب
      GoRoute(
        path: '/order-summary',
        name: 'order-summary',
        builder: (context, state) {
          final orderData = state.extra as Map<String, dynamic>?;
          if (orderData == null) {
            return const Scaffold(body: Center(child: Text('خطأ: لا توجد بيانات طلب')));
          }
          return OrderSummaryPage(orderData: orderData);
        },
      ),

      // صفحة اختبار قاعدة البيانات

      // صفحة اختبار النظام المحمي
      // GoRoute(
      //   path: '/protected-system-test',
      //   name: 'protected-system-test',
      //   builder: (context, state) => const ProtectedSystemTestPage(),
      // ), // تم تعطيل الصفحة المحمية

      // صفحة اختبار النظام الجديد
      GoRoute(
        path: '/new-system-test',
        name: 'new-system-test',
        builder: (context, state) => const NewSystemTestPage(),
      ),

      // صفحة لوحة التحكم الإدارية
      GoRoute(path: '/admin', name: 'admin', builder: (context, state) => const AdvancedAdminDashboard()),

      // صفحة اختبار الإشعارات
    ],

    // معالجة الأخطاء
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('خطأ'), backgroundColor: Colors.red),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('الصفحة غير موجودة', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('المسار: ${state.uri}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => context.go('/welcome'), child: const Text('العودة للصفحة الرئيسية')),
          ],
        ),
      ),
    ),
  );
}

// دوال مساعدة للتنقل
class NavigationHelper {
  static void goToWelcome(BuildContext context) {
    context.go('/welcome');
  }

  static void goToLogin(BuildContext context) {
    context.go('/login');
  }

  static void goToRegister(BuildContext context) {
    context.go('/register');
  }

  static void goToProducts(BuildContext context) {
    context.go('/products');
  }

  static void goToOrders(BuildContext context) {
    context.go('/orders');
  }

  static void goToScheduledOrders(BuildContext context) {
    context.go('/scheduled-orders');
  }

  static void goToProfits(BuildContext context) {
    context.go('/profits');
  }

  static void goToWithdraw(BuildContext context) {
    context.go('/withdraw');
  }

  static void goToCart(BuildContext context) {
    context.go('/cart');
  }

  static void goToFavorites(BuildContext context) {
    context.go('/favorites');
  }

  static void goToAdmin(BuildContext context) {
    context.go('/admin');
  }

  static void goToAddProduct(BuildContext context) {
    context.go('/add-product');
  }

  static void goToStorageTest(BuildContext context) {
    context.go('/storage-test');
  }

  static void goToProtectedSystemTest(BuildContext context) {
    context.go('/protected-system-test');
  }

  static void goToNewSystemTest(BuildContext context) {
    context.go('/new-system-test');
  }

  static void goToNotificationTest(BuildContext context) {
    context.go('/notification-test');
  }
}
