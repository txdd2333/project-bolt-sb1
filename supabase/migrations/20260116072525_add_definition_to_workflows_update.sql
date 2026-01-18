/*
  # Update workflows table with definition field

  1. Changes
    - Confirms definition column exists in workflows table (already added in previous migration)
    - No changes needed as definition was already added

  2. Notes
    - This migration ensures the definition field is available
    - The field stores the X6 graph JSON structure
*/

-- Verify definition column exists (it should from migration 20260116032128)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'workflows' AND column_name = 'definition'
  ) THEN
    ALTER TABLE workflows ADD COLUMN definition jsonb DEFAULT '{}'::jsonb;
  END IF;
END $$;
