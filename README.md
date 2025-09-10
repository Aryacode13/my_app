# Project Pendaftaran & Pembayaran

Aplikasi Flutter untuk pendaftaran dengan integrasi pembayaran Midtrans dan email notification via Resend.

## 🚀 Fitur

- ✅ Form pendaftaran (nama, email, phone, nominal)
- ✅ Integrasi Midtrans Snap untuk pembayaran
- ✅ WebView untuk halaman pembayaran
- ✅ Email notification via Resend
- ✅ Backend menggunakan Supabase Edge Functions
- ✅ Database Supabase untuk menyimpan data

## 📋 Setup

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Setup Supabase
1. Buat project di [supabase.com](https://supabase.com)
2. Jalankan SQL di `supabase-schema.sql` di Supabase SQL Editor
3. Dapatkan URL dan API keys dari project settings

### 3. Setup Midtrans
1. Daftar di [midtrans.com](https://midtrans.com)
2. Buat akun sandbox
3. Dapatkan Server Key (Sandbox)
4. Set Payment Notification URL: `https://YOUR_PROJECT_ID.functions.supabase.co/midtrans-webhook`

### 4. Setup Resend
1. Daftar di [resend.com](https://resend.com)
2. Dapatkan API key
3. Verifikasi domain atau gunakan `onboarding@resend.dev` untuk testing

### 5. Deploy Edge Functions
```bash
# Set environment variables
supabase secrets set --project-ref YOUR_PROJECT_ID \
  SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co \
  SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY \
  MIDTRANS_SERVER_KEY=YOUR_MIDTRANS_SERVER_KEY \
  RESEND_API_KEY=YOUR_RESEND_API_KEY

# Deploy functions
supabase functions deploy create-transaction
supabase functions deploy midtrans-webhook
```

### 6. Update Flutter Config
Edit `lib/main.dart`:
```dart
const supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
const functionsBaseUrl = 'https://YOUR_PROJECT_ID.functions.supabase.co';
```

### 7. Run App
```bash
flutter run
```

## 🔧 API Endpoints

### POST /create-transaction
Membuat transaksi Midtrans dan menyimpan data pendaftaran.

**Request:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "08123456789",
  "amount": 100000
}
```

**Response:**
```json
{
  "order_id": "reg-uuid",
  "token": "midtrans-token",
  "redirect_url": "https://app.sandbox.midtrans.com/snap/v2/vtweb/..."
}
```

### POST /midtrans-webhook
Webhook untuk menerima notifikasi pembayaran dari Midtrans.

## 📱 Screenshots

- Form pendaftaran dengan validasi
- WebView untuk halaman pembayaran Midtrans
- Email notification otomatis

## 🛠 Tech Stack

- **Frontend:** Flutter
- **Backend:** Supabase Edge Functions (Deno)
- **Database:** Supabase PostgreSQL
- **Payment:** Midtrans Snap
- **Email:** Resend
- **WebView:** webview_flutter

## 📝 Environment Variables

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
MIDTRANS_SERVER_KEY=your-midtrans-server-key
RESEND_API_KEY=your-resend-api-key
```

## 🐛 Troubleshooting

1. **Error "Failed to create transaction"**
   - Cek MIDTRANS_SERVER_KEY sudah benar
   - Pastikan Midtrans sandbox aktif

2. **Error "Failed to send email"**
   - Cek RESEND_API_KEY sudah benar
   - Pastikan domain email sudah diverifikasi

3. **WebView tidak load**
   - Cek redirect_url dari response API
   - Pastikan internet connection

## 📄 License

MIT License