@echo off
echo ===================================
echo تحسين التطبيق للويندوز
echo Optimizing App for Windows
echo ===================================

echo.
echo 🔧 تنظيف شامل...
echo Deep cleaning...
flutter clean
if exist "build" rmdir /s /q "build"
if exist ".dart_tool" rmdir /s /q ".dart_tool"

echo.
echo 📦 تحديث Flutter...
echo Updating Flutter...
flutter upgrade

echo.
echo 📋 تحديث الحزم...
echo Updating packages...
flutter pub upgrade

echo.
echo 🔍 فحص المشاكل...
echo Checking for issues...
flutter doctor

echo.
echo 🏗️ بناء محسن للويندوز...
echo Optimized Windows build...
flutter build windows --release --verbose --tree-shake-icons --split-debug-info=debug_symbols --obfuscate

echo.
echo 📁 إنشاء حزمة التوزيع المحسنة...
echo Creating optimized distribution package...
if not exist "release" mkdir release
if not exist "release\montajati_v3.3.0_windows" mkdir release\montajati_v3.3.0_windows

echo.
echo 📋 نسخ الملفات المحسنة...
echo Copying optimized files...
xcopy "build\windows\x64\runner\Release\*" "release\montajati_v3.3.0_windows\" /E /I /Y

echo.
echo 📝 إنشاء ملفات التوثيق...
echo Creating documentation files...

REM إنشاء ملف التعليمات
(
echo تطبيق منتجاتي - الإصدار 3.3.0
echo ===============================
echo.
echo 🚀 مرحباً بك في تطبيق منتجاتي!
echo.
echo 📋 تعليمات التشغيل:
echo 1. تأكد من اتصالك بالإنترنت
echo 2. انقر نقراً مزدوجاً على montajati_app.exe
echo 3. انتظر تحميل التطبيق ^(قد يستغرق دقيقة في المرة الأولى^)
echo 4. استمتع بتجربة التسوق والدروب شوبينغ!
echo.
echo 💻 متطلبات النظام:
echo - ويندوز 10 ^(الإصدار 1903^) أو أحدث
echo - ذاكرة وصول عشوائي: 4 جيجابايت على الأقل
echo - مساحة تخزين: 500 ميجابايت
echo - اتصال مستقر بالإنترنت
echo.
echo 🔧 استكشاف الأخطاء:
echo - إذا لم يعمل التطبيق، تأكد من تشغيله كمدير
echo - تأكد من عدم حجب برنامج مكافحة الفيروسات للتطبيق
echo - أعد تشغيل الكمبيوتر إذا واجهت مشاكل
echo.
echo 📞 الدعم الفني:
echo - البريد الإلكتروني: support@montajati.com
echo - الواتساب: +964 XXX XXX XXXX
echo - الموقع الإلكتروني: https://montajati.com
echo.
echo 📊 معلومات الإصدار:
echo - رقم الإصدار: 3.3.0+10
echo - تاريخ البناء: %date% %time%
echo - نوع البناء: Release ^(محسن^)
echo.
echo 🎉 شكراً لاستخدامك تطبيق منتجاتي!
) > "release\montajati_v3.3.0_windows\تعليمات_التشغيل.txt"

REM إنشاء ملف الترخيص
(
echo تطبيق منتجاتي - اتفاقية الترخيص
echo ================================
echo.
echo حقوق الطبع والنشر ^(c^) 2024 منتجاتي
echo جميع الحقوق محفوظة.
echo.
echo هذا التطبيق مرخص للاستخدام الشخصي والتجاري.
echo يُمنع إعادة توزيع أو تعديل التطبيق بدون إذن مكتوب.
echo.
echo للمزيد من المعلومات، يرجى زيارة:
echo https://montajati.com/license
) > "release\montajati_v3.3.0_windows\الترخيص.txt"

REM إنشاء ملف الإعدادات
(
echo {
echo   "app_name": "منتجاتي",
echo   "version": "3.3.0",
echo   "build": "10",
echo   "platform": "windows",
echo   "build_date": "%date%",
echo   "build_time": "%time%",
echo   "optimization": "release",
echo   "features": [
echo     "دروب شوبينغ",
echo     "إدارة المنتجات",
echo     "تتبع الطلبات",
echo     "إشعارات فورية",
echo     "تقارير مفصلة"
echo   ]
echo }
) > "release\montajati_v3.3.0_windows\app_info.json"

echo.
echo 🗜️ ضغط الحزمة...
echo Compressing package...
powershell -command "Compress-Archive -Path 'release\montajati_v3.3.0_windows\*' -DestinationPath 'release\montajati_v3.3.0_windows.zip' -Force"

echo.
echo ✅ تم إنشاء التطبيق المحسن بنجاح!
echo Optimized app created successfully!
echo.
echo 📍 مسار التطبيق: release\montajati_v3.3.0_windows\
echo App location: release\montajati_v3.3.0_windows\
echo.
echo 📦 الحزمة المضغوطة: release\montajati_v3.3.0_windows.zip
echo Compressed package: release\montajati_v3.3.0_windows.zip
echo.
echo 🚀 التطبيق جاهز للتوزيع!
echo App is ready for distribution!
echo.
pause
