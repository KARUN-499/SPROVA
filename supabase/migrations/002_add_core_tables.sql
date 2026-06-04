-- Core Tables for Student Journey

-- Enrollments Table
CREATE TABLE enrollments (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_email text NOT NULL UNIQUE,
    razorpay_order_id text NOT NULL UNIQUE,
    track text NOT NULL,
    enrolled_at timestamptz DEFAULT now()
);

-- Lessons Table

CREATE TABLE lessons (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    week int NOT NULL CHECK (week >= 1 AND week <= 4),
    day int NOT NULL CHECK (day >= 1 AND day <= 7),
    prompt_text text NOT NULL,
    track text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- Submissions Table
CREATE TABLE submissions (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_email text NOT NULL,
    lesson_id bigint REFERENCES lessons(id) ON DELETE CASCADE,
    response_text text NOT NULL,
    ai_feedback text,
    rating int CHECK (rating >= 1 AND rating <= 5),
    submitted_at timestamptz DEFAULT now()
);

-- Community Posts Table
CREATE TABLE community_posts (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_email text NOT NULL,
    content text NOT NULL,
    posted_at timestamptz DEFAULT now()
);

-- Indexing
CREATE INDEX idx_lessons_track_week_day ON lessons(track, week, day);
CREATE INDEX idx_submissions_student_email ON submissions(student_email);
CREATE INDEX idx_submissions_lesson_id ON submissions(lesson_id);
CREATE INDEX idx_community_posts_student_email ON community_posts(student_email);

-- Enable RLS
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;

-- RLS Policies (Basic implementation using student_email as the identifier)
-- In a full Supabase setup, we would use auth.uid()
CREATE POLICY "Lessons are viewable by everyone" ON lessons FOR SELECT USING (true);
CREATE POLICY "Students can view their own submissions" ON submissions FOR SELECT USING (student_email = (SELECT auth.jwt() ->> 'email'));
CREATE POLICY "Students can insert their own submissions" ON submissions FOR INSERT WITH CHECK (student_email = (SELECT auth.jwt() ->> 'email'));
CREATE POLICY "Students can view all community posts" ON community_posts FOR SELECT USING (true);
CREATE POLICY "Students can insert their own community posts" ON community_posts FOR INSERT WITH CHECK (student_email = (SELECT auth.jwt() ->> 'email'));
