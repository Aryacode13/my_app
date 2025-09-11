# Test webhook dengan order_id yang benar-benar ada
$orderId = "reg-477106ca-8cc7-4ccc-888c-0d639f73939a"  # Order ID terbaru

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
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody"
    }
}
