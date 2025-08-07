@echo off
echo ========================================
echo 🌐 تشغيل موقع منتجاتي محلياً
echo Running Montajati Website Locally
echo ========================================

cd frontend\build\web

echo.
echo 🚀 تشغيل الخادم المحلي...
echo الموقع سيكون متاح على:
echo    http://localhost:8000
echo.
echo 💡 لإيقاف الخادم: اضغط Ctrl+C
echo.

python -m http.server 8000

pause
