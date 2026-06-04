-- Create enrollments table
CREATE TABLE IF NOT EXISTS enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  razorpay_order_id TEXT NOT NULL,
  razorpay_payment_id TEXT NOT NULL,
  track TEXT NOT NULL,
  user_email TEXT,
  amount_paid INTEGER NOT NULL DEFAULT 2999,
  payment_status TEXT NOT NULL DEFAULT 'pending',
  enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index on payment ID for quick lookups
CREATE INDEX IF NOT EXISTS idx_enrollments_payment_id ON enrollments(razorpay_payment_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_order_id ON enrollments(razorpay_order_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_email ON enrollments(user_email);

-- Enable Row Level Security
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;

-- Policy: Allow service role to do everything (for Edge Functions)
CREATE POLICY "Service role can do everything" ON enrollments
  FOR ALL USING (auth.role() = 'service_role');

-- Policy: Allow authenticated users to view their own enrollments
CREATE POLICY "Users can view own enrollments" ON enrollments
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- Add trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_enrollments_updated_at
  BEFORE UPDATE ON enrollments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
