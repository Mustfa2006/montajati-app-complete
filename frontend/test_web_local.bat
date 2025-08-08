@echo off
echo ========================================
echo 🧪 اختبار موقع منتجاتي محلياً
echo ========================================
echo.

echo 📋 التحقق من Flutter...
flutter --version
if %errorlevel% neq 0 (
    echo ❌ Flutter غير مثبت أو غير موجود في PATH
    pause
    exit /b 1
)

echo.
echo 🌐 بناء الموقع للاختبار...
flutter build web --release

echo.
echo 🚀 تشغيل الخادم المحلي...
echo.
echo 📱 للاختبار على الكمبيوتر:
echo    http://localhost:8080
echo.
echo 📱 للاختبار على الهاتف:
echo    1. تأكد من اتصال الهاتف بنفس الشبكة
echo    2. اذهب إلى: http://[عنوان-الكمبيوتر]:8080
echo.
echo 🔍 نصائح الاختبار:
echo    ✅ جرب تسجيل الدخول
echo    ✅ جرب تصفح المنتجات
echo    ✅ جرب إنشاء طلب
echo    ✅ جرب الإشعارات
echo    ✅ جرب إضافة للشاشة الرئيسية (على الهاتف)
echo.
echo 🛑 لإيقاف الخادم: اضغط Ctrl+C
echo.

flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
