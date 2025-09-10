# 🚀 Cara Menjalankan Project Pendaftaran & Pembayaran

## ⚠️ Error yang Sudah Diperbaiki:
- ✅ Hardcode environment variables → pakai `Deno.env.get()`
- ✅ Email domain tidak valid → pakai `onboarding@resend.dev`
- ✅ Comment syntax error → diperbaiki
- ✅ Flutter config placeholder → diisi dengan data Supabase

## 📋 Langkah-langkah Setup:

### 1. **Install Dependencies Flutter**
```bash
flutter pub get
```

### 2. **Setup Resend (PENTING!)**
1. Daftar di [resend.com](https://resend.com)
2. Dapatkan API key (format: `re_xxxxxxxxx`)
3. Ganti di file `setup.ps1`:
   ```powershell
   $RESEND_API_KEY = "re_xxxxxxxxx"  # Ganti dengan API key yang benar
   ```

### 3. **Setup Supabase Database**
1. Buka [Supabase Dashboard](https://supabase.com/dashboard)
2. Pilih project `vmwidifukpjdmbnhaiap`
3. Buka **SQL Editor**
4. Copy-paste isi file `supabase-schema.sql`
5. Klik **Run**

### 4. **Deploy Edge Functions**
```bash
# Set environment variables
supabase secrets set --project-ref vmwidifukpjdmbnhaiap `
  SUPABASE_URL=https://vmwidifukpjdmbnhaiap.supabase.co `
  SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZtd2lkaWZ1a3BqZG1ibmhhaWFwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzMyNzUyOCwiZXhwIjoyMDcyOTAzNTI4fQ.Euhf86d1cGXZa7BHuDn9PWwV20jIUBIyn0dtwtlpqBM `
  MIDTRANS_SERVER_KEY=Mid-server-8SWeXYnW6LnM-w4es9n9aMxY `
  RESEND_API_KEY=re_xxxxxxxxx

# Deploy functions
supabase functions deploy create-transaction
supabase functions deploy midtrans-webhook
```

### 5. **Setup Midtrans Webhook**
1. Buka [Midtrans Dashboard](https://dashboard.midtrans.com)
2. Masuk ke **Settings** → **Configuration**
3. Set **Payment Notification URL**:
   ```
   https://vmwidifukpjdmbnhaiap.functions.supabase.co/midtrans-webhook
   ```

### 6. **Jalankan Flutter App**
```bash
flutter run
```

## 🔧 Troubleshooting:

### Error "Failed to create transaction"
- ✅ Cek MIDTRANS_SERVER_KEY sudah benar
- ✅ Pastikan Midtrans sandbox aktif

### Error "Failed to send email"
- ✅ Cek RESEND_API_KEY sudah benar
- ✅ Pastikan format API key: `re_xxxxxxxxx`

### Error "Cannot find module" di editor
- ✅ Normal, editor tidak mengenali Deno types
- ✅ Functions tetap bisa jalan di Supabase

### WebView tidak load
- ✅ Cek internet connection
- ✅ Cek redirect_url dari response API

## 📱 Test Flow:

1. **Buka app** → Form pendaftaran muncul
2. **Isi form** → Nama, email, phone, nominal
3. **Klik "Daftar & Bayar"** → Loading, lalu WebView Midtrans muncul
4. **Pilih metode pembayaran** → Gopay/Bank Transfer/Credit Card
5. **Lakukan pembayaran** → Test dengan kartu sandbox
6. **Cek email** → Dapat 2 email:
   - "Pendaftaran diterima" (saat submit)
   - "Pembayaran berhasil" (saat settlement)

## 🎯 Endpoint URLs:

- **Create Transaction**: `https://vmwidifukpjdmbnhaiap.functions.supabase.co/create-transaction`
- **Midtrans Webhook**: `https://vmwidifukpjdmbnhaiap.functions.supabase.co/midtrans-webhook`

## 📊 Database:

Tabel `registrations` akan berisi:
- `order_id`: ID unik transaksi
- `name`, `email`, `phone`: Data pendaftar
- `amount`: Nominal pembayaran
- `status`: pending → settlement
- `payment_token`, `payment_redirect_url`: Data Midtrans

## ✅ Checklist:

- [ ] Flutter dependencies installed
- [ ] Resend API key didapatkan
- [ ] Supabase database table dibuat
- [ ] Environment variables di-set
- [ ] Edge Functions di-deploy
- [ ] Midtrans webhook URL di-set
- [ ] App dijalankan dan ditest

**Selamat! Project siap digunakan! 🎉**
