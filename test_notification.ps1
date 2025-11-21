Write-Host "Testing notification send..." -ForegroundColor Yellow

$notificationData = @{
    title = "Test Notification"
    body = "This is a test notification"
    type = "general"
    isScheduled = $false
}

$jsonData = $notificationData | ConvertTo-Json

Write-Host "Notification data:" -ForegroundColor Cyan
Write-Host $jsonData

try {
    $response = Invoke-RestMethod -Uri "https://montajati-official-backend-production.up.railway.app/api/notifications/send" -Method POST -Headers @{'Content-Type'='application/json'} -Body $jsonData
    
    Write-Host "Server response:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10)
    
} catch {
    Write-Host "Error sending notification:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

Write-Host "Test completed!" -ForegroundColor Cyan
