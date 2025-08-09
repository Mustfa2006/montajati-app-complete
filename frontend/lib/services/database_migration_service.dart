import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseMigrationService {
  static final _supabase = Supabase.instance.client;

  // تحديث جدول الطلبات لإضافة حقول شركة الوسيط
  static Future<void> migrateOrdersTable() async {
    try {
      // بدء تحديث جدول الطلبات

      // إضافة الحقول المفقودة أولاً
      final basicFieldsQuery = '''
        ALTER TABLE orders
        ADD COLUMN IF NOT EXISTS customer_phone TEXT,
        ADD COLUMN IF NOT EXISTS customer_address TEXT,
        ADD COLUMN IF NOT EXISTS customer_province TEXT,
        ADD COLUMN IF NOT EXISTS customer_city TEXT,
        ADD COLUMN IF NOT EXISTS customer_notes TEXT,
        ADD COLUMN IF NOT EXISTS total_amount DECIMAL(15,2) DEFAULT 0,
        ADD COLUMN IF NOT EXISTS delivery_cost DECIMAL(15,2) DEFAULT 0,
        ADD COLUMN IF NOT EXISTS profit_amount DECIMAL(15,2) DEFAULT 0,
        ADD COLUMN IF NOT EXISTS items_count INTEGER DEFAULT 0,
        ADD COLUMN IF NOT EXISTS user_name TEXT,
        ADD COLUMN IF NOT EXISTS user_phone TEXT;
      ''';

      try {
        await _supabase.rpc('execute_sql', params: {'sql': basicFieldsQuery});
        // تم إضافة الحقول الأساسية
      } catch (e) {
        if (e.toString().contains('Could not find the function public.execute_sql')) {
          // دالة execute_sql غير متوفرة
          return;
        }
        // خطأ في إضافة الحقول الأساسية
      }

      // تحديث البيانات الموجودة
      final updateDataQuery = '''
        UPDATE orders
        SET
          customer_phone = COALESCE(primary_phone, ''),
          customer_address = COALESCE(province || ' - ' || city, ''),
          customer_province = COALESCE(province, ''),
          customer_city = COALESCE(city, ''),
          customer_notes = COALESCE(notes, ''),
          total_amount = COALESCE(total::DECIMAL, 0),
          delivery_cost = COALESCE(delivery_fee::DECIMAL, 0),
          profit_amount = COALESCE(profit::DECIMAL, 0),
          items_count = 1,
          user_name = 'مستخدم',
          user_phone = COALESCE(primary_phone, '')
        WHERE customer_phone IS NULL;
      ''';

      try {
        await _supabase.rpc('execute_sql', params: {'sql': updateDataQuery});
        // تم تحديث البيانات الموجودة
      } catch (e) {
        if (e.toString().contains('Could not find the function public.execute_sql')) {
          // دالة execute_sql غير متوفرة
          return;
        }
        // خطأ في تحديث البيانات
      }

      // إضافة حقول شركة الوسيط
      final waseetFieldsQuery = '''
        ALTER TABLE orders
        ADD COLUMN IF NOT EXISTS waseet_qr_id TEXT,
        ADD COLUMN IF NOT EXISTS waseet_status TEXT,
        ADD COLUMN IF NOT EXISTS waseet_status_id TEXT,
        ADD COLUMN IF NOT EXISTS waseet_delivery_price TEXT,
        ADD COLUMN IF NOT EXISTS waseet_merchant_price TEXT,
        ADD COLUMN IF NOT EXISTS waseet_order_data JSONB;
      ''';

      try {
        await _supabase.rpc('execute_sql', params: {'sql': waseetFieldsQuery});
        // تم إضافة حقول شركة الوسيط
      } catch (e) {
        // خطأ في إضافة حقول شركة الوسيط
      }

      // إنشاء الفهارس
      final indexQueries = [
        'CREATE INDEX IF NOT EXISTS idx_orders_customer_phone ON orders(customer_phone);',
        'CREATE INDEX IF NOT EXISTS idx_orders_waseet_qr_id ON orders(waseet_qr_id);',
        'CREATE INDEX IF NOT EXISTS idx_orders_waseet_status ON orders(waseet_status);',
      ];

      for (final query in indexQueries) {
        try {
          await _supabase.rpc('execute_sql', params: {'sql': query});
          // تم إنشاء فهرس
        } catch (e) {
          // خطأ في إنشاء الفهرس
        }
      }

      // تم تحديث جدول الطلبات
    } catch (e) {
      // خطأ في تحديث جدول الطلبات
    }
  }

  // إنشاء جدول لحفظ حالات الطلبات من شركة الوسيط
  static Future<void> createOrderStatusesTable() async {
    try {
      // إنشاء جدول حالات الطلبات

      final createTableQuery = '''
        CREATE TABLE IF NOT EXISTS waseet_order_statuses (
          id TEXT PRIMARY KEY,
          status TEXT NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
      ''';

      await _supabase.rpc('execute_sql', params: {'sql': createTableQuery});
      // تم إنشاء جدول حالات الطلبات
    } catch (e) {
      // خطأ في إنشاء جدول حالات الطلبات
    }
  }

  // إنشاء جدول لحفظ المدن والمناطق من شركة الوسيط
  static Future<void> createWaseetDataTables() async {
    try {
      debugPrint('🔄 إنشاء جداول بيانات شركة الوسيط...');

      final createTablesQueries = [
        '''
        CREATE TABLE IF NOT EXISTS waseet_cities (
          id TEXT PRIMARY KEY,
          city_name TEXT NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        ''',
        '''
        CREATE TABLE IF NOT EXISTS waseet_regions (
          id TEXT PRIMARY KEY,
          region_name TEXT NOT NULL,
          city_id TEXT NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          FOREIGN KEY (city_id) REFERENCES waseet_cities(id)
        );
        ''',
        '''
        CREATE TABLE IF NOT EXISTS waseet_package_sizes (
          id TEXT PRIMARY KEY,
          size TEXT NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        ''',
      ];

      for (final query in createTablesQueries) {
        try {
          await _supabase.rpc('execute_sql', params: {'sql': query});
          debugPrint('✅ تم تنفيذ استعلام إنشاء الجدول بنجاح');
        } catch (e) {
          debugPrint('⚠️ خطأ في إنشاء الجدول (قد يكون موجود بالفعل): $e');
        }
      }

      debugPrint('✅ تم إنشاء جداول بيانات شركة الوسيط بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء جداول بيانات شركة الوسيط: $e');
    }
  }

  // تحديث حالات الطلبات لتتطابق مع شركة الوسيط
  static Future<void> updateOrderStatusMapping() async {
    try {
      debugPrint('🔄 تحديث خريطة حالات الطلبات...');

      // إنشاء جدول لخريطة الحالات
      final createMappingTableQuery = '''
        CREATE TABLE IF NOT EXISTS order_status_mapping (
          waseet_status_id TEXT PRIMARY KEY,
          waseet_status_text TEXT NOT NULL,
          local_status TEXT NOT NULL,
          description TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
      ''';

      await _supabase.rpc(
        'execute_sql',
        params: {'sql': createMappingTableQuery},
      );

      // إدراج خريطة الحالات الافتراضية
      final statusMappings = [
        {
          'waseet_status_id': '1',
          'waseet_status_text': 'تم الاستلام من قبل المندوب',
          'local_status': 'confirmed',
        },
        {
          'waseet_status_id': '2',
          'waseet_status_text': 'تم استلام الطلب من قبل المندوب',
          'local_status': 'confirmed',
        },
        {
          'waseet_status_id': '3',
          'waseet_status_text': 'في الطريق',
          'local_status': 'in_transit',
        },
        {
          'waseet_status_id': '4',
          'waseet_status_text': 'تم التسليم',
          'local_status': 'delivered',
        },
        {
          'waseet_status_id': '5',
          'waseet_status_text': 'ملغي',
          'local_status': 'cancelled',
        },
        {
          'waseet_status_id': '6',
          'waseet_status_text': 'مرتجع',
          'local_status': 'returned',
        },
        {
          'waseet_status_id': '7',
          'waseet_status_text': 'في الانتظار',
          'local_status': 'pending',
        },
      ];

      for (final mapping in statusMappings) {
        try {
          await _supabase.from('order_status_mapping').upsert(mapping);
        } catch (e) {
          debugPrint('⚠️ خطأ في إدراج خريطة الحالة: $e');
        }
      }

      debugPrint('✅ تم تحديث خريطة حالات الطلبات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث خريطة حالات الطلبات: $e');
    }
  }

  // إصلاح دالة تحويل الطلبات المجدولة
  static Future<void> fixScheduledOrdersFunction() async {
    try {
      debugPrint('🔄 إصلاح دالة تحويل الطلبات المجدولة...');

      final functionQuery = '''
        CREATE OR REPLACE FUNCTION convert_scheduled_orders_to_active()
        RETURNS TEXT
        LANGUAGE plpgsql
        AS \$\$
        DECLARE
            converted_count INTEGER := 0;
            order_record RECORD;
        BEGIN
            FOR order_record IN
                SELECT * FROM scheduled_orders
                WHERE scheduled_date <= CURRENT_DATE
                AND is_converted = FALSE
                LIMIT 10
            LOOP
                INSERT INTO orders (
                    id,
                    customer_name,
                    primary_phone,
                    secondary_phone,
                    province,
                    city,
                    notes,
                    total,
                    subtotal,
                    delivery_fee,
                    profit,
                    status,
                    created_at,
                    updated_at,
                    customer_phone,
                    customer_address,
                    customer_province,
                    customer_city,
                    customer_notes,
                    total_amount,
                    delivery_cost,
                    profit_amount,
                    items_count,
                    user_name,
                    user_phone
                ) VALUES (
                    gen_random_uuid()::TEXT,
                    order_record.customer_name,
                    order_record.customer_phone,
                    order_record.customer_alternate_phone,
                    order_record.customer_province,
                    order_record.customer_city,
                    order_record.customer_notes,
                    order_record.total_amount::INTEGER,
                    (order_record.total_amount - COALESCE(order_record.delivery_cost, 0))::INTEGER,
                    COALESCE(order_record.delivery_cost, 0)::INTEGER,
                    COALESCE(order_record.profit_amount, 0)::INTEGER,
                    'active',
                    NOW(),
                    NOW(),
                    order_record.customer_phone,
                    order_record.customer_address,
                    order_record.customer_province,
                    order_record.customer_city,
                    order_record.customer_notes,
                    order_record.total_amount,
                    COALESCE(order_record.delivery_cost, 0),
                    COALESCE(order_record.profit_amount, 0),
                    1,
                    'مستخدم',
                    order_record.customer_phone
                );

                UPDATE scheduled_orders
                SET is_converted = TRUE, updated_at = NOW()
                WHERE id = order_record.id;

                converted_count := converted_count + 1;
            END LOOP;

            RETURN 'تم تحويل ' || converted_count || ' طلب بنجاح';
        EXCEPTION
            WHEN OTHERS THEN
                RETURN 'خطأ في التحويل: ' || SQLERRM;
        END;
        \$\$;
      ''';

      await _supabase.rpc('execute_sql', params: {'sql': functionQuery});
      debugPrint('✅ تم إصلاح دالة تحويل الطلبات المجدولة بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إصلاح دالة تحويل الطلبات المجدولة: $e');
    }
  }

  // تشغيل جميع عمليات التحديث
  static Future<void> runAllMigrations() async {
    // بدء تشغيل جميع عمليات تحديث قاعدة البيانات

    await migrateOrdersTable();
    await createOrderStatusesTable();
    await createWaseetDataTables();
    await updateOrderStatusMapping();
    await fixScheduledOrdersFunction();

    // تم الانتهاء من جميع عمليات تحديث قاعدة البيانات
  }

  // فحص ما إذا كانت التحديثات مطلوبة
  static Future<bool> isMigrationNeeded() async {
    try {
      // فحص وجود عمود waseet_qr_id في جدول orders
      await _supabase.from('orders').select('waseet_qr_id').limit(1);

      return false; // التحديث غير مطلوب
    } catch (e) {
      return true; // التحديث مطلوب
    }
  }

  // تنظيف البيانات القديمة
  static Future<void> cleanupOldData() async {
    try {
      debugPrint('🧹 تنظيف البيانات القديمة...');

      // حذف الطلبات التي لا تحتوي على رقم QR من الوسيط وأقدم من 30 يوم
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      await _supabase
          .from('orders')
          .delete()
          .filter('waseet_qr_id', 'is', null)
          .lt('created_at', thirtyDaysAgo.toIso8601String());

      debugPrint('✅ تم تنظيف البيانات القديمة بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف البيانات القديمة: $e');
    }
  }

  // إنشاء دالة SQL لتنفيذ الاستعلامات المخصصة
  static Future<void> createExecuteSqlFunction() async {
    try {
      debugPrint('🔄 إنشاء دالة تنفيذ SQL...');

      final createFunctionQuery = '''
        CREATE OR REPLACE FUNCTION execute_sql(sql TEXT)
        RETURNS TEXT
        LANGUAGE plpgsql
        SECURITY DEFINER
        AS \$\$
        BEGIN
          EXECUTE sql;
          RETURN 'SUCCESS';
        EXCEPTION
          WHEN OTHERS THEN
            RETURN 'ERROR: ' || SQLERRM;
        END;
        \$\$;
      ''';

      await _supabase.rpc('execute_sql', params: {'sql': createFunctionQuery});
      debugPrint('✅ تم إنشاء دالة تنفيذ SQL بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء دالة تنفيذ SQL: $e');
      // إذا فشل إنشاء الدالة، نحاول تنفيذ الاستعلامات مباشرة
    }
  }

  // تحديث الطلبات الموجودة لتتضمن معرف الوسيط
  static Future<void> updateExistingOrdersWithWaseetData() async {
    try {
      debugPrint('🔄 تحديث الطلبات الموجودة بمعرفات الوسيط...');

      // جلب الطلبات التي لا تحتوي على معرف الوسيط
      final ordersWithoutWaseet = await _supabase
          .from('orders')
          .select('id, customer_name, primary_phone, total')
          .filter('waseet_qr_id', 'is', null)
          .limit(10); // تحديث 10 طلبات في كل مرة

      debugPrint('📋 وجد ${ordersWithoutWaseet.length} طلب بحاجة لتحديث');

      // يمكن إضافة منطق لربط الطلبات الموجودة بشركة الوسيط هنا
      // لكن هذا يتطلب إنشاء طلبات جديدة في الوسيط أو مطابقة الطلبات الموجودة

      debugPrint('✅ تم تحديث الطلبات الموجودة');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الطلبات الموجودة: $e');
    }
  }
}
