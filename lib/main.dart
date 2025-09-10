import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Konfigurasi Supabase
const supabaseUrl = 'https://vmwidifukpjdmbnhaiap.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZtd2lkaWZ1a3BqZG1ibmhhaWFwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTczMjc1MjgsImV4cCI6MjA3MjkwMzUyOH0.pAZWMZJf8vpqaIZdcginLgNEclOkzh_pnD-YFD2EBGw';

// URL untuk Supabase Edge Functions
const functionsBaseUrl = 'https://vmwidifukpjdmbnhaiap.functions.supabase.co';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pendaftaran & Pembayaran',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const RegistrationPage(),
    );
  }
}

class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.current});

  final int current; // 1..3

  Color _dot(bool active, BuildContext ctx) => active
      ? Theme.of(ctx).colorScheme.primary
      : Theme.of(ctx).colorScheme.primary.withOpacity(0.2);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 1; i <= 3; i++)
          Container(
            width: 10,
            height: 10,
            margin: EdgeInsets.only(right: i == 3 ? 0 : 8),
            decoration: BoxDecoration(
              color: _dot(i == current, context),
              shape: BoxShape.circle,
            ),
          )
      ],
    );
  }
}

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController(text: '100000');

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final uri = Uri.parse('$functionsBaseUrl/create-transaction');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'amount': int.parse(_amountController.text.trim()),
        }),
      );

      if (res.statusCode != 200) {
        final msg = res.body.isNotEmpty ? res.body : 'Gagal membuat transaksi';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${res.statusCode} - $msg')),
        );
        return;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final redirectUrl = data['redirect_url'] as String?;
      final orderId = data['order_id'] as String?;

      if (redirectUrl == null || orderId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Respon tidak valid dari server')),
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentStatusPage(
            orderId: orderId,
            email: _emailController.text.trim(),
            redirectUrl: redirectUrl,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Pendaftaran')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StepHeader(current: 1),
                const SizedBox(height: 8),
                Text('Step 1 dari 3 • Isi data', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                    if (!v.contains('@')) return 'Email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'No. HP'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nominal (IDR)'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return 'Nominal tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.payment),
                  label: const Text('Daftar & Lanjut Bayar'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentStatusPage extends StatefulWidget {
  const PaymentStatusPage({super.key, required this.orderId, required this.email, required this.redirectUrl});

  final String orderId;
  final String email;
  final String redirectUrl;

  @override
  State<PaymentStatusPage> createState() => _PaymentStatusPageState();
}

class _PaymentStatusPageState extends State<PaymentStatusPage> {
  bool _checking = false;
  String? _status;

  Future<void> _openPayment() async {
    final paymentUri = Uri.parse(widget.redirectUrl);
    if (await canLaunchUrl(paymentUri)) {
      await launchUrl(paymentUri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka halaman pembayaran')),
      );
    }
  }

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    try {
      final client = Supabase.instance.client;
      final row = await client
          .from('registrations')
          .select('status')
          .eq('order_id', widget.orderId)
          .maybeSingle();
      final s = (row != null ? row['status'] as String? : null) ?? 'pending';
      setState(() => _status = s);
      if (s == 'settlement' && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SuccessPage(orderId: widget.orderId, email: widget.email),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status saat ini: $s')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal cek status: $e')),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StepHeader(current: 2),
            const SizedBox(height: 8),
            Text('Step 2 dari 3 • Pembayaran', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            Text('Order ID: ${widget.orderId}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            const Text(
              'Silakan selesaikan pembayaran Anda melalui tombol di bawah ini. Setelah bayar, tekan "Cek Status" untuk memperbarui status.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openPayment,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Buka Halaman Pembayaran'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _checking ? null : _checkStatus,
              icon: _checking
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
              label: const Text('Cek Status'),
            ),
            const SizedBox(height: 12),
            if (_status != null)
              Text('Status: $_status', style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            const Divider(),
            const Text('Catatan:'),
            const Text('• Email 1 telah dikirim (instruksi pembayaran).'),
            const Text('• Email 2 akan dikirim otomatis setelah status menjadi settlement.'),
          ],
        ),
      ),
    );
  }
}

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key, required this.orderId, required this.email});

  final String orderId;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selesai')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StepHeader(current: 3),
            const SizedBox(height: 8),
            Text('Step 3 dari 3 • Selesai', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 16),
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 12),
            const Text('Selamat! Pendaftaran Anda telah berhasil.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Order ID: $orderId'),
            Text('Email: $email'),
            const SizedBox(height: 16),
            const Text('Silakan cek email Anda untuk informasi lebih lanjut.'),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Kembali ke Form'),
            )
          ],
        ),
      ),
    );
  }
}

