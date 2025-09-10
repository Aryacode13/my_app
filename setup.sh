#!/bin/bash

# Script untuk setup project pendaftaran & pembayaran

echo "🚀 Setup Project Pendaftaran & Pembayaran"
echo "=========================================="

# 1. Install dependencies Flutter
echo "📱 Installing Flutter dependencies..."
flutter pub get

# 2. Set environment variables untuk Supabase Functions
echo "🔧 Setting up environment variables..."

# Ganti dengan API key Resend yang benar
RESEND_API_KEY="re_xxxxxxxxx"  # GANTI INI DENGAN API KEY RESEND YANG BENAR

supabase secrets set --project-ref vmwidifukpjdmbnhaiap \
  SUPABASE_URL=https://vmwidifukpjdmbnhaiap.supabase.co \
  SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZtd2lkaWZ1a3BqZG1ibmhhaWFwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzMyNzUyOCwiZXhwIjoyMDcyOTAzNTI4fQ.Euhf86d1cGXZa7BHuDn9PWwV20jIUBIyn0dtwtlpqBM \
  MIDTRANS_SERVER_KEY=Mid-server-8SWeXYnW6LnM-w4es9n9aMxY \
  RESEND_API_KEY=$RESEND_API_KEY

# 3. Deploy Edge Functions
echo "🚀 Deploying Edge Functions..."
supabase functions deploy create-transaction
supabase functions deploy midtrans-webhook

echo "✅ Setup selesai!"
echo ""
echo "📋 Yang perlu dilakukan selanjutnya:"
echo "1. Daftar di resend.com dan dapatkan API key"
echo "2. Ganti RESEND_API_KEY di script ini"
echo "3. Jalankan: chmod +x setup.sh && ./setup.sh"
echo "4. Buat tabel di Supabase (lihat SQL di bawah)"
echo "5. Set webhook URL di Midtrans dashboard"
echo "6. Jalankan: flutter run"
