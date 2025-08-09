# 🚀 نشر تطبيق منتجاتي للويب مباشرة
Write-Host "🌐 بدء نشر تطبيق منتجاتي للويب..." -ForegroundColor Green

# الانتقال لمجلد Frontend
Set-Location "frontend"

# التحقق من وجود Flutter
try {
    flutter --version | Out-Null
    Write-Host "✅ Flutter متوفر" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter غير مثبت" -ForegroundColor Red
    exit 1
}

# تنظيف المشروع
Write-Host "🧹 تنظيف المشروع..." -ForegroundColor Yellow
flutter clean

# تحديث التبعيات
Write-Host "📦 تحديث التبعيات..." -ForegroundColor Yellow
flutter pub get

# تفعيل دعم الويب
Write-Host "🔧 تفعيل دعم الويب..." -ForegroundColor Yellow
flutter config --enable-web

# بناء التطبيق للويب
Write-Host "🏗️ بناء التطبيق للويب..." -ForegroundColor Yellow
flutter build web --release --web-renderer html --base-href /

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ تم بناء التطبيق بنجاح!" -ForegroundColor Green
    
    # عرض معلومات الملفات
    $webPath = "build\web"
    if (Test-Path $webPath) {
        Write-Host "📁 ملفات الويب جاهزة في: $webPath" -ForegroundColor Green
        
        # عرض حجم الملفات الرئيسية
        $indexFile = "$webPath\index.html"
        $mainFile = "$webPath\main.dart.js"
        
        if (Test-Path $indexFile) {
            $indexSize = (Get-Item $indexFile).Length
            Write-Host "📄 index.html: $([math]::Round($indexSize/1KB, 2)) KB" -ForegroundColor Cyan
        }
        
        if (Test-Path $mainFile) {
            $mainSize = (Get-Item $mainFile).Length
            Write-Host "📄 main.dart.js: $([math]::Round($mainSize/1MB, 2)) MB" -ForegroundColor Cyan
        }
        
        # عد الملفات
        $fileCount = (Get-ChildItem $webPath -Recurse -File).Count
        Write-Host "📊 إجمالي الملفات: $fileCount" -ForegroundColor Cyan
        
        Write-Host "`n🎉 التطبيق جاهز للنشر!" -ForegroundColor Green
        Write-Host "📁 المسار: $(Get-Location)\$webPath" -ForegroundColor White
        
        # خيارات النشر
        Write-Host "`n🚀 خيارات النشر السريع:" -ForegroundColor Yellow
        Write-Host "1. Netlify Drop: اسحب مجلد build\web إلى netlify.com/drop" -ForegroundColor White
        Write-Host "2. Vercel: vercel --prod (من داخل مجلد build\web)" -ForegroundColor White
        Write-Host "3. Firebase: firebase deploy --only hosting" -ForegroundColor White
        Write-Host "4. GitHub Pages: ارفع المحتوى لـ gh-pages branch" -ForegroundColor White
        
        # تشغيل خادم محلي للاختبار
        Write-Host "`n🔍 هل تريد اختبار التطبيق محلياً؟ (y/n): " -ForegroundColor Yellow -NoNewline
        $test = Read-Host
        
        if ($test -eq "y" -or $test -eq "Y") {
            Write-Host "🌐 تشغيل خادم محلي على http://localhost:8000" -ForegroundColor Green
            Set-Location $webPath
            
            # محاولة استخدام Python أولاً
            try {
                python -m http.server 8000
            } catch {
                # إذا فشل Python، جرب Node.js
                try {
                    npx serve -s . -p 8000
                } catch {
                    Write-Host "❌ لم يتم العثور على Python أو Node.js لتشغيل الخادم" -ForegroundColor Red
                    Write-Host "يمكنك فتح index.html مباشرة في المتصفح" -ForegroundColor Yellow
                }
            }
        }
        
    } else {
        Write-Host "❌ مجلد build\web غير موجود" -ForegroundColor Red
    }
    
} else {
    Write-Host "❌ فشل في بناء التطبيق" -ForegroundColor Red
    exit 1
}

Write-Host "`n🎯 انتهى النشر!" -ForegroundColor Green
