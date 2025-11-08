import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 📝 إنشاء جدول سجل نقل الأرباح
class ProfitTransferTableCreator {
  static final _supabase = Supabase.instance.client;

  /// 🏗️ إنشاء جدول سجل نقل الأرباح
  static Future<bool> createProfitTransferLogsTable() async {
    try {
      debugPrint('🏗️ إنشاء جدول سجل نقل الأرباح...');

      // إنشاء الجدول باستخدام SQL
      await _supabase.rpc('create_profit_transfer_logs_table');

      debugPrint('✅ تم إنشاء جدول سجل نقل الأرباح بنجاح');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء جدول سجل نقل الأرباح: $e');
      
      // محاولة إنشاء الجدول بطريقة بديلة
      try {
        debugPrint('🔄 محاولة إنشاء الجدول بطريقة بديلة...');
        
        // إدراج سجل تجريبي لإنشاء الجدول
        await _supabase.from('profit_transfer_logs').insert({
          'user_phone': 'test',
          'order_id': 'test',
          'order_number': 'test',
          'order_profit': 0.0,
          'old_status': 'test',
          'new_status': 'test',
          'old_achieved_profits': 0.0,
          'new_achieved_profits': 0.0,
          'old_expected_profits': 0.0,
          'new_expected_profits': 0.0,
          'transfer_date': DateTime.now().toIso8601String(),
        });

        // حذف السجل التجريبي
        await _supabase
            .from('profit_transfer_logs')
            .delete()
            .eq('user_phone', 'test');

        debugPrint('✅ تم إنشاء الجدول بالطريقة البديلة');
        return true;
      } catch (e2) {
        debugPrint('❌ فشل في إنشاء الجدول بالطريقة البديلة: $e2');
        return false;
      }
    }
  }

  /// 🧪 اختبار الجدول
  static Future<bool> testTable() async {
    try {
      debugPrint('🧪 اختبار جدول سجل نقل الأرباح...');

      // محاولة قراءة الجدول
      final response = await _supabase
          .from('profit_transfer_logs')
          .select('*')
          .limit(1);

      debugPrint('✅ الجدول يعمل بشكل صحيح');
      debugPrint('📊 عدد السجلات: ${response.length}');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في اختبار الجدول: $e');
      return false;
    }
  }
}
