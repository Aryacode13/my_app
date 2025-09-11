# Test webhook dengan order_id yang ada
$body = @{
    order_id = "reg-test-123"
} | ConvertTo-Json

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
    Write-Host "Response: $($_.Exception.Response)"
}
