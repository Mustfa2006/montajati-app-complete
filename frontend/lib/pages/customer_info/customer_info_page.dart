/// 📋 صفحة معلومات العميل
/// CustomerInfoPage - Clean Architecture
///
/// ✅ StatelessWidget - Orchestrator فقط
/// ✅ Provider = Single Source of Truth
/// ✅ لا state محلي
/// ✅ يستخدم Widgets الجديدة
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../providers/customer_info_provider.dart';
import '../../widgets/app_background.dart';
import '../../widgets/pull_to_refresh_wrapper.dart';
import '../../models/province.dart';
import '../../models/city.dart';
import '../order_summary_page.dart';

// Widgets
import 'widgets/customer_header.dart';
import 'widgets/customer_name_field.dart';
import 'widgets/phone_fields.dart';
import 'widgets/notes_field.dart';
import 'widgets/province_field.dart';
import 'widgets/city_field.dart';

import 'widgets/province_modal.dart';
import 'widgets/city_modal.dart';
import 'widgets/premium_navigation_button.dart';

class CustomerInfoPage extends StatelessWidget {
  final Map<String, int> orderTotals;
  final List<dynamic> cartItems;
  final DateTime? scheduledDate;
  final String? scheduleNotes;

  const CustomerInfoPage({
    super.key,
    required this.orderTotals,
    required this.cartItems,
    this.scheduledDate,
    this.scheduleNotes,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomerInfoProvider()..loadProvinces(),
      child: _CustomerInfoContent(
        orderTotals: orderTotals,
        cartItems: cartItems,
        scheduledDate: scheduledDate,
        scheduleNotes: scheduleNotes,
      ),
    );
  }
}

/// المحتوى الداخلي - يستخدم Provider
class _CustomerInfoContent extends StatelessWidget {
  final Map<String, int> orderTotals;
  final List<dynamic> cartItems;
  final DateTime? scheduledDate;
  final String? scheduleNotes;

  const _CustomerInfoContent({
    required this.orderTotals,
    required this.cartItems,
    this.scheduledDate,
    this.scheduleNotes,
  });

  @override
  Widget build(BuildContext context) {
    // isDark يمكن استخدامه لاحقاً للتخصيصات
    final provider = context.watch<CustomerInfoProvider>();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: PullToRefreshWrapper(
            onRefresh: () => provider.refreshData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: AnimationLimiter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 375),
                      childAnimationBuilder: (widget) =>
                          SlideAnimation(verticalOffset: 50.0, child: FadeInAnimation(child: widget)),
                      children: [
                        // 1️⃣ Header
                        const CustomerHeader(),
                        const SizedBox(height: 24),

                        // 2️⃣ اسم المستلم
                        const CustomerNameField(),
                        const SizedBox(height: 20),

                        // 3️⃣ أرقام الهاتف
                        const PhoneFields(),
                        const SizedBox(height: 20),

                        // 4️⃣ حقول الموقع
                        _buildLocationSection(context),
                        const SizedBox(height: 20),

                        // 5️⃣ الملاحظات
                        const NotesField(),
                        const SizedBox(height: 32),

                        // 6️⃣ زر الإرسال

                        // 6️⃣ زر الانتقال (تصميم رهيب)
                        Center(
                          child: PremiumNavigationButton(
                            isEnabled: provider.isFormComplete,
                            onTap: () => _handleSubmit(context),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// قسم الموقع (المحافظة + المدينة)
  Widget _buildLocationSection(BuildContext context) {
    return Column(
      children: [
        // حقل المحافظة
        ProvinceField(onTap: () => _showProvinceModal(context)),
        const SizedBox(height: 16),
        // حقل المدينة
        CityField(onTap: () => _showCityModal(context)),
      ],
    );
  }

  /// فتح Modal المحافظة
  void _showProvinceModal(BuildContext context) {
    final provider = context.read<CustomerInfoProvider>();

    // تنظيف البحث
    provider.provinceSearchController.clear();
    provider.filterProvinces('');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: ProvinceModal(
            onSelected: (Province province) {
              // ✅ تحديد المحافظة عبر Provider
              provider.selectProvince(province);
              // ✅ تحميل المدن
              provider.loadCitiesForProvince(province.id);
              // ✅ إغلاق Modal
              Navigator.pop(modalContext);
            },
            onRetry: () {
              provider.loadProvinces();
            },
          ),
        );
      },
    );
  }

  /// فتح Modal المدينة
  void _showCityModal(BuildContext context) {
    final provider = context.read<CustomerInfoProvider>();

    // تنظيف البحث
    provider.citySearchController.clear();
    provider.filterCities('');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: CityModal(
            onSelected: (City city) {
              // ✅ تحديد المدينة عبر Provider
              provider.selectCity(city);
              // ✅ إغلاق Modal
              Navigator.pop(modalContext);
            },
            onRetry: () {
              final selectedProvince = provider.selectedProvince;
              if (selectedProvince != null) {
                provider.loadCitiesForProvince(selectedProvince.id);
              }
            },
          ),
        );
      },
    );
  }

  /// معالجة الإرسال
  void _handleSubmit(BuildContext context) {
    final provider = context.read<CustomerInfoProvider>();

    // ✅ التحقق من الحقول المطلوبة
    final errorKey = provider.validateRequiredFields();
    final errorMessage = provider.getErrorMessage(errorKey);

    if (errorMessage != null) {
      // ✅ عرض رسالة خطأ مفهومة للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // ✅ بناء OrderDraft
    final orderDraft = provider.buildOrderDraft();
    if (orderDraft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء بناء الطلب'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // ✅ بناء orderData للانتقال إلى OrderSummaryPage
    final orderData = {
      'customerName': orderDraft.customerName,
      'primaryPhone': orderDraft.primaryPhone,
      'secondaryPhone': orderDraft.secondaryPhone,
      'notes': orderDraft.notes,
      'province': orderDraft.province.name,
      'provinceId': orderDraft.province.id,
      'city': orderDraft.city.name,
      'cityId': orderDraft.city.id,
      'regionId': orderDraft.regionId,
      'items': cartItems,
      'totals': orderTotals,
      'scheduledDate': scheduledDate,
      'scheduleNotes': scheduleNotes,
    };

    debugPrint('📦 Order Data: ${orderData['customerName']}, ${orderData['primaryPhone']}');
    debugPrint('📍 Location: ${orderData['province']} - ${orderData['city']}');

    // ✅ الانتقال إلى صفحة ملخص الطلب
    Navigator.push(context, MaterialPageRoute(builder: (context) => OrderSummaryPage(orderData: orderData)));
  }
}
