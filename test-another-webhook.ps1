# Test webhook dengan order_id lain
$orderId = "reg-6ee20685-66f3-432d-9624-813f11ea29cd"  # Order ID kedua

$body = @{
    order_id = $orderId
} | ConvertTo-Json

Write-Host "Testing webhook dengan order_id: $orderId"

try {
    $response = Invoke-RestMethod `
        -Uri "https://vmwidifukpjdmbnhaiap.functions.supabase.co/midtrans-webhook" `
        -Method POST `
        -ContentType 'application/json' `
        -Headers @{ 'x-test-webhook-secret' = 'let-me-test-settlement' } `
        -Body $body
    
    Write-Host "Success: $response"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}
