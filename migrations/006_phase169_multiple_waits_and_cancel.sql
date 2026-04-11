ALTER TABLE public.agent_session_waits
    ADD COLUMN IF NOT EXISTS summary text,
    ADD COLUMN IF NOT EXISTS context_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS cancellation_note text;

DROP INDEX IF EXISTS public.idx_agent_session_waits_one_active_per_session;

UPDATE public.agent_sessions
SET status = 'running'
WHERE status = 'waiting';

