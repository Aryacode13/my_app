// supabase/functions/create-transaction/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const MIDTRANS_SERVER_KEY = Deno.env.get('MIDTRANS_SERVER_KEY')!;
const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function sendEmail(to: string, subject: string, html: string) {
	const res = await fetch("https://api.resend.com/emails", {
		method: "POST",
		headers: {
			"Authorization": `Bearer ${RESEND_API_KEY}`,
			"Content-Type": "application/json"
		},
		body: JSON.stringify({
			from: "onboarding@resend.dev",
			to: [to],
			subject,
			html
		})
	});
	if (!res.ok) {
		const text = await res.text();
		console.error("Failed to send email:", text);
	}
}

serve(async (req: Request) => {
	// Handle CORS
	if (req.method === 'OPTIONS') {
		return new Response('ok', {
			headers: {
				'Access-Control-Allow-Origin': '*',
				'Access-Control-Allow-Methods': 'POST, OPTIONS',
				'Access-Control-Allow-Headers': 'Content-Type, Authorization',
			},
		});
	}

	if (req.method !== 'POST') {
		return new Response('Method Not Allowed', { status: 405 });
	}

	// Get authorization header
	const authHeader = req.headers.get('Authorization');
	if (!authHeader) {
		return new Response(JSON.stringify({ error: 'Missing authorization header' }), { 
			status: 401, 
			headers: { 
				'Content-Type': 'application/json',
				'Access-Control-Allow-Origin': '*',
			} 
		});
	}

	try {
		const { name, email, phone, amount } = await req.json();

		if (!name || !email || !amount) {
			return new Response(JSON.stringify({ error: 'Missing fields' }), { status: 400, headers: { 'Content-Type': 'application/json' } });
		}

		// Idempotency: cek apakah sudah ada pending terbaru untuk email ini (mis. 10 menit terakhir)
		const tenMinutesAgoIso = new Date(Date.now() - 10 * 60 * 1000).toISOString();
		const { data: existingPending, error: existingErr } = await supabase
			.from('registrations')
			.select('*')
			.eq('email', email)
			.eq('status', 'pending')
			.gte('created_at', tenMinutesAgoIso)
			.order('created_at', { ascending: false })
			.limit(1)
			.maybeSingle();

		if (existingErr) {
			console.error('Supabase select error:', existingErr);
		}
		if (existingPending && existingPending.payment_redirect_url) {
			// Kembalikan transaksi sebelumnya agar tidak membuat data dobel
			return new Response(
				JSON.stringify({
					order_id: existingPending.order_id,
					token: existingPending.payment_token,
					redirect_url: existingPending.payment_redirect_url,
					reuse: true
				}),
				{ status: 200, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } }
			);
		}

		const order_id = `reg-${crypto.randomUUID()}`;

		// Create Midtrans transaction (Snap)
		const snapRequestBody = {
			transaction_details: {
				order_id,
				gross_amount: Number(amount)
			},
			customer_details: {
				first_name: name,
				email,
				phone
			},
			enable_payments: ["gopay", "bank_transfer", "echannel", "credit_card", "qris"],
			callbacks: {
				finish: "https://vmwidifukpjdmbnhaiap.functions.supabase.co/midtrans-webhook"
			}
		};

		const authHeaderBasic = "Basic " + btoa(`${MIDTRANS_SERVER_KEY}:`);
		console.log('Using MIDTRANS_SERVER_KEY:', MIDTRANS_SERVER_KEY);
		console.log('Auth header:', authHeaderBasic);
		
		const midtransRes = await fetch("https://app.sandbox.midtrans.com/snap/v1/transactions", {
			method: 'POST',
			headers: {
				'Authorization': authHeaderBasic,
				'Content-Type': 'application/json'
			},
			body: JSON.stringify(snapRequestBody)
		});

		if (!midtransRes.ok) {
			const errText = await midtransRes.text();
			console.error('Midtrans error:', errText);
			console.error('Request body:', JSON.stringify(snapRequestBody, null, 2));
			console.error('Auth header:', authHeaderBasic);
			return new Response(JSON.stringify({ error: 'Failed to create transaction', details: errText }), { 
				status: 502, 
				headers: { 
					'Content-Type': 'application/json',
					'Access-Control-Allow-Origin': '*',
				} 
			});
		}

		const { token, redirect_url } = await midtransRes.json();

		// Save to Supabase
		const { error } = await supabase
			.from('registrations')
			.insert([
				{ order_id, name, email, phone, amount: Number(amount), status: 'pending', payment_token: token, payment_redirect_url: redirect_url }
			]);

		if (error) {
			console.error('Supabase insert error:', error);
			return new Response(JSON.stringify({ error: 'Failed to save registration' }), { status: 500, headers: { 'Content-Type': 'application/json' } });
		}

		// Send registration email (call-to-action untuk selesaikan pembayaran)
		await sendEmail(
			email,
			"Pendaftaran diterima - Selesaikan Pembayaran",
			`<p>Halo ${name},</p>
			<p>Pendaftaran kamu sudah kami terima. Untuk menyelesaikan pendaftaran, silakan lakukan pembayaran melalui tautan berikut:</p>
			<p><a href="${redirect_url}">Bayar Sekarang</a></p>
			<p>Order ID: <b>${order_id}</b></p>`
		);

		return new Response(JSON.stringify({ order_id, token, redirect_url }), { 
			status: 200, 
			headers: { 
				'Content-Type': 'application/json',
				'Access-Control-Allow-Origin': '*',
			} 
		});
	} catch (err) {
		console.error(err);
		return new Response(JSON.stringify({ error: 'Internal Server Error' }), { 
			status: 500, 
			headers: { 
				'Content-Type': 'application/json',
				'Access-Control-Allow-Origin': '*',
			} 
		});
	}
});
