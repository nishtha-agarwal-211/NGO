-- ============================================================
-- Supabase Storage Buckets & Policies
-- Run this in the Supabase SQL Editor after the schema migration.
-- ============================================================

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public)
VALUES ('event-photos', 'event-photos', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('member-photos', 'member-photos', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('news-clippings', 'news-clippings', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- EVENT PHOTOS policies
-- Admin can upload/update/delete; authenticated users can view
-- ============================================================

CREATE POLICY "Admin upload event photos"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'event-photos' AND (SELECT is_admin()));

CREATE POLICY "Admin update event photos"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'event-photos' AND (SELECT is_admin()));

CREATE POLICY "Admin delete event photos"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'event-photos' AND (SELECT is_admin()));

CREATE POLICY "Auth users view event photos"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'event-photos' AND auth.uid() IS NOT NULL);

-- ============================================================
-- MEMBER PHOTOS policies
-- Admin can upload/update/delete; authenticated users can view
-- ============================================================

CREATE POLICY "Admin upload member photos"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'member-photos' AND (SELECT is_admin()));

CREATE POLICY "Admin update member photos"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'member-photos' AND (SELECT is_admin()));

CREATE POLICY "Admin delete member photos"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'member-photos' AND (SELECT is_admin()));

CREATE POLICY "Auth users view member photos"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'member-photos' AND auth.uid() IS NOT NULL);

-- ============================================================
-- NEWS CLIPPINGS policies (public bucket)
-- Admin can upload/update/delete; anyone can view
-- ============================================================

CREATE POLICY "Admin upload news clippings"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'news-clippings' AND (SELECT is_admin()));

CREATE POLICY "Admin update news clippings"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'news-clippings' AND (SELECT is_admin()));

CREATE POLICY "Admin delete news clippings"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'news-clippings' AND (SELECT is_admin()));

CREATE POLICY "Anyone view news clippings"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'news-clippings');
