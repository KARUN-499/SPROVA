-- Create lessons table
CREATE TABLE IF NOT EXISTS lessons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  track TEXT NOT NULL,
  week INTEGER NOT NULL,
  prompt_text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(track, week)
);

-- Create submissions table
CREATE TABLE IF NOT EXISTS submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES lessons(id),
  response_text TEXT NOT NULL,
  ai_feedback TEXT,
  rating INTEGER CHECK (rating IN (-1, 1)), -- -1 for down, 1 for up
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create cohort_config table
CREATE TABLE IF NOT EXISTS cohort_config (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  cohort_start_date TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cohort_config ENABLE ROW LEVEL SECURITY;

-- Policies for lessons: anyone authenticated can read
CREATE POLICY "Authenticated users can read lessons" ON lessons
  FOR SELECT USING (auth.role() = 'authenticated');

-- Policies for submissions: users can read/write their own
CREATE POLICY "Users can manage own submissions" ON submissions
  FOR ALL USING (auth.uid() = user_id);

-- Policies for cohort_config: read only for authenticated, all for service role
CREATE POLICY "Authenticated users can read config" ON cohort_config
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Service role can manage config" ON cohort_config
  FOR ALL USING (auth.role() = 'service_role');

-- Insert initial config (placeholder date)
INSERT INTO cohort_config (id, cohort_start_date) 
VALUES (1, '2026-05-01 00:00:00+00')
ON CONFLICT (id) DO NOTHING;
