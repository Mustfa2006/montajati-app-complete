@echo off
echo 🚀 رفع ملفات التحديث للخادم...
echo =====================================

echo.
echo 📁 الملفات المطلوب رفعها:
echo - backend\downloads\montajati-v3.6.1.apk
echo - backend\downloads\index.html

echo.
echo 🌐 الوجهة:
echo - https://montajati-official-backend-production.up.railway.app/downloads/

echo.
echo 📋 تعليمات الرفع:
echo.
echo 1. استخدم لوحة تحكم الاستضافة:
echo    - ادخل للوحة التحكم
echo    - اذهب لـ File Manager  
echo    - انتقل لمجلد public_html/downloads/
echo    - ارفع الملفين

echo.
echo 2. أو استخدم Railway CLI:
echo    railway deploy

echo.
echo 3. بعد الرفع، اختبر الروابط:
echo    https://montajati-official-backend-production.up.railway.app/downloads/
echo    https://montajati-official-backend-production.up.railway.app/downloads/montajati-v3.6.1.apk

echo.
echo ✅ بعد رفع الملفات، النظام سيعمل تلقائياً!
echo.
pause
