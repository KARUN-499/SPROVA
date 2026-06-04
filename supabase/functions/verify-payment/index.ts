import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { orderId, paymentId, signature, track, userEmail } = await req.json();

    // Input validation
    if (typeof orderId !== "string" || orderId.trim().length === 0) {
      throw new Error("Invalid order ID");
    }
    if (typeof paymentId !== "string" || paymentId.trim().length === 0) {
      throw new Error("Invalid payment ID");
    }
    if (typeof signature !== "string" || signature.trim().length === 0) {
      throw new Error("Invalid signature");
    }
    if (typeof track !== "string" || track.trim().length === 0) {
      throw new Error("Invalid track");
    }

    const razorpayKeyId = Deno.env.get("RAZORPAY_KEY_ID");
    const razorpayKeySecret = Deno.env.get("RAZORPAY_KEY_SECRET");

    if (!razorpayKeyId || !razorpayKeySecret) {
      throw new Error("Razorpay credentials not configured");
    }

    // Verify payment signature using HMAC-SHA256
    const body = orderId + "|" + paymentId;
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(razorpayKeySecret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );
    const signatureBytes = await crypto.subtle.sign(
      "HMAC",
      key,
      encoder.encode(body)
    );
    const expectedSignature = Array.from(new Uint8Array(signatureBytes))
      .map(b => b.toString(16).padStart(2, "0"))
      .join("");

    if (expectedSignature !== signature) {
      throw new Error("Invalid payment signature");
    }

    // Fetch payment details from Razorpay to confirm status
    const paymentResponse = await fetch(`https://api.razorpay.com/v1/payments/${paymentId}`, {
      headers: {
        "Authorization": `Basic ${btoa(`${razorpayKeyId}:${razorpayKeySecret}`)}`,
      },
    });

    if (!paymentResponse.ok) {
      throw new Error("Failed to fetch payment details from Razorpay");
    }

    const payment = await paymentResponse.json();

    if (payment.status !== "captured") {
      throw new Error("Payment not captured");
    }

    // Create enrollment record in Supabase
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? ""
    );

    const { error: insertError } = await supabase
      .from("enrollments")
      .insert({
        razorpay_order_id: orderId,
        razorpay_payment_id: paymentId,
        track: track,
        user_email: userEmail,
        amount_paid: payment.amount || 2999,
        payment_status: "completed",
        enrolled_at: new Date().toISOString(),
      });

    if (insertError) {
      throw new Error(`Failed to create enrollment: ${insertError.message}`);
    }

    return new Response(JSON.stringify({ success: true, paymentId }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Payment verification error:", error);
    return new Response(JSON.stringify({ error: "Payment verification failed" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
