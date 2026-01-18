/*
  # Add definition field to workflows table

  1. Changes
    - Add `definition` column to `workflows` table to store workflow graph data
    - The column is jsonb type and nullable (NULL by default for existing records)
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'workflows' AND column_name = 'definition'
  ) THEN
    ALTER TABLE workflows ADD COLUMN definition jsonb DEFAULT '{}'::jsonb;
  END IF;
END $$;