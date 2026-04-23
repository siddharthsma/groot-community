ALTER TABLE public.agent_sessions
    ADD COLUMN active_run_id uuid;

CREATE TABLE public.agent_session_run_queue (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    agent_id uuid NOT NULL,
    agent_session_id uuid NOT NULL,
    session_key text NOT NULL,
    input_event_id uuid NOT NULL,
    subscription_id uuid,
    agent_version_id uuid,
    origin_kind text DEFAULT 'subscription'::text NOT NULL,
    test_run_id uuid,
    delivery_job_id uuid,
    execution_mode text,
    status text NOT NULL,
    sequence bigserial NOT NULL,
    agent_run_id uuid,
    enqueued_at timestamp without time zone DEFAULT now() NOT NULL,
    leased_at timestamp without time zone,
    completed_at timestamp without time zone,
    last_error text,
    CONSTRAINT agent_session_run_queue_origin_kind_chk CHECK ((origin_kind = ANY (ARRAY['subscription'::text, 'test_run'::text]))),
    CONSTRAINT agent_session_run_queue_status_chk CHECK ((status = ANY (ARRAY['queued'::text, 'running'::text, 'done'::text, 'failed'::text])))
);

ALTER TABLE public.agent_session_run_queue
    ADD CONSTRAINT agent_session_run_queue_pkey PRIMARY KEY (id);

CREATE INDEX idx_agent_session_run_queue_session_status_sequence
    ON public.agent_session_run_queue (agent_session_id, status, sequence);

CREATE UNIQUE INDEX idx_agent_session_run_queue_agent_run_unique
    ON public.agent_session_run_queue (agent_run_id)
    WHERE agent_run_id IS NOT NULL;

CREATE INDEX idx_agent_sessions_active_run_id
    ON public.agent_sessions (active_run_id)
    WHERE active_run_id IS NOT NULL;
