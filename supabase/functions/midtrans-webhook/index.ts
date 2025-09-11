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
			payment_type,
			fraud_status,
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

		// Log received payload for debugging
		console.log('Webhook payload:', {
			order_id,
			transaction_status,
			payment_type,
			fraud_status,
			status_code
		});

		// Normalize status: map successful payment statuses to 'settlement'
		let newStatus: string = transaction_status;
		
		// Credit card: capture + fraud_status accept = settlement
		if (payment_type === 'credit_card' && transaction_status === 'capture' && fraud_status === 'accept') {
			newStatus = 'settlement';
			console.log('Credit card payment successful, setting status to settlement');
		}
		// Bank transfer: settlement = settlement
		else if (payment_type === 'bank_transfer' && transaction_status === 'settlement') {
			newStatus = 'settlement';
			console.log('Bank transfer payment successful, setting status to settlement');
		}
		// E-wallet (Gopay): settlement = settlement
		else if (payment_type === 'gopay' && transaction_status === 'settlement') {
			newStatus = 'settlement';
			console.log('Gopay payment successful, setting status to settlement');
		}
		// QRIS: settlement = settlement
		else if (payment_type === 'qris' && transaction_status === 'settlement') {
			newStatus = 'settlement';
			console.log('QRIS payment successful, setting status to settlement');
		}
		// Echannel (Mandiri): settlement = settlement
		else if (payment_type === 'echannel' && transaction_status === 'settlement') {
			newStatus = 'settlement';
			console.log('Echannel payment successful, setting status to settlement');
		}
		// Default: use original transaction_status
		else {
			newStatus = transaction_status;
			console.log(`Using original status: ${transaction_status} for payment type: ${payment_type}`);
		}

		console.log(`Updating registration ${order_id} to status: ${newStatus}`);
		
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

		console.log('Database updated successfully:', { order_id, newStatus, email: data?.email });

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


