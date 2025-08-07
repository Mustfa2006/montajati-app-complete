#!/usr/bin/env pwsh

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "تنظيف وتحديث مشروع منتجاتي" -ForegroundColor Yellow
Write-Host "Cleaning and Updating Montajati Project" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "🧹 تنظيف مجلد Frontend..." -ForegroundColor Green

# الانتقال لمجلد Frontend
Set-Location -Path "frontend"

Write-Host ""
Write-Host "🔧 إصلاح إعدادات Git..." -ForegroundColor Blue
try {
    git config --global --add safe.directory "C:/flutter"
    Write-Host "✅ تم إصلاح إعدادات Git" -ForegroundColor Green
} catch {
    Write-Host "⚠️ تحذير: لم يتم إصلاح إعدادات Git" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🧹 تنظيف Flutter..." -ForegroundColor Blue
try {
    flutter clean
    Write-Host "✅ تم تنظيف Flutter" -ForegroundColor Green
} catch {
    Write-Host "❌ خطأ في تنظيف Flutter" -ForegroundColor Red
    Write-Host "تأكد من تثبيت Flutter وإضافته للـ PATH" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📦 تحديث التبعيات..." -ForegroundColor Blue
try {
    flutter pub get
    Write-Host "✅ تم تحديث التبعيات" -ForegroundColor Green
} catch {
    Write-Host "❌ خطأ في تحديث التبعيات" -ForegroundColor Red
}

Write-Host ""
Write-Host "🔨 بناء الملفات المولدة..." -ForegroundColor Blue
try {
    flutter pub run build_runner build --delete-conflicting-outputs
    Write-Host "✅ تم بناء الملفات المولدة" -ForegroundColor Green
} catch {
    Write-Host "⚠️ تحذير: لم يتم بناء الملفات المولدة" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ تم الانتهاء من تنظيف Frontend!" -ForegroundColor Green

Write-Host ""
Write-Host "🧹 تنظيف مجلد Backend..." -ForegroundColor Green

# الانتقال لمجلد Backend
Set-Location -Path "../backend"

Write-Host ""
Write-Host "📦 تحديث تبعيات Node.js..." -ForegroundColor Blue
try {
    npm install
    Write-Host "✅ تم تحديث تبعيات Node.js" -ForegroundColor Green
} catch {
    Write-Host "❌ خطأ في تحديث تبعيات Node.js" -ForegroundColor Red
    Write-Host "تأكد من تثبيت Node.js" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🧹 تنظيف cache..." -ForegroundColor Blue
try {
    npm cache clean --force
    Write-Host "✅ تم تنظيف cache" -ForegroundColor Green
} catch {
    Write-Host "⚠️ تحذير: لم يتم تنظيف cache" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ تم الانتهاء من تنظيف Backend!" -ForegroundColor Green

# العودة للمجلد الرئيسي
Set-Location -Path ".."

Write-Host ""
Write-Host "🎉 تم تنظيف وتحديث المشروع بالكامل!" -ForegroundColor Cyan
Write-Host ""
Write-Host "📱 لتشغيل التطبيق:" -ForegroundColor Yellow
Write-Host "   cd frontend" -ForegroundColor White
Write-Host "   flutter run" -ForegroundColor White
Write-Host ""
Write-Host "🖥️ لتشغيل الخادم:" -ForegroundColor Yellow
Write-Host "   cd backend" -ForegroundColor White
Write-Host "   npm start" -ForegroundColor White
Write-Host ""

Read-Host "اضغط Enter للمتابعة..."
