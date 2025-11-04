-- ===================================
-- نظام تنظيف FCM Tokens التلقائي في قاعدة البيانات
-- يعمل كل 12 ساعة لحذف الـ tokens المكررة
-- ===================================

-- 1. إنشاء دالة تنظيف FCM Tokens المكررة
CREATE OR REPLACE FUNCTION cleanup_duplicate_fcm_tokens()
RETURNS TABLE(
  user_phone_cleaned TEXT,
  tokens_deleted INTEGER
) AS $$
DECLARE
  user_record RECORD;
  deleted_count INTEGER := 0;
  total_users_cleaned INTEGER := 0;
BEGIN
  -- جلب جميع المستخدمين الذين لديهم أكثر من token واحد (نشط أو غير نشط)
  FOR user_record IN
    SELECT
      user_phone,
      COUNT(*) as token_count
    FROM fcm_tokens
    GROUP BY user_phone
    HAVING COUNT(*) > 1
  LOOP
    -- حذف جميع الـ tokens القديمة والاحتفاظ بالأحدث فقط (بغض النظر عن is_active)
    WITH latest_token AS (
      SELECT id
      FROM fcm_tokens
      WHERE user_phone = user_record.user_phone
      ORDER BY
        COALESCE(last_used_at, created_at) DESC,
        created_at DESC
      LIMIT 1
    )
    DELETE FROM fcm_tokens
    WHERE user_phone = user_record.user_phone
      AND id NOT IN (SELECT id FROM latest_token);

    -- حساب عدد الـ tokens المحذوفة
    GET DIAGNOSTICS deleted_count = ROW_COUNT;

    -- إرجاع النتيجة
    user_phone_cleaned := user_record.user_phone;
    tokens_deleted := deleted_count;
    total_users_cleaned := total_users_cleaned + 1;

    RETURN NEXT;

    RAISE NOTICE '🧹 تم تنظيف % tokens للمستخدم: %', deleted_count, user_record.user_phone;
  END LOOP;

  RAISE NOTICE '✅ تم تنظيف FCM Tokens لـ % مستخدم', total_users_cleaned;

  RETURN;
END;
$$ LANGUAGE plpgsql;

-- 2. دالة لحذف FCM Tokens القديمة جداً - تم تعطيلها
-- ملاحظة: لا نحذف الـ tokens القديمة، فقط نحتفظ بأحدث token لكل مستخدم
CREATE OR REPLACE FUNCTION cleanup_old_fcm_tokens()
RETURNS INTEGER AS $$
BEGIN
  -- تم تعطيل هذه الميزة - لا نحذف tokens قديمة
  RAISE NOTICE '⚠️ ميزة حذف الـ tokens القديمة معطلة - نحتفظ بأحدث token فقط';
  RETURN 0;
END;
$$ LANGUAGE plpgsql;

-- 3. إنشاء دالة رئيسية تجمع كل عمليات التنظيف
CREATE OR REPLACE FUNCTION run_fcm_tokens_cleanup()
RETURNS JSON AS $$
DECLARE
  duplicate_cleanup_result RECORD;
  total_duplicates_deleted INTEGER := 0;
  total_users_cleaned INTEGER := 0;
  result JSON;
BEGIN
  RAISE NOTICE '🧹 ========================================';
  RAISE NOTICE '🧹 بدء تنظيف FCM Tokens التلقائي';
  RAISE NOTICE '🧹 الوقت: %', NOW();
  RAISE NOTICE '🧹 ========================================';

  -- تنظيف الـ tokens المكررة فقط (بدون حذف القديمة)
  FOR duplicate_cleanup_result IN
    SELECT * FROM cleanup_duplicate_fcm_tokens()
  LOOP
    total_duplicates_deleted := total_duplicates_deleted + duplicate_cleanup_result.tokens_deleted;
    total_users_cleaned := total_users_cleaned + 1;
  END LOOP;

  -- إنشاء نتيجة JSON
  result := json_build_object(
    'success', true,
    'timestamp', NOW(),
    'users_cleaned', total_users_cleaned,
    'duplicate_tokens_deleted', total_duplicates_deleted,
    'total_tokens_deleted', total_duplicates_deleted
  );

  RAISE NOTICE '✅ ========================================';
  RAISE NOTICE '✅ اكتمل تنظيف FCM Tokens';
  RAISE NOTICE '✅ المستخدمين المنظفين: %', total_users_cleaned;
  RAISE NOTICE '✅ Tokens المكررة المحذوفة: %', total_duplicates_deleted;
  RAISE NOTICE '✅ ========================================';

  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 4. تفعيل امتداد pg_cron (إذا لم يكن مفعلاً)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 5. حذف أي Cron Job قديم بنفس الاسم
SELECT cron.unschedule('fcm-tokens-cleanup-job');

-- 6. جدولة Cron Job ليعمل كل 12 ساعة
-- يعمل عند الساعة 00:00 و 12:00 كل يوم
SELECT cron.schedule(
  'fcm-tokens-cleanup-job',           -- اسم الـ Job
  '0 */12 * * *',                     -- كل 12 ساعة (عند الساعة 00:00 و 12:00)
  $$SELECT run_fcm_tokens_cleanup()$$ -- الدالة المراد تنفيذها
);

-- 7. إنشاء جدول لحفظ سجل التنظيف (اختياري)
CREATE TABLE IF NOT EXISTS fcm_cleanup_logs (
  id SERIAL PRIMARY KEY,
  users_cleaned INTEGER,
  duplicate_tokens_deleted INTEGER,
  old_tokens_deleted INTEGER,
  total_tokens_deleted INTEGER,
  execution_time TIMESTAMP DEFAULT NOW(),
  result JSON
);

-- 8. تعديل دالة run_fcm_tokens_cleanup لحفظ السجل
CREATE OR REPLACE FUNCTION run_fcm_tokens_cleanup()
RETURNS JSON AS $$
DECLARE
  duplicate_cleanup_result RECORD;
  total_duplicates_deleted INTEGER := 0;
  total_users_cleaned INTEGER := 0;
  result JSON;
BEGIN
  RAISE NOTICE '🧹 ========================================';
  RAISE NOTICE '🧹 بدء تنظيف FCM Tokens التلقائي';
  RAISE NOTICE '🧹 الوقت: %', NOW();
  RAISE NOTICE '🧹 ========================================';

  -- تنظيف الـ tokens المكررة فقط
  FOR duplicate_cleanup_result IN
    SELECT * FROM cleanup_duplicate_fcm_tokens()
  LOOP
    total_duplicates_deleted := total_duplicates_deleted + duplicate_cleanup_result.tokens_deleted;
    total_users_cleaned := total_users_cleaned + 1;
  END LOOP;

  -- إنشاء نتيجة JSON
  result := json_build_object(
    'success', true,
    'timestamp', NOW(),
    'users_cleaned', total_users_cleaned,
    'duplicate_tokens_deleted', total_duplicates_deleted,
    'total_tokens_deleted', total_duplicates_deleted
  );

  -- حفظ السجل في الجدول
  INSERT INTO fcm_cleanup_logs (
    users_cleaned,
    duplicate_tokens_deleted,
    old_tokens_deleted,
    total_tokens_deleted,
    result
  ) VALUES (
    total_users_cleaned,
    total_duplicates_deleted,
    0,  -- لا نحذف tokens قديمة
    total_duplicates_deleted,
    result
  );

  RAISE NOTICE '✅ ========================================';
  RAISE NOTICE '✅ اكتمل تنظيف FCM Tokens';
  RAISE NOTICE '✅ المستخدمين المنظفين: %', total_users_cleaned;
  RAISE NOTICE '✅ Tokens المكررة المحذوفة: %', total_duplicates_deleted;
  RAISE NOTICE '✅ ========================================';

  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 9. تشغيل التنظيف مرة واحدة للاختبار (اختياري)
-- SELECT run_fcm_tokens_cleanup();

-- 10. عرض جميع Cron Jobs المجدولة
SELECT * FROM cron.job WHERE jobname = 'fcm-tokens-cleanup-job';

-- ===================================
-- ملاحظات:
-- ===================================
-- 1. الـ Cron Job يعمل تلقائياً كل 12 ساعة
-- 2. يحذف جميع الـ tokens المكررة ويبقي فقط الأحدث
-- 3. يحذف الـ tokens القديمة (أكثر من 30 يوم بدون استخدام)
-- 4. يحفظ سجل كل عملية تنظيف في جدول fcm_cleanup_logs
-- 5. لإيقاف الـ Cron Job: SELECT cron.unschedule('fcm-tokens-cleanup-job');
-- 6. لتشغيل التنظيف يدوياً: SELECT run_fcm_tokens_cleanup();
-- ===================================

