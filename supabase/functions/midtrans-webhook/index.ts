// supabase/functions/midtrans-webhook/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const MIDTRANS_SERVER_KEY = Deno.env.get('MIDTRANS_SERVER_KEY')!;
const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!;
const TEST_WEBHOOK_SECRET = Deno.env.get('TEST_WEBHOOK_SECRET') || "";

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

function sha512(input: string) {
	const encoder = new TextEncoder();
	const data = encoder.encode(input);
	return crypto.subtle.digest('SHA-512', data);
}

function toHex(buffer: ArrayBuffer) {
	return [...new Uint8Array(buffer)].map(b => b.toString(16).padStart(2, '0')).join('');
}

serve(async (req: Request) => {
	if (req.method !== 'POST') {
		return new Response('Method Not Allowed', { status: 405 });
	}

	try {
		const payload = await req.json();

		// TEST MODE: jika header x-test-webhook-secret cocok, bypass signature dan paksa settlement
		const testSecretHeader = req.headers.get('x-test-webhook-secret') || "";
		if (TEST_WEBHOOK_SECRET && testSecretHeader && testSecretHeader === TEST_WEBHOOK_SECRET) {
			const forcedOrderId = payload.order_id as string;
			if (!forcedOrderId) {
				return new Response('Missing order_id for test', { status: 400 });
			}

			const { data, error } = await supabase
				.from('registrations')
				.update({ status: 'settlement', updated_at: new Date().toISOString() })
				.eq('order_id', forcedOrderId)
				.select('*')
				.single();

			if (error || !data) {
				console.error('Supabase update error (test mode):', error);
				return new Response('Update failed', { status: 500 });
			}

			await sendEmail(
				data.email,
				"Pembayaran Berhasil - Pendaftaran Terkonfirmasi",
				`<p>Halo ${data.name},</p>
				<p>Pendaftaran kamu <b>berhasil</b>. Pembayaran sudah kami terima (settlement).</p>
				<p>Order ID: <b>${forcedOrderId}</b></p>`
			);

			return new Response('OK (test settlement)', { status: 200 });
		}

		const {
			order_id,
			status_code,
			gross_amount,
			transaction_status,
			signature_key
		} = payload;

		// Verify signature per Midtrans doc: sha512(order_id+status_code+gross_amount+ServerKey)
		const raw = `${order_id}${status_code}${gross_amount}${MIDTRANS_SERVER_KEY}`;
		const digest = await sha512(raw);
		const calculated = toHex(digest);
		if (calculated !== signature_key) {
			console.warn('Invalid signature for order', order_id);
			return new Response('Invalid signature', { status: 401 });
		}

		// Update registration status
		const newStatus = transaction_status; // e.g. 'settlement', 'pending', 'expire', 'cancel'
		const { data, error } = await supabase
			.from('registrations')
			.update({ status: newStatus, updated_at: new Date().toISOString() })
			.eq('order_id', order_id)
			.select('*')
			.single();

		if (error) {
			console.error('Supabase update error:', error);
			return new Response('Update failed', { status: 500 });
		}

		if (newStatus === 'settlement' && data) {
			await sendEmail(
				data.email,
				"Pembayaran Berhasil - Pendaftaran Terkonfirmasi",
				`<p>Halo ${data.name},</p>
				<p>Pendaftaran kamu <b>berhasil</b>. Pembayaran sudah kami terima (settlement).</p>
				<p>Order ID: <b>${order_id}</b></p>`
			);
		}

		return new Response('OK', { status: 200 });
	} catch (err) {
		console.error(err);
		return new Response('Internal Server Error', { status: 500 });
	}
});


