# NGO Management App — Implementation Plan

## Summary

A Flutter (Dart) cross-platform mobile app (Android-first, iOS-ready) backed by Supabase (Postgres + Auth + Storage). Single admin has full CRUD access; members/volunteers can log in for read-only views. Public News archive is accessible without login.

---

## Confirmed Decisions (from PRD + clarifications)

| Decision | Choice |
|---|---|
| Framework | **Flutter** (Dart), single codebase for Android + future iOS |
| Backend | **Supabase** free tier (Postgres, Auth, Storage) |
| Auth | **Email + password** via Supabase Auth |
| User roles | **Admin** (full CRUD) + **Member** (read-only login, sees own profile + events) |
| Offline support | **drift** (SQLite ORM for Flutter) for local queue, background sync |
| Member photos | Uploaded to Supabase Storage in v1 |
| Event volunteers | Pick from Members OR type ad-hoc names |
| News bulk import | Not needed — manual entry for ~20-25 items |
| State management | **Riverpod** (robust, testable, recommended for Flutter) |
| Navigation | **GoRouter** (declarative, supports deep links, auth guards) |

---

## Confirmed Member Access Rules

| Area | Member access | Admin access |
|---|---|---|
| Member profiles | **All profiles** (read-only) | Full CRUD |
| Projects & events | **All** (read-only) | Full CRUD |
| Donor data & donations | **Yes** (read-only) | Full CRUD |
| Event photos & news | Read-only / public news | Full CRUD |
| Dashboard stats | Read-only (when built) | Full access |
| Editing anything | **No** | Yes |

> [!NOTE]
> **Member authentication flow:** Since members are first created by Admin in the directory, I'll implement it so that when Admin adds a member with an email, a Supabase Auth account is auto-created (or an invite is sent). The member can then set their password and log in. This avoids a separate "registration" flow.

---

## Proposed Project Structure

```
ngo/
├── NGO_App_PRD.md                    # Existing PRD
├── supabase/
│   ├── migrations/
│   │   └── 001_initial_schema.sql    # Full database schema
│   ├── seed.sql                      # Optional seed data
│   └── storage_policies.sql          # Storage bucket + RLS policies
│
└── ngo_app/                          # Flutter project root
    ├── android/
    ├── ios/
    ├── lib/
    │   ├── main.dart                 # App entry point
    │   ├── app.dart                  # MaterialApp + GoRouter setup
    │   │
    │   ├── config/
    │   │   ├── supabase_config.dart  # Supabase URL + anon key
    │   │   ├── theme.dart            # App theme (colors, typography)
    │   │   └── constants.dart        # App-wide constants
    │   │
    │   ├── models/                   # Data classes (freezed/json_serializable)
    │   │   ├── member.dart
    │   │   ├── donor.dart
    │   │   ├── donation.dart
    │   │   ├── project.dart
    │   │   ├── event.dart
    │   │   ├── photo.dart
    │   │   ├── news_item.dart
    │   │   └── event_volunteer.dart
    │   │
    │   ├── services/                 # Supabase + business logic
    │   │   ├── auth_service.dart
    │   │   ├── member_service.dart
    │   │   ├── donor_service.dart
    │   │   ├── donation_service.dart
    │   │   ├── project_service.dart
    │   │   ├── event_service.dart
    │   │   ├── photo_service.dart
    │   │   ├── news_service.dart
    │   │   ├── notification_service.dart
    │   │   └── sync_service.dart     # Offline queue + sync logic
    │   │
    │   ├── providers/                # Riverpod providers
    │   │   ├── auth_provider.dart
    │   │   ├── member_provider.dart
    │   │   ├── donor_provider.dart
    │   │   ├── project_provider.dart
    │   │   ├── event_provider.dart
    │   │   ├── news_provider.dart
    │   │   └── dashboard_provider.dart
    │   │
    │   ├── screens/                  # Full-page screens
    │   │   ├── auth/
    │   │   │   └── login_screen.dart
    │   │   ├── dashboard/
    │   │   │   └── dashboard_screen.dart
    │   │   ├── members/
    │   │   │   ├── member_list_screen.dart
    │   │   │   ├── member_detail_screen.dart
    │   │   │   └── member_form_screen.dart
    │   │   ├── donors/
    │   │   │   ├── donor_list_screen.dart
    │   │   │   ├── donor_detail_screen.dart
    │   │   │   └── donor_form_screen.dart
    │   │   ├── projects/
    │   │   │   ├── project_list_screen.dart
    │   │   │   ├── project_detail_screen.dart
    │   │   │   └── project_form_screen.dart
    │   │   ├── events/
    │   │   │   ├── event_detail_screen.dart
    │   │   │   ├── event_form_screen.dart
    │   │   │   └── calendar_screen.dart
    │   │   ├── photos/
    │   │   │   ├── photo_gallery_screen.dart
    │   │   │   └── photo_viewer_screen.dart
    │   │   └── news/
    │   │       ├── news_list_screen.dart
    │   │       ├── news_detail_screen.dart
    │   │       └── news_form_screen.dart
    │   │
    │   ├── widgets/                  # Reusable components
    │   │   ├── app_drawer.dart
    │   │   ├── search_bar.dart
    │   │   ├── stat_card.dart
    │   │   ├── member_card.dart
    │   │   ├── donor_card.dart
    │   │   ├── event_card.dart
    │   │   ├── news_card.dart
    │   │   ├── photo_grid.dart
    │   │   ├── donation_form_widget.dart
    │   │   ├── volunteer_picker.dart
    │   │   └── empty_state.dart
    │   │
    │   ├── database/                 # Local SQLite (drift) for offline
    │   │   ├── app_database.dart
    │   │   ├── app_database.g.dart   # Generated
    │   │   └── tables/
    │   │       └── sync_queue.dart
    │   │
    │   └── utils/
    │       ├── date_utils.dart
    │       ├── image_utils.dart      # Compression + thumbnail generation
    │       ├── validators.dart
    │       └── extensions.dart
    │
    ├── pubspec.yaml
    └── README.md
```

---

## Supabase Schema (SQL)

This is the complete initial migration. All tables use UUIDs, have `created_at`/`updated_at` timestamps, and enforce foreign key relationships.

```sql
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

-- ============================================================
-- EVENTS (instances of a project)
-- ============================================================

CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    title TEXT,                 -- auto-generated or custom, e.g., "Wednesday Food Donation — Jul 16, 2026"
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

CREATE POLICY "Authenticated users can read all members"
    ON members FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- --------------------
-- DONORS policies
-- --------------------
CREATE POLICY "Admin full access to donors"
    ON donors FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "Authenticated users can read donors"
    ON donors FOR SELECT
    USING (auth.uid() IS NOT NULL);

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
-- DONATIONS policies
-- --------------------
CREATE POLICY "Admin full access to donations"
    ON donations FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "Authenticated users can read donations"
    ON donations FOR SELECT
    USING (auth.uid() IS NOT NULL);

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
```

---

## Supabase Storage Buckets

```sql
-- Storage bucket for event photos (private, requires auth)
INSERT INTO storage.buckets (id, name, public) VALUES ('event-photos', 'event-photos', false);

-- Storage bucket for member profile photos (private)
INSERT INTO storage.buckets (id, name, public) VALUES ('member-photos', 'member-photos', false);

-- Storage bucket for news clippings (public, for the public News archive)
INSERT INTO storage.buckets (id, name, public) VALUES ('news-clippings', 'news-clippings', true);

-- Storage policies
-- Event photos: admin can upload/delete, authenticated can view
CREATE POLICY "Admin upload event photos" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'event-photos' AND is_admin());
CREATE POLICY "Admin delete event photos" ON storage.objects
    FOR DELETE USING (bucket_id = 'event-photos' AND is_admin());
CREATE POLICY "Auth users view event photos" ON storage.objects
    FOR SELECT USING (bucket_id = 'event-photos' AND auth.uid() IS NOT NULL);

-- Member photos: admin can upload/delete, auth users can view
CREATE POLICY "Admin upload member photos" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'member-photos' AND is_admin());
CREATE POLICY "Admin delete member photos" ON storage.objects
    FOR DELETE USING (bucket_id = 'member-photos' AND is_admin());
CREATE POLICY "Auth users view member photos" ON storage.objects
    FOR SELECT USING (bucket_id = 'member-photos' AND auth.uid() IS NOT NULL);

-- News clippings: admin can upload/delete, anyone can view (public bucket)
CREATE POLICY "Admin upload news clippings" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'news-clippings' AND is_admin());
CREATE POLICY "Admin delete news clippings" ON storage.objects
    FOR DELETE USING (bucket_id = 'news-clippings' AND is_admin());
CREATE POLICY "Anyone view news clippings" ON storage.objects
    FOR SELECT USING (bucket_id = 'news-clippings');
```

---

## Key Flutter Dependencies

| Package | Purpose |
|---|---|
| `supabase_flutter` | Supabase client (auth, database, storage) |
| `flutter_riverpod` | State management |
| `go_router` | Navigation + auth guards |
| `drift` + `sqlite3_flutter_libs` | Local SQLite for offline queue |
| `freezed` + `json_serializable` | Immutable data classes + JSON serialization |
| `image_picker` | Camera/gallery photo selection |
| `flutter_image_compress` | Photo compression + thumbnail generation |
| `connectivity_plus` | Network status detection for offline mode |
| `workmanager` | Background sync when connectivity returns |
| `flutter_local_notifications` | Birthday/event reminders |
| `intl` | Date formatting, localization |
| `cached_network_image` | Image caching for galleries |
| `url_launcher` | WhatsApp/SMS/call shortcuts |
| `youtube_player_flutter` | YouTube embed in News screen |
| `table_calendar` | Calendar view for events |

---

## Proposed Changes

### Milestone 1: Project Setup + Supabase Schema

#### [NEW] [supabase/migrations/001_initial_schema.sql](file:///Users/nishtha/Desktop/ngo/supabase/migrations/001_initial_schema.sql)
Complete database schema as shown above — all tables, indexes, enums, triggers, RLS policies.

#### [NEW] [supabase/storage_policies.sql](file:///Users/nishtha/Desktop/ngo/supabase/storage_policies.sql)
Storage bucket creation and access policies.

#### [NEW] Flutter project (`ngo_app/`)
Scaffold via `flutter create`, configure Supabase client, theme, GoRouter shell with auth guard.

---

### Milestone 2: Auth + Member Management

#### [NEW] Auth screens and service
- Login screen (email + password)
- Auth service wrapping Supabase Auth
- Auth provider (Riverpod) managing session state
- GoRouter auth redirect (unauthenticated → login, authenticated → dashboard)

#### [NEW] Member CRUD
- Member list screen (searchable, filterable by role/tags)
- Member detail screen (profile view with "Wish" quick actions — WhatsApp/SMS/call)
- Member form screen (add/edit with photo upload)
- Birthday/anniversary reminder logic (query members with upcoming dates within 7 days)

---

### Milestone 3: Donor Management

#### [NEW] Donor CRUD
- Donor list screen (searchable)
- Donor detail screen (contribution history)
- Donor form screen (with duplicate detection by mobile number)
- Auto-create donor flow (used later from event donation logging)

---

### Milestone 4: Project & Event Management

#### [NEW] Project CRUD
- Project list/detail/form screens
- Recurring project setup (day of week, time, location)
- Weekly event auto-generation logic (create next 4 weeks of events for recurring projects)

#### [NEW] Event CRUD
- Event detail screen (attendance, beneficiaries, donations, expenses, photos, notes)
- Event form screen
- Calendar view (all events across all projects)
- Volunteer picker widget (select from Members + ad-hoc entry)
- Donation logging from within an event (with auto-donor creation)
- Expense line-item logging

---

### Milestone 5: Photo Upload + Offline Support

#### [NEW] Photo management
- Camera/gallery picker on event detail screen
- Client-side image compression + thumbnail generation
- Upload to Supabase Storage with proper paths
- Photo gallery per event and per project

#### [NEW] Offline queue
- drift (SQLite) tables for sync queue (pending creates/updates/photo uploads)
- Connectivity detection
- Background sync via WorkManager
- Sync status indicator in UI

---

### Milestone 6: News & Media Coverage

#### [NEW] News archive
- News list screen (chronological, filterable by type + year, searchable)
- News detail screen (article link / YouTube embed)
- News form screen (admin only — add article or video)
- Public access (no auth required to view news)

---

### Milestone 7: Dashboard + Notifications

#### [NEW] Dashboard
- Today/this week's events
- Upcoming birthdays/anniversaries (next 7 days)
- Recent donors
- Quick stats (total members, donors, monthly donations, events held)

#### [NEW] Notifications
- Local notifications for birthday/anniversary reminders
- Event reminders (e.g., "Wednesday Food Donation tomorrow")
- Scheduled notification checks via WorkManager

---

## Verification Plan

### Automated Tests
- Unit tests for services (member, donor, donation, project, event, news)
- Widget tests for key screens (login, member form, event form)
- Integration tests for auth flow and offline sync

### Manual Verification
- Run on Android emulator and/or physical device
- Test offline workflow: airplane mode → log event → re-enable network → verify sync
- Test all CRUD operations for each entity
- Verify RLS policies (member login can only see allowed data)
- Verify public News archive works without login
- Verify photo upload/compression/thumbnail flow
- Verify birthday/anniversary reminder notifications

---

## Build Order

I will build and deliver incrementally in this order, pausing after each milestone for your review:

1. **Milestone 1** — Flutter project scaffold + Supabase SQL files
2. **Milestone 2** — Auth + Member Management
3. **Milestone 3** — Donor Management
4. **Milestone 4** — Project & Event Management
5. **Milestone 5** — Photo Upload + Offline Support
6. **Milestone 6** — News & Media Coverage
7. **Milestone 7** — Dashboard + Notifications
