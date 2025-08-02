# 🚀 سكريپت تشغيل تطبيق منتجاتي
Write-Host "🚀 ===== إعداد وتشغيل تطبيق منتجاتي =====" -ForegroundColor Green
Write-Host ""

# تحديد مسار المشروع
$projectPath = "C:\Users\Mustafa\Desktop\montajati\frontend"
Write-Host "📁 مسار المشروع: $projectPath" -ForegroundColor Cyan

# التحقق من وجود المجلد
if (-not (Test-Path $projectPath)) {
    Write-Host "❌ مجلد المشروع غير موجود!" -ForegroundColor Red
    Write-Host "💡 تأكد من المسار: $projectPath" -ForegroundColor Yellow
    Read-Host "اضغط Enter للخروج"
    exit 1
}

# الانتقال لمجلد المشروع
Set-Location $projectPath
Write-Host "✅ تم الانتقال لمجلد المشروع" -ForegroundColor Green
Write-Host ""

# التحقق من Flutter
Write-Host "🔍 التحقق من Flutter..." -ForegroundColor Cyan
try {
    $flutterVersion = flutter --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Flutter موجود ويعمل" -ForegroundColor Green
        Write-Host "📋 إصدار Flutter:" -ForegroundColor Yellow
        flutter --version
    } else {
        throw "Flutter not found"
    }
} catch {
    Write-Host "❌ Flutter غير مثبت أو غير موجود في PATH" -ForegroundColor Red
    Write-Host "💡 يرجى تثبيت Flutter من: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Yellow
    Write-Host "💡 أو إضافة Flutter إلى متغير PATH" -ForegroundColor Yellow
    Read-Host "اضغط Enter للخروج"
    exit 1
}
Write-Host ""

# التحقق من Android SDK
Write-Host "🤖 التحقق من Android SDK..." -ForegroundColor Cyan
try {
    $adbVersion = adb version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Android SDK موجود" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Android SDK غير موجود في PATH" -ForegroundColor Yellow
        Write-Host "💡 تأكد من تثبيت Android Studio وإضافة SDK إلى PATH" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ لم يتم العثور على ADB" -ForegroundColor Yellow
}
Write-Host ""

# فحص الأجهزة المتصلة
Write-Host "📱 فحص الأجهزة والمحاكيات المتصلة..." -ForegroundColor Cyan
try {
    flutter devices
    Write-Host ""
    
    # التحقق من وجود أجهزة
    $devices = flutter devices --machine 2>$null | ConvertFrom-Json
    if ($devices.Count -eq 0) {
        Write-Host "⚠️ لا توجد أجهزة متصلة!" -ForegroundColor Yellow
        Write-Host "💡 يرجى:" -ForegroundColor Yellow
        Write-Host "   1. تشغيل محاكي Android من Android Studio" -ForegroundColor Yellow
        Write-Host "   2. أو توصيل جهاز Android حقيقي" -ForegroundColor Yellow
        Write-Host ""
        $continue = Read-Host "هل تريد المتابعة؟ (y/n)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            exit 0
        }
    } else {
        Write-Host "✅ تم العثور على $($devices.Count) جهاز/محاكي" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ خطأ في فحص الأجهزة" -ForegroundColor Yellow
}
Write-Host ""

# تحديث التبعيات
Write-Host "📦 تحديث تبعيات Flutter..." -ForegroundColor Cyan
try {
    flutter pub get
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ تم تحديث التبعيات بنجاح" -ForegroundColor Green
    } else {
        Write-Host "⚠️ مشكلة في تحديث التبعيات" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ خطأ في تحديث التبعيات" -ForegroundColor Red
}
Write-Host ""

# معلومات تسجيل الدخول
Write-Host "🔐 معلومات تسجيل الدخول للوحة التحكم:" -ForegroundColor Cyan
Write-Host "   📧 البريد الإلكتروني: admin@montajati.com" -ForegroundColor Yellow
Write-Host "   🔑 كلمة المرور: admin123" -ForegroundColor Yellow
Write-Host ""

# تعليمات التشخيص
Write-Host "🔍 تعليمات تشخيص مشكلة تحديث الحالة:" -ForegroundColor Cyan
Write-Host "   1. بعد تشغيل التطبيق، سجل دخول كمدير" -ForegroundColor Yellow
Write-Host "   2. اذهب إلى قسم 'الطلبات'" -ForegroundColor Yellow
Write-Host "   3. اختر أي طلب واضغط 'تفاصيل'" -ForegroundColor Yellow
Write-Host "   4. جرب تحديث حالة الطلب" -ForegroundColor Yellow
Write-Host "   5. راقب رسائل الخطأ في هذا Terminal" -ForegroundColor Yellow
Write-Host ""

# تشغيل التطبيق
Write-Host "🚀 تشغيل التطبيق..." -ForegroundColor Green
Write-Host "💡 للخروج: اضغط Ctrl+C" -ForegroundColor Yellow
Write-Host "💡 لإعادة التحميل السريع: اضغط 'r' في Terminal" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔄 بدء التشغيل..." -ForegroundColor Cyan
Write-Host "=" * 50

try {
    flutter run --debug --verbose
} catch {
    Write-Host ""
    Write-Host "❌ خطأ في تشغيل التطبيق" -ForegroundColor Red
    Write-Host "💡 تحقق من:" -ForegroundColor Yellow
    Write-Host "   - وجود محاكي يعمل" -ForegroundColor Yellow
    Write-Host "   - اتصال الإنترنت" -ForegroundColor Yellow
    Write-Host "   - إعدادات Flutter" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🏁 انتهى التشغيل" -ForegroundColor Green
Read-Host "اضغط Enter للخروج"
