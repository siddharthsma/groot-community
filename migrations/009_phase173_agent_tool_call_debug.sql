ALTER TABLE public.agent_run_tool_calls
    ADD COLUMN IF NOT EXISTS args_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS error_text text;
