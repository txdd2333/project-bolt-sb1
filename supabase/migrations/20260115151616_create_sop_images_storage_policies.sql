/*
  # Create Storage Policies for SOP Images

  1. Storage Configuration
    - Bucket: sop-images (already created)
    - Public read access for all images
    - Authenticated users can upload images

  2. Security
    - SELECT: Public access (images need to be viewable)
    - INSERT: Authenticated users only
    - UPDATE: Owner can update their own images
    - DELETE: Owner can delete their own images

  3. Notes
    - File path format: user_id/filename
    - This ensures user ownership tracking
*/

CREATE POLICY "Public read access for sop images"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'sop-images');

CREATE POLICY "Authenticated users can upload sop images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'sop-images');

CREATE POLICY "Users can update their own sop images"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'sop-images' AND (storage.foldername(name))[1] = auth.uid()::text)
  WITH CHECK (bucket_id = 'sop-images' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can delete their own sop images"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'sop-images' AND (storage.foldername(name))[1] = auth.uid()::text);
