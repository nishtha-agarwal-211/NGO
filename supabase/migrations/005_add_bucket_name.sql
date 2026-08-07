-- ============================================================
-- 005_add_bucket_name.sql
-- Store the actual storage bucket name on each photo/video row
-- so that deletePhoto() uses the correct bucket deterministically
-- instead of guessing based on the media_type flag.
-- ============================================================

-- Add bucket_name column
ALTER TABLE photos
  ADD COLUMN IF NOT EXISTS bucket_name TEXT;

-- Backfill existing rows with best-guess bucket names.
-- Photos → 'event-photos', Videos → 'event-videos'.
-- (Videos that fell back to event-photos during upload will be wrong here,
--  but the app's delete logic retains a fallback for rows with no bucket_name.)
UPDATE photos SET bucket_name = 'event-photos' WHERE media_type = 'photo' AND bucket_name IS NULL;
UPDATE photos SET bucket_name = 'event-videos' WHERE media_type = 'video' AND bucket_name IS NULL;
