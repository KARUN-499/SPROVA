# Supabase Setup for Sprova

## Step 1: Set Razorpay Secrets in Supabase

Run these commands in Supabase Dashboard → Edge Functions → Manage Secrets:

```
RAZORPAY_KEY_ID=YOUR_RAZORPAY_KEY_ID
RAZORPAY_KEY_SECRET=<your_secret_from_razorpay_dashboard>
```

**Important:** Get the full `RAZORPAY_KEY_ID` from Razorpay Dashboard → Settings → API Keys → Test Mode. The current key appears truncated.

## Step 2: Deploy Edge Functions

```bash
# Install Supabase CLI if not installed
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref iyphhwvqiukhrejipeww

# Deploy Edge Functions
supabase functions deploy create-order
supabase functions deploy verify-payment
```

## Step 3: Run Database Migration

In Supabase Dashboard → SQL Editor, run the contents of `migrations/001_create_enrollments_table.sql`

Or via CLI:
```bash
supabase db push
```

## Step 4: Test Payment Flow

1. Run the app: `flutter run -d <device>`
2. Select a track
3. Click "Pay Rs. 2,999 & Secure My Seat"
4. Complete test payment with Razorpay test card
5. Verify enrollment record created in Supabase

## Test Card Details (Razorpay Test Mode)

- Card: 4111 1111 1111 1111
- CVV: Any 3 digits
- Expiry: Any future date
- SMS OTP: Not required in test mode

## Production Checklist

Before going live:

- [ ] Switch to Razorpay live keys (update secrets)
- [ ] Update `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` in Supabase
- [ ] Update `.env` with live `RAZORPAY_KEY_ID` (client-side only)
- [ ] Test with real payment (small amount first)
- [ ] Enable Supabase RLS policies for production
