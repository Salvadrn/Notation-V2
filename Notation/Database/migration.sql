-- =====================================================
-- Notation V2 - Supabase Database Migration
-- Run this in the Supabase SQL Editor
-- =====================================================

-- ENUMS
CREATE TYPE page_size AS ENUM ('a4', 'letter');
CREATE TYPE page_orientation AS ENUM ('portrait', 'landscape');
CREATE TYPE subscription_tier AS ENUM ('free', 'pro');

-- =====================================================
-- PROFILES
-- =====================================================
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    avatar_url TEXT,
    subscription_tier subscription_tier DEFAULT 'free',
    token_balance INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- =====================================================
-- FOLDERS
-- =====================================================
CREATE TABLE folders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES folders(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    path TEXT NOT NULL DEFAULT '',
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE folders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own folders"
    ON folders FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_folders_user_id ON folders(user_id);
CREATE INDEX idx_folders_parent_id ON folders(parent_id);

-- =====================================================
-- NOTEBOOKS
-- =====================================================
CREATE TABLE notebooks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    folder_id UUID REFERENCES folders(id) ON DELETE SET NULL,
    title TEXT NOT NULL DEFAULT 'Untitled Notebook',
    cover_color TEXT DEFAULT '#6366F1',
    sort_order INTEGER DEFAULT 0,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE notebooks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own notebooks"
    ON notebooks FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Shared notebook access (read-only for shared users)
CREATE POLICY "Shared users can view notebooks"
    ON notebooks FOR SELECT
    USING (
        auth.uid() = user_id OR
        id IN (SELECT notebook_id FROM shared_notebooks WHERE shared_with_id = auth.uid())
    );

CREATE INDEX idx_notebooks_user_id ON notebooks(user_id);
CREATE INDEX idx_notebooks_folder_id ON notebooks(folder_id);

-- =====================================================
-- SECTIONS
-- =====================================================
CREATE TABLE sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notebook_id UUID NOT NULL REFERENCES notebooks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT 'Untitled Section',
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE sections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own sections"
    ON sections FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_sections_notebook_id ON sections(notebook_id);

-- =====================================================
-- PAGES
-- =====================================================
CREATE TABLE pages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    section_id UUID NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT DEFAULT '',
    page_size page_size DEFAULT 'a4',
    orientation page_orientation DEFAULT 'portrait',
    text_content JSONB DEFAULT '{}',
    sort_order INTEGER DEFAULT 0,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE pages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own pages"
    ON pages FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_pages_section_id ON pages(section_id);

-- =====================================================
-- PAGE LAYERS
-- =====================================================
CREATE TABLE page_layers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    page_id UUID NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    layer_type TEXT NOT NULL CHECK (layer_type IN ('text', 'drawing', 'handwriting')),
    drawing_data BYTEA,
    is_visible BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE page_layers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own layers"
    ON page_layers FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_page_layers_page_id ON page_layers(page_id);

-- =====================================================
-- GLYPHS (Handwriting Characters)
-- =====================================================
CREATE TABLE glyphs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    character TEXT NOT NULL,
    variation_index INTEGER DEFAULT 0,
    stroke_data BYTEA NOT NULL,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE glyphs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own glyphs"
    ON glyphs FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_glyphs_user_character ON glyphs(user_id, character);

-- =====================================================
-- AI JOBS
-- =====================================================
CREATE TABLE ai_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    page_id UUID REFERENCES pages(id) ON DELETE SET NULL,
    input_type TEXT NOT NULL CHECK (input_type IN ('photo', 'pdf', 'image')),
    input_url TEXT,
    output_notes JSONB,
    tokens_used INTEGER DEFAULT 0,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE ai_jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own AI jobs"
    ON ai_jobs FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- SHARED NOTEBOOKS
-- =====================================================
CREATE TABLE shared_notebooks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notebook_id UUID NOT NULL REFERENCES notebooks(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    shared_with_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    permission TEXT DEFAULT 'view' CHECK (permission IN ('view', 'edit')),
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(notebook_id, shared_with_id)
);

ALTER TABLE shared_notebooks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owners can manage shared notebooks"
    ON shared_notebooks FOR ALL
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Shared users can view their shares"
    ON shared_notebooks FOR SELECT
    USING (auth.uid() = shared_with_id);

-- =====================================================
-- TOKEN TRANSACTIONS
-- =====================================================
CREATE TABLE token_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL,
    reason TEXT NOT NULL,
    reference_id TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE token_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own transactions"
    ON token_transactions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own transactions"
    ON token_transactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_token_transactions_user_id ON token_transactions(user_id);

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Token balance increment function (called via RPC)
CREATE OR REPLACE FUNCTION increment_token_balance(user_id_input UUID, amount_input INTEGER)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE profiles
    SET token_balance = token_balance + amount_input,
        updated_at = now()
    WHERE id = user_id_input;
END;
$$;

-- Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all relevant tables
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_folders_updated_at
    BEFORE UPDATE ON folders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notebooks_updated_at
    BEFORE UPDATE ON notebooks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sections_updated_at
    BEFORE UPDATE ON sections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pages_updated_at
    BEFORE UPDATE ON pages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_page_layers_updated_at
    BEFORE UPDATE ON page_layers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- AUTO-CREATE PROFILE ON SIGNUP
-- =====================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    INSERT INTO profiles (id, full_name, token_balance)
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data->>'full_name',
        100  -- Starter token balance
    );
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- ENABLE REALTIME
-- =====================================================
ALTER PUBLICATION supabase_realtime ADD TABLE pages;
ALTER PUBLICATION supabase_realtime ADD TABLE page_layers;
ALTER PUBLICATION supabase_realtime ADD TABLE notebooks;
ALTER PUBLICATION supabase_realtime ADD TABLE sections;

-- =====================================================
-- STORAGE BUCKETS
-- Run these in the Supabase Dashboard > Storage
-- or use the API:
-- =====================================================
-- CREATE BUCKET: avatars (public)
-- CREATE BUCKET: glyphs (private, user-scoped)
-- CREATE BUCKET: attachments (private, user-scoped)
-- CREATE BUCKET: exports (private, user-scoped)

-- Storage policies (run in SQL Editor):

-- Avatars bucket (public read, authenticated write)
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);

CREATE POLICY "Avatar upload" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Avatar read" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

-- Glyphs bucket (private, user-scoped)
INSERT INTO storage.buckets (id, name, public) VALUES ('glyphs', 'glyphs', false);

CREATE POLICY "Glyph access" ON storage.objects
    FOR ALL USING (
        bucket_id = 'glyphs' AND auth.uid()::text = (storage.foldername(name))[1]
    ) WITH CHECK (
        bucket_id = 'glyphs' AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Attachments bucket (private, user-scoped)
INSERT INTO storage.buckets (id, name, public) VALUES ('attachments', 'attachments', false);

CREATE POLICY "Attachment access" ON storage.objects
    FOR ALL USING (
        bucket_id = 'attachments' AND auth.uid()::text = (storage.foldername(name))[1]
    ) WITH CHECK (
        bucket_id = 'attachments' AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Exports bucket (private, user-scoped)
INSERT INTO storage.buckets (id, name, public) VALUES ('exports', 'exports', false);

CREATE POLICY "Export access" ON storage.objects
    FOR ALL USING (
        bucket_id = 'exports' AND auth.uid()::text = (storage.foldername(name))[1]
    ) WITH CHECK (
        bucket_id = 'exports' AND auth.uid()::text = (storage.foldername(name))[1]
    );
