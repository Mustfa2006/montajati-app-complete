// ===================================
// إعداد قاعدة البيانات الكاملة
// ===================================

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

class DatabaseSetup {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
  }

  // ===================================
  // إنشاء جدول المستخدمين
  // ===================================
  async createUsersTable() {
    console.log('👥 إنشاء جدول المستخدمين...');
    
    const { error } = await this.supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS users (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          email VARCHAR(255) UNIQUE NOT NULL,
          password_hash VARCHAR(255) NOT NULL,
          full_name VARCHAR(255) NOT NULL,
          phone VARCHAR(20),
          role VARCHAR(50) DEFAULT 'user',
          fcm_token TEXT,
          is_active BOOLEAN DEFAULT true,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
        CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
      `
    });
    
    if (error) {
      console.error('❌ خطأ في إنشاء جدول المستخدمين:', error.message);
      return false;
    }
    
    console.log('✅ تم إنشاء جدول المستخدمين');
    return true;
  }

  // ===================================
  // إنشاء جدول المنتجات
  // ===================================
  async createProductsTable() {
    console.log('📦 إنشاء جدول المنتجات...');
    
    const { error } = await this.supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS products (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          name VARCHAR(255) NOT NULL,
          description TEXT,
          price DECIMAL(10,2) NOT NULL,
          stock_quantity INTEGER DEFAULT 0,
          category VARCHAR(100),
          image_url TEXT,
          is_active BOOLEAN DEFAULT true,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
        CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);
      `
    });
    
    if (error) {
      console.error('❌ خطأ في إنشاء جدول المنتجات:', error.message);
      return false;
    }
    
    console.log('✅ تم إنشاء جدول المنتجات');
    return true;
  }

  // ===================================
  // إنشاء جدول الطلبات
  // ===================================
  async createOrdersTable() {
    console.log('🛒 إنشاء جدول الطلبات...');
    
    const { error } = await this.supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS orders (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          order_number VARCHAR(50) UNIQUE NOT NULL,
          customer_id UUID REFERENCES users(id),
          customer_name VARCHAR(255) NOT NULL,
          primary_phone VARCHAR(20) NOT NULL,
          secondary_phone VARCHAR(20),
          address TEXT NOT NULL,
          city VARCHAR(100) NOT NULL,
          total_amount DECIMAL(10,2) NOT NULL,
          status VARCHAR(50) DEFAULT 'pending',
          waseet_order_id VARCHAR(100),
          waseet_status VARCHAR(50),
          waseet_data JSONB,
          last_status_check TIMESTAMP WITH TIME ZONE,
          delivery_notes TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
        CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
        CREATE INDEX IF NOT EXISTS idx_orders_waseet ON orders(waseet_order_id);
        CREATE INDEX IF NOT EXISTS idx_orders_updated ON orders(updated_at);
      `
    });
    
    if (error) {
      console.error('❌ خطأ في إنشاء جدول الطلبات:', error.message);
      return false;
    }
    
    console.log('✅ تم إنشاء جدول الطلبات');
    return true;
  }

  // ===================================
  // إنشاء جدول تاريخ حالات الطلبات
  // ===================================
  async createOrderStatusHistoryTable() {
    console.log('📋 إنشاء جدول تاريخ حالات الطلبات...');
    
    const { error } = await this.supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS order_status_history (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
          old_status VARCHAR(50),
          new_status VARCHAR(50) NOT NULL,
          changed_by VARCHAR(100) DEFAULT 'system',
          change_reason TEXT,
          waseet_response JSONB,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE INDEX IF NOT EXISTS idx_order_history_order ON order_status_history(order_id);
        CREATE INDEX IF NOT EXISTS idx_order_history_created ON order_status_history(created_at);
      `
    });
    
    if (error) {
      console.error('❌ خطأ في إنشاء جدول تاريخ الحالات:', error.message);
      return false;
    }
    
    console.log('✅ تم إنشاء جدول تاريخ حالات الطلبات');
    return true;
  }

  // ===================================
  // إنشاء جدول طلبات السحب
  // ===================================
  async createWithdrawalRequestsTable() {
    console.log('💰 إنشاء جدول طلبات السحب...');
    
    const { error } = await this.supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS withdrawal_requests (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID REFERENCES users(id),
          amount DECIMAL(10,2) NOT NULL,
          status VARCHAR(50) DEFAULT 'pending',
          bank_details JSONB,
          admin_notes TEXT,
          processed_at TIMESTAMP WITH TIME ZONE,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE INDEX IF NOT EXISTS idx_withdrawal_user ON withdrawal_requests(user_id);
        CREATE INDEX IF NOT EXISTS idx_withdrawal_status ON withdrawal_requests(status);
        CREATE INDEX IF NOT EXISTS idx_withdrawal_updated ON withdrawal_requests(updated_at);
      `
    });
    
    if (error) {
      console.error('❌ خطأ في إنشاء جدول طلبات السحب:', error.message);
      return false;
    }
    
    console.log('✅ تم إنشاء جدول طلبات السحب');
    return true;
  }

  // ===================================
  // إنشاء جدول مقدمي الخدمة
  // ===================================
  async createDeliveryProvidersTable() {
    console.log('🚚 إنشاء جدول مقدمي خدمة التوصيل...');
    
    const { error } = await this.supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS delivery_providers (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          name VARCHAR(100) UNIQUE NOT NULL,
          api_url TEXT,
          token TEXT,
          token_expires_at TIMESTAMP WITH TIME ZONE,
          config JSONB,
          is_active BOOLEAN DEFAULT true,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE INDEX IF NOT EXISTS idx_delivery_providers_name ON delivery_providers(name);
        CREATE INDEX IF NOT EXISTS idx_delivery_providers_active ON delivery_providers(is_active);
      `
    });
    
    if (error) {
      console.error('❌ خطأ في إنشاء جدول مقدمي الخدمة:', error.message);
      return false;
    }
    
    console.log('✅ تم إنشاء جدول مقدمي خدمة التوصيل');
    return true;
  }

  // ===================================
  // إنشاء جدول سجل النظام
  // ===================================
  async createSystemLogsTable() {
    console.log('📝 إنشاء جدول سجل النظام...');
    
    const { error } = await this.supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS system_logs (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          event_type VARCHAR(100) NOT NULL,
          event_data JSONB,
          user_id UUID REFERENCES users(id),
          ip_address INET,
          user_agent TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE INDEX IF NOT EXISTS idx_system_logs_type ON system_logs(event_type);
        CREATE INDEX IF NOT EXISTS idx_system_logs_created ON system_logs(created_at);
        CREATE INDEX IF NOT EXISTS idx_system_logs_user ON system_logs(user_id);
      `
    });
    
    if (error) {
      console.error('❌ خطأ في إنشاء جدول سجل النظام:', error.message);
      return false;
    }
    
    console.log('✅ تم إنشاء جدول سجل النظام');
    return true;
  }

  // ===================================
  // إدراج بيانات تجريبية
  // ===================================
  async insertSampleData() {
    console.log('🌱 إدراج بيانات تجريبية...');
    
    try {
      // إدراج مستخدم تجريبي
      const { error: userError } = await this.supabase
        .from('users')
        .upsert({
          email: 'admin@montajati.com',
          password_hash: '$2b$10$example.hash.here',
          full_name: 'مدير النظام',
          phone: '+9647700000000',
          role: 'admin'
        });
      
      if (userError && !userError.message.includes('duplicate')) {
        console.error('❌ خطأ في إدراج المستخدم:', userError.message);
      } else {
        console.log('✅ تم إدراج المستخدم التجريبي');
      }

      // إدراج مقدم خدمة الوسيط
      const { error: providerError } = await this.supabase
        .from('delivery_providers')
        .upsert({
          name: 'alwaseet',
          api_url: 'https://api.alwaseet-iq.net',
          config: {
            username: process.env.WASEET_USERNAME || 'محمد@mustfaabd',
            base_url: process.env.ALMASEET_BASE_URL || 'https://api.alwaseet-iq.net'
          },
          is_active: true
        });
      
      if (providerError && !providerError.message.includes('duplicate')) {
        console.error('❌ خطأ في إدراج مقدم الخدمة:', providerError.message);
      } else {
        console.log('✅ تم إدراج مقدم خدمة الوسيط');
      }

    } catch (error) {
      console.error('❌ خطأ في إدراج البيانات التجريبية:', error.message);
    }
  }

  // ===================================
  // إعداد قاعدة البيانات الكاملة
  // ===================================
  async setupComplete() {
    console.log('🚀 بدء إعداد قاعدة البيانات الكاملة...\n');
    
    const results = [];
    
    results.push(await this.createUsersTable());
    results.push(await this.createProductsTable());
    results.push(await this.createOrdersTable());
    results.push(await this.createOrderStatusHistoryTable());
    results.push(await this.createWithdrawalRequestsTable());
    results.push(await this.createDeliveryProvidersTable());
    results.push(await this.createSystemLogsTable());
    
    await this.insertSampleData();
    
    const successCount = results.filter(r => r).length;
    const totalCount = results.length;
    
    console.log('\n' + '='.repeat(50));
    console.log('📊 نتائج إعداد قاعدة البيانات:');
    console.log(`✅ نجح: ${successCount}/${totalCount} جدول`);
    
    if (successCount === totalCount) {
      console.log('🎉 تم إعداد قاعدة البيانات بنجاح!');
    } else {
      console.log('⚠️ بعض الجداول فشلت في الإنشاء');
    }
    
    console.log('='.repeat(50));
  }
}

// تشغيل الإعداد
if (require.main === module) {
  const setup = new DatabaseSetup();
  setup.setupComplete().catch(console.error);
}

module.exports = DatabaseSetup;
