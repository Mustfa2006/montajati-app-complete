Write-Host "Testing notification endpoints..." -ForegroundColor Yellow

# Test system-test endpoint
Write-Host "Testing system-test endpoint..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "https://montajati-backend.onrender.com/api/notifications/system-test" -Method POST -Headers @{'Content-Type'='application/json'} -Body '{}'
    Write-Host "System test response:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 5)
} catch {
    Write-Host "System test error:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

# Test stats endpoint
Write-Host "`nTesting stats endpoint..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "https://montajati-backend.onrender.com/api/notifications/stats" -Method GET
    Write-Host "Stats response:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 5)
} catch {
    Write-Host "Stats error:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

# Test send endpoint with detailed error info
Write-Host "`nTesting send endpoint..." -ForegroundColor Cyan
try {
    $body = @{
        title = "Test"
        body = "Test message"
        type = "general"
        isScheduled = $false
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri "https://montajati-backend.onrender.com/api/notifications/send" -Method POST -Headers @{'Content-Type'='application/json'} -Body $body
    Write-Host "Send response status:" -ForegroundColor Green
    Write-Host $response.StatusCode
    Write-Host "Send response body:" -ForegroundColor Green
    Write-Host $response.Content
} catch {
    Write-Host "Send error:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Error response body:" -ForegroundColor Red
        Write-Host $responseBody
    }
}

Write-Host "`nTest completed!" -ForegroundColor Cyan
