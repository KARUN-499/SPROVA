import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import crypto from "https://deno.land/std@0.168.0/crypto/mod.ts"

const RAZORPAY_SECRET = Deno.env.get("RAZORPAY_SECRET") || "";
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") || "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

serve(async (req) => {
  const signature = req.headers.get("x-razorpay-signature");
  const body = await req.text();

  // 1. Verify Razorpay Signature
  const hmac = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(RAZORPAY_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const signatureBuffer = await crypto.subtle.sign("HMAC", hmac, new TextEncoder().encode(body));
  const computedSignature = Array.from(new Uint8Array(signatureBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  if (signature !== computedSignature) {
    return new Response("Invalid signature", { status: 400 });
  }

  const event = JSON.parse(body);
  if (event.event !== "payment.captured") {
    return new Response("Event ignored", { status: 200 });
  }

  const paymentEntity = event.payload.payment.entity;
  const email = paymentEntity.email;
  const orderId = paymentEntity.order_id;

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // 2. Idempotent Enrollment
  const { error: enrollError } = await supabase
    .from("enrollments")
    .upsert(
      {
        student_email: email,
        razorpay_order_id: orderId,
        track: paymentEntity.notes?.track || "General"
      },
      { onConflict: "razorpay_order_id" }
    );

  if (enrollError) {
    return new Response(`Enrollment error: ${enrollError.message}`, { status: 500 });
  }

  // 3. Send Welcome Email via Resend
  try {
    await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: "Academy <onboarding@yourdomain.com>",
        to: [email],
        subject: "Welcome to the Cohort!",
        html: `
          <p>Welcome! Your payment is successful.</p>
          <p><strong>Cohort Start Date:</strong> ${Deno.env.get("COHORT_START_DATE") || "Coming Soon"}</p>
          <p>Join the community on WhatsApp: <a href="${Deno.env.get("WHATSAPP_LINK") || "#"}">Join Now</a></p>
        `,
      }),
    });
  } catch (e) {
    console.error("Email sending failed:", e);
    // We don't fail the whole request if email fails, as payment is captured
  }

  return new Response("Success", { status: 200 });
});
