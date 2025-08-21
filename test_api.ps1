$orderId = "test_order_1753115468"
$newStatus = "مغلق"
$url = "https://montajati-official-backend-production.up.railway.app/api/orders/$orderId/status"

$body = @{
    status = $newStatus
    notes = "اختبار تحديث الحالة من PowerShell"
    changedBy = "test_script"
} | ConvertTo-Json -Depth 10

Write-Host "🧪 اختبار تحديث حالة الطلب عبر Backend API..." -ForegroundColor Yellow
Write-Host "📦 الطلب: $orderId" -ForegroundColor Cyan
Write-Host "🔄 الحالة الجديدة: $newStatus" -ForegroundColor Cyan
Write-Host "🌐 URL: $url" -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri $url -Method PUT -Body $body -ContentType "application/json" -TimeoutSec 30
    
    Write-Host "✅ نجح تحديث الحالة عبر API:" -ForegroundColor Green
    Write-Host "📝 الرسالة: $($response.message)" -ForegroundColor Green
    Write-Host "🔄 البيانات:" -ForegroundColor Green
    $response.data | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor Green
    
} catch {
    Write-Host "❌ خطأ في اختبار API:" -ForegroundColor Red
    Write-Host "📝 رسالة الخطأ: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        Write-Host "📊 كود الخطأ: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
}
