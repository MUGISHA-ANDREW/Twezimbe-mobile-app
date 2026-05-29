-- ============================================================================
-- Supabase Storage Policies for Avatars Bucket
-- ============================================================================
-- Run these commands in your Supabase SQL Editor to set up storage policies
-- for the 'avatars' bucket.
--
-- Prerequisites:
-- 1. Create a public bucket named 'avatars' in Supabase Storage
-- 2. Run this SQL script in the SQL Editor
-- ============================================================================

-- Policy 1: Allow authenticated users to upload their own avatars
-- This ensures users can only upload files to their own folder (user_id)
CREATE POLICY "Users can upload their own avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 2: Allow authenticated users to update their own avatars
-- This allows users to replace existing avatar files
CREATE POLICY "Users can update their own avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' 
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'avatars' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 3: Allow authenticated users to delete their own avatars
-- This enables automatic cleanup of old profile photos
CREATE POLICY "Users can delete their own avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 4: Allow public read access to all avatars
-- This is necessary so profile photos can be displayed without authentication
CREATE POLICY "Public can view avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- ============================================================================
-- Verification Query
-- ============================================================================
-- Run this to verify your policies are set up correctly:
-- SELECT * FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';
