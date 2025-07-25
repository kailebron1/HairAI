--  create_upload_sessions_table.sql

CREATE TABLE IF NOT EXISTS public.upload_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    image_url TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- AI-generated attributes
    face_shape TEXT,
    skin_tone TEXT,
    hair_color TEXT,
    jawline TEXT,
    has_eyeglasses BOOLEAN,
    has_facial_hair BOOLEAN,
    
    -- Raw analysis data from Rekognition
    raw_analysis_data JSONB
);

-- Row-level security policies
ALTER TABLE public.upload_sessions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own upload sessions.
CREATE POLICY "Allow individual read access"
ON public.upload_sessions
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can only insert their own upload sessions.
CREATE POLICY "Allow individual insert access"
ON public.upload_sessions
FOR INSERT
WITH CHECK (auth.uid() = user_id); 