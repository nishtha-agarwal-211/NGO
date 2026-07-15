-- ============================================================
-- 001_initial_schema.sql
-- NGO Management App — Supabase Postgres Schema
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE member_role AS ENUM ('admin', 'volunteer', 'member');
CREATE TYPE donor_type AS ENUM ('one_time', 'recurring');
CREATE TYPE donation_type AS ENUM ('cash', 'kind', 'service');
CREATE TYPE project_type AS ENUM ('recurring', 'ongoing');
CREATE TYPE project_status AS ENUM ('active', 'completed', 'paused');
CREATE TYPE news_type AS ENUM ('article', 'video');

-- ============================================================
-- PROFILES (extends Supabase auth.users)
-- ============================================================
-- Maps Supabase Auth users to app roles.
-- Admin gets a profile on first setup; member profiles are
-- created when Admin adds a member with an email.

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role member_role NOT NULL DEFAULT 'member',
    member_id UUID,  -- FK added after members table exists
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- MEMBERS
-- ============================================================

CREATE TABLE members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    photo_url TEXT,              -- Supabase Storage URL
    photo_storage_path TEXT,    -- Storage path for deletion
    mobile TEXT NOT NULL,
    email TEXT,
    address TEXT,
    date_of_birth DATE,
    wedding_anniversary DATE,
    role member_role NOT NULL DEFAULT 'member',
    join_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    tags TEXT[],                 -- e.g., ['cooking', 'driving', 'weekend-available']
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_members_mobile ON members(mobile);
CREATE INDEX idx_members_dob ON members(date_of_birth);
CREATE INDEX idx_members_anniversary ON members(wedding_anniversary);
CREATE INDEX idx_members_name ON members(name);
CREATE INDEX idx_members_auth_user ON members(auth_user_id);

-- Now add the FK from profiles → members
ALTER TABLE profiles
    ADD CONSTRAINT fk_profiles_member
    FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE SET NULL;

-- ============================================================
-- DONORS
-- ============================================================

CREATE TABLE donors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    mobile TEXT NOT NULL,
    email TEXT,
    address TEXT,
    donor_type donor_type NOT NULL DEFAULT 'one_time',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_donors_mobile ON donors(mobile);
CREATE INDEX idx_donors_name ON donors(name);

-- ============================================================
-- PROJECTS
-- ============================================================

CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,              -- e.g., 'food', 'education', 'medical'
    project_type project_type NOT NULL DEFAULT 'ongoing',
    status project_status NOT NULL DEFAULT 'active',
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,             -- NULL = open-ended
    -- Recurrence fields (for recurring projects like Wednesday food donation)
    recurrence_day_of_week INTEGER,   -- 0=Sunday, 1=Monday, ..., 3=Wednesday, etc.
    recurrence_time TIME,
    recurrence_location TEXT,
    -- Campaign/ongoing fields
    goal_description TEXT,     -- e.g., "Sponsor 50 students' school fees"
    target_amount DECIMAL(12,2),
    target_beneficiary_count INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_type ON projects(project_type);

-- ============================================================
-- EVENTS (instances of a project)
-- ============================================================

CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    title TEXT,                 -- auto-generated or custom
    event_date DATE NOT NULL,
    event_time TIME,
    location TEXT,
    beneficiary_count INTEGER DEFAULT 0,
    beneficiary_details TEXT,  -- optional notes for school/medical cases
    notes TEXT,                -- summary of the day
    status TEXT NOT NULL DEFAULT 'upcoming',  -- upcoming, completed, cancelled
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_events_project ON events(project_id);
CREATE INDEX idx_events_date ON events(event_date);
CREATE INDEX idx_events_status ON events(status);

-- ============================================================
-- EVENT VOLUNTEERS (many-to-many: events ↔ members, plus ad-hoc)
-- ============================================================

CREATE TABLE event_volunteers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    member_id UUID REFERENCES members(id) ON DELETE SET NULL,  -- NULL if ad-hoc
    volunteer_name TEXT,       -- used when member_id is NULL (ad-hoc volunteer)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_event_volunteers_event ON event_volunteers(event_id);
CREATE INDEX idx_event_volunteers_member ON event_volunteers(member_id);

-- Ensure either member_id or volunteer_name is provided
ALTER TABLE event_volunteers
    ADD CONSTRAINT chk_volunteer_identity
    CHECK (member_id IS NOT NULL OR volunteer_name IS NOT NULL);

-- ============================================================
-- DONATIONS
-- ============================================================

CREATE TABLE donations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    donor_id UUID NOT NULL REFERENCES donors(id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
    event_id UUID REFERENCES events(id) ON DELETE SET NULL,
    donation_type donation_type NOT NULL DEFAULT 'cash',
    amount DECIMAL(12,2),        -- for cash donations
    item_description TEXT,       -- for in-kind/service donations
    donation_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_donations_donor ON donations(donor_id);
CREATE INDEX idx_donations_project ON donations(project_id);
CREATE INDEX idx_donations_event ON donations(event_id);
CREATE INDEX idx_donations_date ON donations(donation_date);

-- ============================================================
-- EVENT EXPENSES (line items per event)
-- ============================================================

CREATE TABLE event_expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    description TEXT NOT NULL,     -- e.g., "Rice - 50kg", "Transport"
    amount DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_event_expenses_event ON event_expenses(event_id);

-- ============================================================
-- PHOTOS
-- ============================================================

CREATE TABLE photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,      -- Supabase Storage path (full-size)
    thumbnail_path TEXT,            -- Supabase Storage path (thumbnail)
    url TEXT NOT NULL,              -- Public/signed URL for full-size
    thumbnail_url TEXT,             -- Public/signed URL for thumbnail
    caption TEXT,
    is_featured BOOLEAN DEFAULT FALSE,  -- mark for use in news/public display
    uploaded_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_photos_event ON photos(event_id);

-- ============================================================
-- NEWS ITEMS (Press / Media Coverage)
-- ============================================================

CREATE TABLE news_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    source_name TEXT NOT NULL,      -- e.g., "Times of India", "Local TV Channel"
    news_type news_type NOT NULL,
    article_url TEXT,               -- URL of the online article
    youtube_url TEXT,               -- YouTube video URL
    clipping_image_url TEXT,        -- Supabase Storage URL for uploaded clipping photo
    clipping_storage_path TEXT,     -- Storage path for clipping
    linked_project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
    linked_event_id UUID REFERENCES events(id) ON DELETE SET NULL,
    published_date DATE NOT NULL,
    summary TEXT,                   -- optional short description
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_news_type ON news_items(news_type);
CREATE INDEX idx_news_published ON news_items(published_date DESC);
CREATE INDEX idx_news_source ON news_items(source_name);

-- ============================================================
-- UPDATED_AT TRIGGER (auto-update timestamps)
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER trg_profiles_updated BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_members_updated BEFORE UPDATE ON members
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_donors_updated BEFORE UPDATE ON donors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_projects_updated BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_events_updated BEFORE UPDATE ON events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_donations_updated BEFORE UPDATE ON donations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_news_items_updated BEFORE UPDATE ON news_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE members ENABLE ROW LEVEL SECURITY;
ALTER TABLE donors ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_volunteers ENABLE ROW LEVEL SECURITY;
ALTER TABLE donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_items ENABLE ROW LEVEL SECURITY;

-- Helper function: check if current user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- --------------------
-- PROFILES policies
-- --------------------
CREATE POLICY "Admin full access to profiles"
    ON profiles FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "Users can read own profile"
    ON profiles FOR SELECT
    USING (id = auth.uid());

-- --------------------
-- MEMBERS policies
-- --------------------
CREATE POLICY "Admin full access to members"
    ON members FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "Members can read own record"
    ON members FOR SELECT
    USING (auth_user_id = auth.uid());

-- --------------------
-- DONORS policies (admin-only)
-- --------------------
CREATE POLICY "Admin full access to donors"
    ON donors FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

-- --------------------
-- PROJECTS policies
-- --------------------
CREATE POLICY "Admin full access to projects"
    ON projects FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "Authenticated users can read projects"
    ON projects FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- --------------------
-- EVENTS policies
-- --------------------
CREATE POLICY "Admin full access to events"
    ON events FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "Authenticated users can read events"
    ON events FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- --------------------
-- EVENT VOLUNTEERS policies
-- --------------------
CREATE POLICY "Admin full access to event_volunteers"
    ON event_volunteers FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "Members can read event volunteers"
    ON event_volunteers FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- --------------------
-- DONATIONS policies (admin-only)
-- --------------------
CREATE POLICY "Admin full access to donations"
    ON donations FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

-- --------------------
-- EVENT EXPENSES policies (admin-only)
-- --------------------
CREATE POLICY "Admin full access to event_expenses"
    ON event_expenses FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

-- --------------------
-- PHOTOS policies
-- --------------------
CREATE POLICY "Admin full access to photos"
    ON photos FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "Authenticated users can read photos"
    ON photos FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- --------------------
-- NEWS ITEMS policies (public read!)
-- --------------------
CREATE POLICY "Anyone can read news items"
    ON news_items FOR SELECT
    USING (TRUE);  -- No auth required for reading news

CREATE POLICY "Admin full access to news items"
    ON news_items FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());
