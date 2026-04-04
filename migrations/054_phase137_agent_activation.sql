ALTER TABLE agents
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active';

UPDATE agents
SET status = 'active'
WHERE status IS NULL OR BTRIM(status) = '';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'agents_status_check'
  ) THEN
    ALTER TABLE agents
    ADD CONSTRAINT agents_status_check
    CHECK (status IN ('draft', 'active'));
  END IF;
END $$;
