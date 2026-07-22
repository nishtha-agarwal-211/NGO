-- ============================================================
-- 002_add_video_support.sql
-- Add media_type and video_duration columns to photos table
-- to support video uploads alongside photos.
-- ============================================================

-- Add media_type column: 'photo' (default) or 'video'
ALTER TABLE photos
  ADD COLUMN IF NOT EXISTS media_type TEXT NOT NULL DEFAULT 'photo';

-- Add video_duration_seconds for video files
ALTER TABLE photos
  ADD COLUMN IF NOT EXISTS video_duration_seconds INTEGER;

-- Add content_type to store the MIME type (image/jpeg, video/mp4, etc.)
ALTER TABLE photos
  ADD COLUMN IF NOT EXISTS content_type TEXT;
