# اختبار بسيط لإرسال إشعار

Write-Host "اختبار إرسال إشعار..." -ForegroundColor Yellow

$notificationData = @{
    title = "اختبار التشخيص"
    body = "هذا إشعار تجريبي"
    type = "general"
    isScheduled = $false
}

$jsonData = $notificationData | ConvertTo-Json

Write-Host "بيانات الإشعار:" -ForegroundColor Cyan
Write-Host $jsonData

try {
    $response = Invoke-RestMethod -Uri "https://montajati-backend.onrender.com/api/notifications/send" -Method POST -Headers @{'Content-Type'='application/json'} -Body $jsonData
    
    Write-Host "استجابة الخادم:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10)
    
} catch {
    Write-Host "خطأ في الإرسال:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

Write-Host "انتهى الاختبار!" -ForegroundColor Cyan
