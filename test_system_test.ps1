Write-Host "Testing system-test endpoint..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "https://montajati-backend.onrender.com/api/notifications/system-test" -Method POST -Headers @{'Content-Type'='application/json'} -Body '{}'
    Write-Host "System test SUCCESS:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "System test ERROR:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Error response body:" -ForegroundColor Red
        Write-Host $responseBody
    }
}

Write-Host "Test completed!" -ForegroundColor Cyan
