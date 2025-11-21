# اختبار نظام الإشعارات على Render

Write-Host "🔧 إنشاء جداول قاعدة البيانات..." -ForegroundColor Yellow

try {
    $setupResponse = Invoke-RestMethod -Uri "https://montajati-official-backend-production.up.railway.app/api/notifications/setup-database" -Method POST -Headers @{'Content-Type'='application/json'} -Body '{}'
    Write-Host "✅ تم إنشاء جداول قاعدة البيانات:" -ForegroundColor Green
    Write-Host ($setupResponse | ConvertTo-Json -Depth 3)
} catch {
    Write-Host "❌ خطأ في إنشاء جداول قاعدة البيانات: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🧪 اختبار النظام..." -ForegroundColor Yellow

try {
    $testResponse = Invoke-RestMethod -Uri "https://montajati-official-backend-production.up.railway.app/api/notifications/test-system" -Method POST -Headers @{'Content-Type'='application/json'} -Body '{}'
    Write-Host "✅ نتائج اختبار النظام:" -ForegroundColor Green
    Write-Host ($testResponse | ConvertTo-Json -Depth 3)
} catch {
    Write-Host "❌ خطأ في اختبار النظام: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n📊 جلب الإحصائيات..." -ForegroundColor Yellow

try {
    $statsResponse = Invoke-RestMethod -Uri "https://montajati-official-backend-production.up.railway.app/api/notifications/stats" -Method GET
    Write-Host "✅ الإحصائيات:" -ForegroundColor Green
    Write-Host ($statsResponse | ConvertTo-Json -Depth 3)
} catch {
    Write-Host "❌ خطأ في جلب الإحصائيات: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n📜 جلب التاريخ..." -ForegroundColor Yellow

try {
    $historyResponse = Invoke-RestMethod -Uri "https://montajati-official-backend-production.up.railway.app/api/notifications/history" -Method GET
    Write-Host "✅ التاريخ:" -ForegroundColor Green
    Write-Host ($historyResponse | ConvertTo-Json -Depth 3)
} catch {
    Write-Host "❌ خطأ في جلب التاريخ: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🚀 إرسال إشعار تجريبي..." -ForegroundColor Yellow

try {
    $notificationData = @{
        title = "🧪 اختبار النظام"
        body = "هذا إشعار تجريبي للتأكد من عمل نظام الإشعارات الجماعية"
        type = "general"
        isScheduled = $false
    } | ConvertTo-Json

    $sendResponse = Invoke-RestMethod -Uri "https://montajati-official-backend-production.up.railway.app/api/notifications/send" -Method POST -Headers @{'Content-Type'='application/json'} -Body $notificationData
    Write-Host "✅ تم إرسال الإشعار التجريبي:" -ForegroundColor Green
    Write-Host ($sendResponse | ConvertTo-Json -Depth 3)
} catch {
    Write-Host "❌ خطأ في إرسال الإشعار التجريبي: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎉 انتهى الاختبار!" -ForegroundColor Cyan
