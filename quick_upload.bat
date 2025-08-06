@echo off
echo 🚀 رفع ملفات التحديث للخادم...
echo =====================================

echo.
echo 📁 الملفات المطلوب رفعها:
echo - backend\downloads\montajati-v3.6.1.apk
echo - backend\downloads\index.html

echo.
echo 🌐 الوجهة:
echo - https://clownfish-app-krnk9.ondigitalocean.app/downloads/

echo.
echo 📋 تعليمات الرفع:
echo.
echo 1. استخدم لوحة تحكم الاستضافة:
echo    - ادخل للوحة التحكم
echo    - اذهب لـ File Manager  
echo    - انتقل لمجلد public_html/downloads/
echo    - ارفع الملفين

echo.
echo 2. أو استخدم SCP:
echo    scp backend/downloads/montajati-v3.6.1.apk root@clownfish-app-krnk9.ondigitalocean.app:/var/www/html/downloads/
echo    scp backend/downloads/index.html root@clownfish-app-krnk9.ondigitalocean.app:/var/www/html/downloads/

echo.
echo 3. بعد الرفع، اختبر الروابط:
echo    https://clownfish-app-krnk9.ondigitalocean.app/downloads/
echo    https://clownfish-app-krnk9.ondigitalocean.app/downloads/montajati-v3.6.1.apk

echo.
echo ✅ بعد رفع الملفات، النظام سيعمل تلقائياً!
echo.
pause
