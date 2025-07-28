Write-Host "Testing send-bulk endpoint..." -ForegroundColor Yellow

try {
    $body = @{
        title = "Test Notification"
        body = "Test message from PowerShell"
        type = "general"
        isScheduled = $false
    } | ConvertTo-Json
    
    Write-Host "Request body:" -ForegroundColor Cyan
    Write-Host $body
    
    $response = Invoke-RestMethod -Uri "https://montajati-backend.onrender.com/api/notifications/send-bulk" -Method POST -Headers @{'Content-Type'='application/json'} -Body $body -TimeoutSec 60
    
    Write-Host "SUCCESS Response:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10)
    
} catch {
    Write-Host "ERROR:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Error response body:" -ForegroundColor Red
        Write-Host $responseBody
    }
}

Write-Host "Test completed!" -ForegroundColor Cyan
