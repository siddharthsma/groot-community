DROP INDEX IF EXISTS public.agent_sessions_agent_key_uq;

CREATE UNIQUE INDEX IF NOT EXISTS agent_sessions_agent_key_active_uq
ON public.agent_sessions (agent_id, session_key)
WHERE status <> 'closed';
