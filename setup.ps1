# PowerShell script untuk setup project pendaftaran & pembayaran

Write-Host "🚀 Setup Project Pendaftaran & Pembayaran" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# 1. Install dependencies Flutter
Write-Host "📱 Installing Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

# 2. Set environment variables untuk Supabase Functions
Write-Host "🔧 Setting up environment variables..." -ForegroundColor Yellow

# Ganti dengan API key Resend yang benar
$RESEND_API_KEY = "re_xxxxxxxxx"  # GANTI INI DENGAN API KEY RESEND YANG BENAR

Write-Host "⚠️  PENTING: Ganti RESEND_API_KEY di script ini dengan API key Resend yang benar!" -ForegroundColor Red
Write-Host "📧 Daftar di resend.com untuk mendapatkan API key" -ForegroundColor Cyan

# Uncomment baris di bawah setelah ganti RESEND_API_KEY
# supabase secrets set --project-ref vmwidifukpjdmbnhaiap `
#   SUPABASE_URL=https://vmwidifukpjdmbnhaiap.supabase.co `
#   SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZtd2lkaWZ1a3BqZG1ibmhhaWFwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzMyNzUyOCwiZXhwIjoyMDcyOTAzNTI4fQ.Euhf86d1cGXZa7BHuDn9PWwV20jIUBIyn0dtwtlpqBM `
#   MIDTRANS_SERVER_KEY=Mid-server-8SWeXYnW6LnM-w4es9n9aMxY `
#   RESEND_API_KEY=$RESEND_API_KEY

# 3. Deploy Edge Functions
Write-Host "🚀 Deploying Edge Functions..." -ForegroundColor Yellow
# Uncomment baris di bawah setelah set environment variables
# supabase functions deploy create-transaction
# supabase functions deploy midtrans-webhook

Write-Host "✅ Setup selesai!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Yang perlu dilakukan selanjutnya:" -ForegroundColor Cyan
Write-Host "1. Daftar di resend.com dan dapatkan API key" -ForegroundColor White
Write-Host "2. Ganti RESEND_API_KEY di script ini" -ForegroundColor White
Write-Host "3. Uncomment baris supabase secrets set dan deploy" -ForegroundColor White
Write-Host "4. Jalankan: .\setup.ps1" -ForegroundColor White
Write-Host "5. Buat tabel di Supabase (lihat supabase-schema.sql)" -ForegroundColor White
Write-Host "6. Set webhook URL di Midtrans dashboard" -ForegroundColor White
Write-Host "7. Jalankan: flutter run" -ForegroundColor White
