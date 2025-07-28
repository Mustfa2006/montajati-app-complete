# اختبار إرسال إشعار مع تشخيص شامل

Write-Host "اختبار إرسال إشعار جماعي مع التشخيص الشامل..." -ForegroundColor Yellow

try {
    $notificationData = @{
        title = "اختبار التشخيص الشامل"
        body = "هذا إشعار تجريبي لاختبار نظام التشخيص الجديد"
        type = "general"
        isScheduled = $false
    } | ConvertTo-Json

    Write-Host "بيانات الإشعار:" -ForegroundColor Cyan
    Write-Host $notificationData

    $response = Invoke-RestMethod -Uri "https://montajati-backend.onrender.com/api/notifications/send" -Method POST -Headers @{'Content-Type'='application/json'} -Body $notificationData

    Write-Host "استجابة الخادم:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10)

    if ($response.diagnostics) {
        Write-Host "تشخيص مفصل:" -ForegroundColor Magenta
        Write-Host ($response.diagnostics | ConvertTo-Json -Depth 10)
    }

} catch {
    Write-Host "خطأ في الإرسال:" -ForegroundColor Red
    Write-Host $_.Exception.Message

    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "تفاصيل الخطأ من الخادم:" -ForegroundColor Red
        Write-Host $responseBody
    }
}

Write-Host "اختبار النظام الشامل..." -ForegroundColor Yellow

try {
    $systemTestResponse = Invoke-RestMethod -Uri "https://montajati-backend.onrender.com/api/notifications/system-test" -Method POST -Headers @{'Content-Type'='application/json'} -Body '{}'

    Write-Host "نتائج اختبار النظام:" -ForegroundColor Green
    Write-Host ($systemTestResponse | ConvertTo-Json -Depth 10)

} catch {
    Write-Host "خطأ في اختبار النظام:" -ForegroundColor Red
    Write-Host $_.Exception.Message

    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "تفاصيل الخطأ:" -ForegroundColor Red
        Write-Host $responseBody
    }
}

Write-Host "انتهى الاختبار!" -ForegroundColor Cyan
