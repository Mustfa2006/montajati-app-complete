Write-Host "Testing Production Sync System..." -ForegroundColor Yellow

# Test health endpoint
Write-Host "`nTesting health endpoint..." -ForegroundColor Cyan
try {
    $health = Invoke-RestMethod -Uri "https://montajati-official-backend-production.up.railway.app/health" -Method GET
    Write-Host "Health Status:" -ForegroundColor Green
    Write-Host ($health | ConvertTo-Json -Depth 5)
    
    # Check if sync service is mentioned
    if ($health.services -and $health.services.sync) {
        Write-Host "`nSync Service Status: $($health.services.sync)" -ForegroundColor $(if($health.services.sync -eq "healthy") {"Green"} else {"Red"})
    }
    
} catch {
    Write-Host "Health check error:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

# Test if there's a sync status endpoint
Write-Host "`nTesting sync status..." -ForegroundColor Cyan
try {
    $syncStatus = Invoke-RestMethod -Uri "https://montajati-official-backend-production.up.railway.app/api/sync/status" -Method GET
    Write-Host "Sync Status:" -ForegroundColor Green
    Write-Host ($syncStatus | ConvertTo-Json -Depth 5)
} catch {
    Write-Host "Sync status error (endpoint may not exist):" -ForegroundColor Yellow
    Write-Host $_.Exception.Message
}

# Test orders endpoint to see recent orders
Write-Host "`nTesting recent orders..." -ForegroundColor Cyan
try {
    $orders = Invoke-RestMethod -Uri "https://montajati-official-backend-production.up.railway.app/api/orders?limit=5" -Method GET
    Write-Host "Recent Orders Count: $($orders.data.length)" -ForegroundColor Green
    
    if ($orders.data -and $orders.data.length -gt 0) {
        foreach ($order in $orders.data[0..2]) {
            Write-Host "Order $($order.id): Status=$($order.status), Waseet_Status=$($order.waseet_status), Last_Check=$($order.last_status_check)" -ForegroundColor Cyan
        }
    }
} catch {
    Write-Host "Orders check error:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

Write-Host "`nTest completed!" -ForegroundColor Cyan
