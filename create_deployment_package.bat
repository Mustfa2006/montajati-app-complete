@echo off
echo ========================================
echo 📦 إنشاء حزمة النشر لـ DigitalOcean
echo Creating Deployment Package for DigitalOcean
echo ========================================

cd frontend\build\web

echo.
echo 📁 إنشاء مجلد النشر...
if not exist "..\..\deployment" mkdir "..\..\deployment"

echo.
echo 📋 نسخ الملفات...
xcopy /E /I /Y . "..\..\deployment\montajati-web"

echo.
echo 📦 ضغط الملفات...
powershell Compress-Archive -Path "..\..\deployment\montajati-web\*" -DestinationPath "..\..\deployment\montajati-website.zip" -Force

echo.
echo ✅ تم إنشاء حزمة النشر بنجاح!
echo 📁 الملف: deployment\montajati-website.zip
echo 📊 حجم الحزمة: 
dir "..\..\deployment\montajati-website.zip"

echo.
echo 🚀 الخطوات التالية:
echo 1. اذهب إلى cloud.digitalocean.com
echo 2. انقر Create → Apps
echo 3. اختر "Upload your source code"
echo 4. ارفع ملف montajati-website.zip
echo 5. اتبع التعليمات

pause
