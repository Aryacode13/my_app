# Cek data registrasi di Supabase
$headers = @{
    'Authorization' = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZtd2lkaWZ1a3BqZG1ibmhhaWFwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTczMjc1MjgsImV4cCI6MjA3MjkwMzUyOH0.pAZWMZJf8vpqaIZdcginLgNEclOkzh_pnD-YFD2EBGw'
    'Content-Type' = 'application/json'
    'apikey' = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZtd2lkaWZ1a3BqZG1ibmhhaWFwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTczMjc1MjgsImV4cCI6MjA3MjkwMzUyOH0.pAZWMZJf8vpqaIZdcginLgNEclOkzh_pnD-YFD2EBGw'
}

try {
    $response = Invoke-RestMethod `
        -Uri "https://vmwidifukpjdmbnhaiap.supabase.co/rest/v1/registrations?select=order_id,status,email,created_at&order=created_at.desc&limit=5" `
        -Method GET `
        -Headers $headers
    
    Write-Host "Data registrasi terbaru:"
    $response | ForEach-Object {
        Write-Host "Order ID: $($_.order_id) | Status: $($_.status) | Email: $($_.email) | Created: $($_.created_at)"
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}
