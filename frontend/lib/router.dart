// router.dart - نظام التنقل لتطبيق منتجاتي

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// استيراد الصفحات
import 'pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/new_products_page.dart';
import 'services/real_auth_service.dart';

import 'pages/new_account_page.dart';
import 'pages/cart_page.dart';

import 'pages/advanced_admin_dashboard.dart';
import 'pages/simple_add_product_page.dart';
import 'pages/orders_page.dart';
import 'pages/modern_product_details_page.dart';
import 'pages/user_order_details_page.dart';
import 'pages/edit_order_page.dart';

import 'pages/profits_page.dart';
import 'pages/statistics_page.dart';
import 'pages/withdraw_page.dart';
import 'pages/withdrawal_history_page.dart';
import 'pages/storage_test_page.dart';
import 'pages/favorites_page.dart';
import 'pages/order_summary_page.dart';
import 'pages/scheduled_orders_main_page.dart';
// import 'pages/protected_system_test_page.dart'; // تم حذف الصفحة
import 'pages/new_system_test_page.dart';


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
      // المسار الجذر - يوجه إلى صفحة المنتجات
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const NewProductsPage(),
      ),

      // صفحة الترحيب
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),

      // صفحة تسجيل الدخول
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // صفحة إنشاء حساب
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      // صفحة المنتجات
      GoRoute(
        path: '/products',
        name: 'products',
        builder: (context, state) => const NewProductsPage(),
        routes: [
          // صفحة تفاصيل المنتج
          GoRoute(
            path: '/details/:productId',
            name: 'product-details',
            builder: (context, state) {
              final productId = state.pathParameters['productId']!;
              return ModernProductDetailsPage(productId: productId);
            },
          ),
        ],
      ),

      // صفحة الطلبات
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) => const OrdersPage(),
        routes: [
          // صفحة تفاصيل الطلب للمستخدم
          GoRoute(
            path: '/details/:orderId',
            name: 'user-order-details',
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              return UserOrderDetailsPage(orderId: orderId);
            },
          ),
          // صفحة تعديل الطلب
          GoRoute(
            path: '/edit/:orderId',
            name: 'edit-order',
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              return EditOrderPage(orderId: orderId);
            },
          ),
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

      // صفحة الأرباح
      GoRoute(
        path: '/profits',
        name: 'profits',
        builder: (context, state) => const ProfitsPage(),
      ),

      // صفحة الإحصائيات
      GoRoute(
        path: '/statistics',
        name: 'statistics',
        builder: (context, state) => const StatisticsPage(),
      ),

      // صفحة سحب الأرباح
      GoRoute(
        path: '/withdraw',
        name: 'withdraw',
        builder: (context, state) => const WithdrawPage(),
      ),

      // صفحة سجل السحب
      GoRoute(
        path: '/profits/withdrawal-history',
        name: 'withdrawal-history',
        builder: (context, state) => const WithdrawalHistoryPage(),
      ),

      // صفحة الحساب الشخصي
      GoRoute(
        path: '/account',
        name: 'account',
        builder: (context, state) => const NewAccountPage(),
      ),

      // صفحة السلة
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartPage(),
      ),

      // صفحة المفضلة
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        builder: (context, state) => const FavoritesPage(),
      ),

      // لوحة التحكم الإدارية
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdvancedAdminDashboard(),
      ),

      // صفحة إضافة منتج
      GoRoute(
        path: '/add-product',
        name: 'add-product',
        builder: (context, state) => const SimpleAddProductPage(),
      ),

      // صفحة اختبار Storage
      GoRoute(
        path: '/storage-test',
        name: 'storage-test',
        builder: (context, state) => const StorageTestPage(),
      ),

      // صفحة ملخص الطلب
      GoRoute(
        path: '/order-summary',
        name: 'order-summary',
        builder: (context, state) {
          final orderData = state.extra as Map<String, dynamic>?;
          if (orderData == null) {
            return const Scaffold(
              body: Center(child: Text('خطأ: لا توجد بيانات طلب')),
            );
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
            Text(
              'الصفحة غير موجودة',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'المسار: ${state.uri}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/welcome'),
              child: const Text('العودة للصفحة الرئيسية'),
            ),
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

  static void goToAccount(BuildContext context) {
    context.go('/account');
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
