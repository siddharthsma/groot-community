ALTER TABLE public.agent_sessions
    ADD COLUMN IF NOT EXISTS session_context_json jsonb NOT NULL DEFAULT '{}'::jsonb;
