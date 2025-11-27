// ═══════════════════════════════════════════════════════════════════════════
// 🧮 خدمة حساب ملخص الطلب - Order Calculator Service
// ═══════════════════════════════════════════════════════════════════════════
// ✅ تستدعي Backend API للحسابات
// ✅ لا حسابات محلية - كل شيء من السيرفر
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// 🧮 نتيجة حساب الطلب من السيرفر
class OrderCalculation {
  final bool success;
  final bool validated;
  
  // القيم المحسوبة
  final int subtotal;           // المجموع الفرعي (سعر الجملة)
  final int customerTotal;      // مجموع سعر العميل
  final int deliveryFee;        // رسوم التوصيل التي يدفعها العميل
  final int baseDeliveryFee;    // رسوم التوصيل الأساسية
  final int deliveryPaidFromProfit; // المبلغ المخصوم من الربح
  final int profitInitial;      // الربح الأولي
  final int profitFinal;        // الربح النهائي
  final int totalCustomer;      // المجموع الذي يدفعه العميل
  final int totalWaseet;        // المجموع الكامل للوسيط
  
  // بيانات إضافية
  final String? provinceName;
  final int itemsCount;
  final List<dynamic>? stockErrors;
  final List<String>? warnings;
  final String? error;
  
  OrderCalculation({
    required this.success,
    required this.validated,
    required this.subtotal,
    required this.customerTotal,
    required this.deliveryFee,
    required this.baseDeliveryFee,
    required this.deliveryPaidFromProfit,
    required this.profitInitial,
    required this.profitFinal,
    required this.totalCustomer,
    required this.totalWaseet,
    this.provinceName,
    required this.itemsCount,
    this.stockErrors,
    this.warnings,
    this.error,
  });
  
  factory OrderCalculation.fromJson(Map<String, dynamic> json) {
    return OrderCalculation(
      success: json['success'] ?? false,
      validated: json['validated'] ?? false,
      subtotal: json['subtotal'] ?? 0,
      customerTotal: json['customer_total'] ?? 0,
      deliveryFee: json['delivery_fee'] ?? 0,
      baseDeliveryFee: json['base_delivery_fee'] ?? 0,
      deliveryPaidFromProfit: json['delivery_paid_from_profit'] ?? 0,
      profitInitial: json['profit_initial'] ?? 0,
      profitFinal: json['profit_final'] ?? 0,
      totalCustomer: json['total_customer'] ?? 0,
      totalWaseet: json['total_waseet'] ?? 0,
      provinceName: json['province_name'],
      itemsCount: json['items_count'] ?? 0,
      stockErrors: json['stock_errors'],
      warnings: json['warnings'] != null ? List<String>.from(json['warnings']) : null,
      error: json['error'],
    );
  }
  
  factory OrderCalculation.error(String errorMessage) {
    return OrderCalculation(
      success: false,
      validated: false,
      subtotal: 0,
      customerTotal: 0,
      deliveryFee: 0,
      baseDeliveryFee: 0,
      deliveryPaidFromProfit: 0,
      profitInitial: 0,
      profitFinal: 0,
      totalCustomer: 0,
      totalWaseet: 0,
      itemsCount: 0,
      error: errorMessage,
    );
  }
}

/// 🧮 خدمة حساب الطلب
class OrderCalculatorService {
  static final String _baseUrl = ApiService.baseUrl;
  
  /// 🧮 حساب ملخص الطلب من السيرفر
  /// 
  /// [items] قائمة المنتجات: [{product_id, quantity, customer_price}]
  /// [province] اسم المحافظة
  /// [provinceId] معرف المحافظة (اختياري)
  /// [sliderDeliveryFee] رسوم التوصيل من السلايدر
  static Future<OrderCalculation> calculate({
    required List<Map<String, dynamic>> items,
    String? province,
    String? provinceId,
    String? city,
    String? cityId,
    int sliderDeliveryFee = 0,
  }) async {
    try {
      debugPrint('🧮 ══════════════════════════════════════════');
      debugPrint('🧮 طلب حساب الملخص من السيرفر');
      debugPrint('   المحافظة: $province ($provinceId)');
      debugPrint('   السلايدر: $sliderDeliveryFee');
      debugPrint('   عدد المنتجات: ${items.length}');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/orders/calculate'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'items': items,
          'province': province,
          'province_id': provinceId,
          'city': city,
          'city_id': cityId,
          'slider_delivery_fee': sliderDeliveryFee,
        }),
      ).timeout(const Duration(seconds: 15));
      
      debugPrint('📡 استجابة السيرفر: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = OrderCalculation.fromJson(data);
        
        debugPrint('✅ تم حساب الملخص بنجاح');
        debugPrint('   الربح النهائي: ${result.profitFinal}');
        debugPrint('   المجموع: ${result.totalCustomer}');
        debugPrint('🧮 ══════════════════════════════════════════');
        
        return result;
      } else {
        final errorData = jsonDecode(response.body);
        return OrderCalculation.error(errorData['error'] ?? 'خطأ في الحساب');
      }
    } catch (e) {
      debugPrint('❌ خطأ في حساب الملخص: $e');
      return OrderCalculation.error('فشل الاتصال بالسيرفر: $e');
    }
  }
}

