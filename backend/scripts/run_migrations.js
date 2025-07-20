#!/usr/bin/env node

// ✅ Script تشغيل Migrations تلقائياً
// Automatic Database Migration Runner
// تاريخ الإنشاء: 2024-12-20

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

class MigrationRunner {
  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    this.migrationsDir = path.join(__dirname, '../database/migrations');
  }

  /**
   * تشغيل جميع migrations
   */
  async runMigrations() {
    try {
      console.log('🚀 بدء تشغيل Database Migrations...');

      // إنشاء جدول migrations إذا لم يكن موجوداً
      await this.createMigrationsTable();

      // الحصول على قائمة migrations المطبقة
      const appliedMigrations = await this.getAppliedMigrations();

      // الحصول على قائمة ملفات migrations
      const migrationFiles = this.getMigrationFiles();

      // تطبيق migrations الجديدة
      for (const file of migrationFiles) {
        if (!appliedMigrations.includes(file)) {
          await this.runMigration(file);
        } else {
          console.log(`⏭️ تم تخطي ${file} (مطبق مسبقاً)`);
        }
      }

      console.log('✅ تم تطبيق جميع Migrations بنجاح!');

    } catch (error) {
      console.error('❌ خطأ في تشغيل Migrations:', error);
      process.exit(1);
    }
  }

  /**
   * إنشاء جدول migrations
   */
  async createMigrationsTable() {
    const query = `
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        filename VARCHAR(255) NOT NULL UNIQUE,
        applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;

    const { error } = await this.supabase.rpc('exec_sql', { sql: query });
    if (error) {
      throw new Error(`خطأ في إنشاء جدول migrations: ${error.message}`);
    }
  }

  /**
   * الحصول على migrations المطبقة
   */
  async getAppliedMigrations() {
    const { data, error } = await this.supabase
      .from('migrations')
      .select('filename');

    if (error) {
      console.warn('⚠️ تحذير: لا يمكن قراءة جدول migrations:', error.message);
      return [];
    }

    return data.map(row => row.filename);
  }

  /**
   * الحصول على ملفات migrations
   */
  getMigrationFiles() {
    if (!fs.existsSync(this.migrationsDir)) {
      console.log('📁 لا توجد مجلد migrations');
      return [];
    }

    return fs.readdirSync(this.migrationsDir)
      .filter(file => file.endsWith('.sql'))
      .sort(); // ترتيب أبجدي
  }

  /**
   * تشغيل migration واحد
   */
  async runMigration(filename) {
    try {
      console.log(`🔄 تطبيق migration: ${filename}`);

      // قراءة محتوى الملف
      const filePath = path.join(this.migrationsDir, filename);
      const sql = fs.readFileSync(filePath, 'utf8');

      // تنفيذ SQL
      const { error } = await this.supabase.rpc('exec_sql', { sql });
      if (error) {
        throw new Error(`خطأ في تنفيذ ${filename}: ${error.message}`);
      }

      // تسجيل Migration كمطبق
      const { error: insertError } = await this.supabase
        .from('migrations')
        .insert({ filename });

      if (insertError) {
        console.warn(`⚠️ تحذير: لا يمكن تسجيل migration ${filename}:`, insertError.message);
      }

      console.log(`✅ تم تطبيق ${filename} بنجاح`);

    } catch (error) {
      console.error(`❌ خطأ في migration ${filename}:`, error.message);
      throw error;
    }
  }

  /**
   * إنشاء migration جديد
   */
  async createMigration(name) {
    const timestamp = new Date().toISOString().slice(0, 19).replace(/[-:]/g, '').replace('T', '_');
    const filename = `${timestamp}_${name}.sql`;
    const filePath = path.join(this.migrationsDir, filename);

    const template = `-- Migration: ${name}
-- تاريخ الإنشاء: ${new Date().toISOString().slice(0, 10)}

-- أضف SQL commands هنا

COMMIT;
`;

    fs.writeFileSync(filePath, template);
    console.log(`✅ تم إنشاء migration جديد: ${filename}`);
  }
}

// تشغيل Script
async function main() {
  const runner = new MigrationRunner();
  
  const command = process.argv[2];
  
  if (command === 'create') {
    const name = process.argv[3];
    if (!name) {
      console.error('❌ يجب تحديد اسم Migration');
      console.log('الاستخدام: node run_migrations.js create migration_name');
      process.exit(1);
    }
    await runner.createMigration(name);
  } else {
    await runner.runMigrations();
  }
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = MigrationRunner;
