-- Canonical Groot baseline schema.
-- Generated from the current intended local schema during Phase 164.

--
-- PostgreSQL database dump
--


-- Dumped from database version 15.17 (Debian 15.17-1.pgdg13+1)
-- Dumped by pg_dump version 15.17 (Debian 15.17-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: agent_budgets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_budgets (
    agent_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    monthly_token_limit bigint DEFAULT 0 NOT NULL,
    alert_threshold_percent integer DEFAULT 80 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT agent_budgets_alert_threshold_chk CHECK (((alert_threshold_percent >= 1) AND (alert_threshold_percent <= 100))),
    CONSTRAINT agent_budgets_monthly_token_limit_chk CHECK ((monthly_token_limit >= 0))
);


--
-- Name: agent_run_tool_calls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_run_tool_calls (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    agent_run_id uuid NOT NULL,
    agent_session_id uuid NOT NULL,
    tool_name text NOT NULL,
    idempotency_key text NOT NULL,
    status text NOT NULL,
    args_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    external_id text,
    result_json jsonb NOT NULL,
    error_text text,
    integration text,
    model text,
    usage_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    status_code integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT agent_run_tool_calls_status_check CHECK ((status = ANY (ARRAY['succeeded'::text, 'failed'::text])))
);


--
-- Name: agent_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_runs (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    input_event_id uuid NOT NULL,
    subscription_id uuid,
    status text NOT NULL,
    steps integer DEFAULT 0 NOT NULL,
    started_at timestamp without time zone DEFAULT now() NOT NULL,
    completed_at timestamp without time zone,
    last_error text,
    created_by_actor_type text,
    created_by_actor_id text,
    created_by_actor_email text,
    agent_id uuid,
    agent_session_id uuid,
    agent_version_id uuid,
    origin_kind text DEFAULT 'subscription'::text NOT NULL,
    test_run_id uuid,
    CONSTRAINT agent_runs_origin_kind_chk CHECK ((origin_kind = ANY (ARRAY['subscription'::text, 'test_run'::text])))
);


--
-- Name: agent_session_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_session_events (
    id uuid NOT NULL,
    agent_session_id uuid NOT NULL,
    event_id uuid NOT NULL,
    linked_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: agent_session_histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_session_histories (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    agent_session_id uuid NOT NULL,
    agent_run_id uuid,
    version integer NOT NULL,
    messages jsonb NOT NULL,
    message_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: agent_session_waits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_session_waits (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    agent_session_id uuid NOT NULL,
    agent_run_id uuid NOT NULL,
    subscription_id uuid NOT NULL,
    tool_name text NOT NULL,
    status text NOT NULL,
    summary text,
    context_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    timeout_at timestamp without time zone,
    resumed_at timestamp without time zone,
    resume_event_id uuid,
    cancellation_note text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT agent_session_waits_status_check CHECK ((status = ANY (ARRAY['active'::text, 'resumed'::text, 'expired'::text, 'cancelled'::text])))
);


--
-- Name: agent_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_sessions (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    agent_id uuid NOT NULL,
    session_key text NOT NULL,
    status text DEFAULT 'running'::text NOT NULL,
    summary text,
    last_event_id uuid,
    last_activity_at timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by_actor_type text,
    created_by_actor_id text,
    created_by_actor_email text,
    updated_by_actor_type text,
    updated_by_actor_id text,
    updated_by_actor_email text,
    CONSTRAINT agent_sessions_status_check CHECK ((status = ANY (ARRAY['running'::text, 'waiting'::text, 'closed'::text, 'failed'::text])))
);


--
-- Name: agent_steps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_steps (
    id uuid NOT NULL,
    agent_run_id uuid NOT NULL,
    step_num integer NOT NULL,
    kind text NOT NULL,
    tool_name text,
    tool_args jsonb,
    tool_result jsonb,
    llm_integration text,
    llm_model text,
    usage jsonb,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: agent_test_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_test_runs (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    agent_id uuid NOT NULL,
    mode text NOT NULL,
    status text NOT NULL,
    input_event_id uuid NOT NULL,
    agent_run_id uuid,
    agent_session_id uuid,
    session_key text NOT NULL,
    last_error text,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_actor_type text,
    created_by_actor_id text,
    created_by_actor_email text,
    updated_by_actor_type text,
    updated_by_actor_id text,
    updated_by_actor_email text,
    CONSTRAINT agent_test_runs_mode_chk CHECK ((mode = ANY (ARRAY['live'::text, 'dry_run'::text]))),
    CONSTRAINT agent_test_runs_status_chk CHECK ((status = ANY (ARRAY['queued'::text, 'running'::text, 'succeeded'::text, 'failed'::text])))
);


--
-- Name: agent_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_versions (
    id uuid NOT NULL,
    agent_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    version_number integer NOT NULL,
    name text NOT NULL,
    instructions text NOT NULL,
    integration text,
    model text,
    allowed_tools jsonb DEFAULT '[]'::jsonb NOT NULL,
    tool_bindings jsonb DEFAULT '{}'::jsonb NOT NULL,
    memory_enabled boolean DEFAULT false NOT NULL,
    session_auto_create boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by_actor_type text,
    created_by_actor_id text,
    created_by_actor_email text
);


--
-- Name: agents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agents (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    name text NOT NULL,
    instructions text NOT NULL,
    integration text,
    model text,
    allowed_tools jsonb DEFAULT '[]'::jsonb NOT NULL,
    tool_bindings jsonb DEFAULT '{}'::jsonb NOT NULL,
    memory_enabled boolean DEFAULT true NOT NULL,
    session_auto_create boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by_actor_type text,
    created_by_actor_id text,
    created_by_actor_email text,
    updated_by_actor_type text,
    updated_by_actor_id text,
    updated_by_actor_email text,
    status text DEFAULT 'active'::text NOT NULL,
    CONSTRAINT agents_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'active'::text])))
);


--
-- Name: analytics_rollup_agent_usage_daily; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.analytics_rollup_agent_usage_daily (
    tenant_id uuid NOT NULL,
    day date NOT NULL,
    agent_id uuid NOT NULL,
    model text NOT NULL,
    origin_kind text NOT NULL,
    prompt_tokens bigint NOT NULL,
    completion_tokens bigint NOT NULL,
    total_tokens bigint NOT NULL,
    run_count bigint NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: analytics_rollup_deliveries_daily; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.analytics_rollup_deliveries_daily (
    tenant_id uuid NOT NULL,
    day date NOT NULL,
    status text NOT NULL,
    count bigint NOT NULL,
    median_latency_ms double precision NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: analytics_rollup_events_daily; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.analytics_rollup_events_daily (
    tenant_id uuid NOT NULL,
    day date NOT NULL,
    integration_name text NOT NULL,
    event_type text NOT NULL,
    count bigint NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: api_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_keys (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    name text NOT NULL,
    key_prefix text NOT NULL,
    key_hash text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    revoked_at timestamp without time zone,
    last_used_at timestamp without time zone
);


--
-- Name: audit_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_events (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    actor_type text,
    actor_id text,
    actor_email text,
    action text NOT NULL,
    resource_type text NOT NULL,
    resource_id uuid,
    request_id text,
    ip text,
    user_agent text,
    metadata jsonb,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    user_id uuid,
    membership_id uuid,
    principal_kind text
);


--
-- Name: connected_apps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connected_apps (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    name text NOT NULL,
    destination_url text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: connection_secret_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connection_secret_values (
    id uuid NOT NULL,
    connection_id uuid NOT NULL,
    field_name text NOT NULL,
    backend text NOT NULL,
    ciphertext bytea NOT NULL,
    nonce bytea NOT NULL,
    key_version integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    rotated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: connector_instances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connector_instances (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    connector_name text NOT NULL,
    status text DEFAULT 'enabled'::text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    config_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    scope text DEFAULT 'tenant'::text NOT NULL,
    owner_tenant_id uuid,
    created_by_actor_type text,
    created_by_actor_id text,
    created_by_actor_email text,
    updated_by_actor_type text,
    updated_by_actor_id text,
    updated_by_actor_email text,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    label text NOT NULL,
    secret_refs_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    status_reason text,
    setup_diagnostics_json jsonb DEFAULT '[]'::jsonb NOT NULL,
    setup_outputs_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    last_setup_action text,
    last_setup_at timestamp without time zone,
    CONSTRAINT connector_instances_owner_check CHECK ((((scope = 'tenant'::text) AND (owner_tenant_id IS NOT NULL)) OR ((scope = 'global'::text) AND (owner_tenant_id IS NULL)))),
    CONSTRAINT connector_instances_scope_check CHECK ((scope = ANY (ARRAY['tenant'::text, 'global'::text])))
);


--
-- Name: delivery_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delivery_attempts (
    id uuid NOT NULL,
    delivery_job_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    attempt integer NOT NULL,
    started_at timestamp with time zone NOT NULL,
    completed_at timestamp with time zone,
    status text NOT NULL,
    error_summary text,
    status_code integer,
    external_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: delivery_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delivery_jobs (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    subscription_id uuid NOT NULL,
    event_id uuid NOT NULL,
    status text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    last_error text,
    completed_at timestamp without time zone,
    external_id text,
    last_status_code integer,
    is_replay boolean DEFAULT false NOT NULL,
    replay_of_event_id uuid,
    result_event_id uuid,
    trace_id text,
    traceparent text,
    tracestate text
);


--
-- Name: event_schemas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_schemas (
    id uuid NOT NULL,
    event_type text NOT NULL,
    source text NOT NULL,
    source_kind text NOT NULL,
    schema_json jsonb NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by_actor_type text,
    created_by_actor_id text,
    created_by_actor_email text,
    updated_by_actor_type text,
    updated_by_actor_id text,
    updated_by_actor_email text
);


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    event_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    type text NOT NULL,
    source text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    payload jsonb NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    chain_depth integer DEFAULT 0 NOT NULL,
    source_connection_id uuid,
    source_connection_name text,
    source_external_account_id text,
    source_json jsonb DEFAULT '{"kind": "external"}'::jsonb NOT NULL,
    origin_integration text,
    origin_connection_id uuid,
    origin_connection_name text,
    origin_external_account_id text
);


--
-- Name: function_destinations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.function_destinations (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    name text NOT NULL,
    url text NOT NULL,
    secret text NOT NULL,
    timeout_seconds integer DEFAULT 10 NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: inbound_routes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inbound_routes (
    id uuid NOT NULL,
    connector_name text NOT NULL,
    route_key text NOT NULL,
    tenant_id uuid NOT NULL,
    connector_instance_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    status text DEFAULT 'enabled'::text NOT NULL,
    metadata_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT inbound_routes_status_check CHECK ((status = ANY (ARRAY['enabled'::text, 'disabled'::text])))
);


--
-- Name: password_credentials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_credentials (
    user_id uuid NOT NULL,
    password_hash text NOT NULL,
    password_updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_reset_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_hash text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    consumed_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: resend_routes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resend_routes (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    token text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    agent_version_id uuid,
    kind text NOT NULL,
    status text NOT NULL,
    match_json jsonb NOT NULL,
    action_json jsonb NOT NULL,
    emit_success_event boolean DEFAULT false NOT NULL,
    emit_failure_event boolean DEFAULT false NOT NULL,
    created_by_kind text,
    parent_event_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    match_event_type text NOT NULL,
    trigger_type text DEFAULT 'event'::text NOT NULL,
    trigger_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    destination_type text DEFAULT 'webhook'::text NOT NULL,
    function_destination_id uuid,
    connector_instance_id uuid,
    operation text,
    operation_params jsonb DEFAULT '{}'::jsonb NOT NULL,
    filter_json jsonb,
    created_by_actor_type text,
    created_by_actor_id text,
    created_by_actor_email text,
    updated_by_actor_type text,
    updated_by_actor_id text,
    updated_by_actor_email text,
    agent_id uuid,
    session_key_template text,
    session_create_if_missing boolean DEFAULT true NOT NULL,
    workflow_id uuid,
    workflow_version_id uuid,
    workflow_node_id text,
    managed_by_workflow boolean DEFAULT false NOT NULL,
    workflow_artifact_status text
);


--
-- Name: system_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_settings (
    key text NOT NULL,
    value text NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: tenant_budgets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenant_budgets (
    tenant_id uuid NOT NULL,
    monthly_token_limit bigint NOT NULL,
    alert_threshold_percent integer NOT NULL,
    notifications_enabled boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    monthly_spend_limit_usd double precision DEFAULT 0 NOT NULL,
    CONSTRAINT tenant_budgets_alert_threshold_chk CHECK (((alert_threshold_percent >= 1) AND (alert_threshold_percent <= 100))),
    CONSTRAINT tenant_budgets_monthly_spend_limit_usd_chk CHECK ((monthly_spend_limit_usd >= (0)::double precision))
);


--
-- Name: tenant_invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenant_invitations (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    email text NOT NULL,
    role text NOT NULL,
    token_hash text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    accepted_by_user_id uuid,
    created_by_user_id uuid,
    accepted_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT tenant_invitations_role_check CHECK ((role = ANY (ARRAY['owner'::text, 'admin'::text, 'member'::text]))),
    CONSTRAINT tenant_invitations_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'accepted'::text, 'revoked'::text, 'expired'::text])))
);


--
-- Name: tenant_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenant_memberships (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    joined_at timestamp without time zone DEFAULT now() NOT NULL,
    invited_by_user_id uuid,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT tenant_memberships_role_check CHECK ((role = ANY (ARRAY['owner'::text, 'admin'::text, 'member'::text]))),
    CONSTRAINT tenant_memberships_status_check CHECK ((status = ANY (ARRAY['active'::text, 'suspended'::text])))
);


--
-- Name: tenant_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenant_settings (
    tenant_id uuid NOT NULL,
    timezone text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: tenants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenants (
    id uuid NOT NULL,
    name text NOT NULL,
    api_key_hash text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_identities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_identities (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    provider_type text NOT NULL,
    issuer text,
    external_subject text NOT NULL,
    email text DEFAULT ''::text NOT NULL,
    display_name text DEFAULT ''::text NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    active_tenant_id uuid NOT NULL,
    token_hash text NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    last_seen_at timestamp without time zone DEFAULT now() NOT NULL,
    revoked_at timestamp without time zone
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    email text NOT NULL,
    display_name text DEFAULT ''::text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    last_login_at timestamp without time zone
);


--
-- Name: agent_budgets agent_budgets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_budgets
    ADD CONSTRAINT agent_budgets_pkey PRIMARY KEY (agent_id);


--
-- Name: agent_run_tool_calls agent_run_tool_calls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_run_tool_calls
    ADD CONSTRAINT agent_run_tool_calls_pkey PRIMARY KEY (id);


--
-- Name: agent_runs agent_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT agent_runs_pkey PRIMARY KEY (id);


--
-- Name: agent_session_events agent_session_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_session_events
    ADD CONSTRAINT agent_session_events_pkey PRIMARY KEY (id);


--
-- Name: agent_session_histories agent_session_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_session_histories
    ADD CONSTRAINT agent_session_histories_pkey PRIMARY KEY (id);


--
-- Name: agent_session_waits agent_session_waits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_session_waits
    ADD CONSTRAINT agent_session_waits_pkey PRIMARY KEY (id);


--
-- Name: agent_sessions agent_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_sessions
    ADD CONSTRAINT agent_sessions_pkey PRIMARY KEY (id);


--
-- Name: agent_steps agent_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_steps
    ADD CONSTRAINT agent_steps_pkey PRIMARY KEY (id);


--
-- Name: agent_test_runs agent_test_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_test_runs
    ADD CONSTRAINT agent_test_runs_pkey PRIMARY KEY (id);


--
-- Name: agent_versions agent_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_versions
    ADD CONSTRAINT agent_versions_pkey PRIMARY KEY (id);


--
-- Name: agents agents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_pkey PRIMARY KEY (id);


--
-- Name: analytics_rollup_agent_usage_daily analytics_rollup_agent_usage_daily_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analytics_rollup_agent_usage_daily
    ADD CONSTRAINT analytics_rollup_agent_usage_daily_pkey PRIMARY KEY (tenant_id, day, agent_id, model, origin_kind);


--
-- Name: analytics_rollup_deliveries_daily analytics_rollup_deliveries_daily_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analytics_rollup_deliveries_daily
    ADD CONSTRAINT analytics_rollup_deliveries_daily_pkey PRIMARY KEY (tenant_id, day, status);


--
-- Name: analytics_rollup_events_daily analytics_rollup_events_daily_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analytics_rollup_events_daily
    ADD CONSTRAINT analytics_rollup_events_daily_pkey PRIMARY KEY (tenant_id, day, integration_name, event_type);


--
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- Name: audit_events audit_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT audit_events_pkey PRIMARY KEY (id);


--
-- Name: connected_apps connected_apps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connected_apps
    ADD CONSTRAINT connected_apps_pkey PRIMARY KEY (id);


--
-- Name: connection_secret_values connection_secret_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connection_secret_values
    ADD CONSTRAINT connection_secret_values_pkey PRIMARY KEY (id);


--
-- Name: connector_instances connector_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connector_instances
    ADD CONSTRAINT connector_instances_pkey PRIMARY KEY (id);


--
-- Name: delivery_attempts delivery_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_attempts
    ADD CONSTRAINT delivery_attempts_pkey PRIMARY KEY (id);


--
-- Name: delivery_jobs delivery_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_jobs
    ADD CONSTRAINT delivery_jobs_pkey PRIMARY KEY (id);


--
-- Name: event_schemas event_schemas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_schemas
    ADD CONSTRAINT event_schemas_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (event_id);


--
-- Name: function_destinations function_destinations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.function_destinations
    ADD CONSTRAINT function_destinations_pkey PRIMARY KEY (id);


--
-- Name: inbound_routes inbound_routes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inbound_routes
    ADD CONSTRAINT inbound_routes_pkey PRIMARY KEY (id);


--
-- Name: password_credentials password_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_credentials
    ADD CONSTRAINT password_credentials_pkey PRIMARY KEY (user_id);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_token_hash_key UNIQUE (token_hash);


--
-- Name: resend_routes resend_routes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resend_routes
    ADD CONSTRAINT resend_routes_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (key);


--
-- Name: tenant_budgets tenant_budgets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_budgets
    ADD CONSTRAINT tenant_budgets_pkey PRIMARY KEY (tenant_id);


--
-- Name: tenant_invitations tenant_invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_invitations
    ADD CONSTRAINT tenant_invitations_pkey PRIMARY KEY (id);


--
-- Name: tenant_invitations tenant_invitations_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_invitations
    ADD CONSTRAINT tenant_invitations_token_hash_key UNIQUE (token_hash);


--
-- Name: tenant_memberships tenant_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_memberships
    ADD CONSTRAINT tenant_memberships_pkey PRIMARY KEY (id);


--
-- Name: tenant_memberships tenant_memberships_tenant_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_memberships
    ADD CONSTRAINT tenant_memberships_tenant_id_user_id_key UNIQUE (tenant_id, user_id);


--
-- Name: tenant_settings tenant_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_settings
    ADD CONSTRAINT tenant_settings_pkey PRIMARY KEY (tenant_id);


--
-- Name: tenants tenants_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_name_key UNIQUE (name);


--
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);


--
-- Name: user_identities user_identities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_identities
    ADD CONSTRAINT user_identities_pkey PRIMARY KEY (id);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);


--
-- Name: user_sessions user_sessions_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_token_hash_key UNIQUE (token_hash);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: agent_budgets_tenant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_budgets_tenant_idx ON public.agent_budgets USING btree (tenant_id);


--
-- Name: agent_runs_agent_started_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_runs_agent_started_idx ON public.agent_runs USING btree (tenant_id, agent_id, started_at DESC);


--
-- Name: agent_runs_input_event_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_runs_input_event_idx ON public.agent_runs USING btree (input_event_id);


--
-- Name: agent_runs_origin_kind_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_runs_origin_kind_idx ON public.agent_runs USING btree (tenant_id, origin_kind, started_at DESC);


--
-- Name: agent_runs_session_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_runs_session_idx ON public.agent_runs USING btree (agent_session_id);


--
-- Name: agent_runs_tenant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_runs_tenant_idx ON public.agent_runs USING btree (tenant_id);


--
-- Name: agent_session_events_event_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_session_events_event_idx ON public.agent_session_events USING btree (event_id);


--
-- Name: agent_session_events_session_event_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX agent_session_events_session_event_uq ON public.agent_session_events USING btree (agent_session_id, event_id);


--
-- Name: agent_session_histories_session_version_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX agent_session_histories_session_version_uq ON public.agent_session_histories USING btree (agent_session_id, version);


--
-- Name: agent_session_histories_tenant_session_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_session_histories_tenant_session_created_idx ON public.agent_session_histories USING btree (tenant_id, agent_session_id, created_at DESC);


--
-- Name: agent_sessions_agent_key_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX agent_sessions_agent_key_active_uq ON public.agent_sessions USING btree (agent_id, session_key) WHERE (status <> 'closed');


--
-- Name: agent_sessions_last_activity_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_sessions_last_activity_idx ON public.agent_sessions USING btree (last_activity_at);


--
-- Name: agent_sessions_tenant_agent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_sessions_tenant_agent_idx ON public.agent_sessions USING btree (tenant_id, agent_id);


--
-- Name: agent_steps_run_step_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX agent_steps_run_step_uq ON public.agent_steps USING btree (agent_run_id, step_num);


--
-- Name: agent_test_runs_agent_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_test_runs_agent_created_idx ON public.agent_test_runs USING btree (tenant_id, agent_id, created_at DESC);


--
-- Name: agent_test_runs_event_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_test_runs_event_idx ON public.agent_test_runs USING btree (input_event_id);


--
-- Name: agent_versions_agent_version_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX agent_versions_agent_version_uq ON public.agent_versions USING btree (agent_id, version_number);


--
-- Name: agent_versions_tenant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_versions_tenant_idx ON public.agent_versions USING btree (tenant_id);


--
-- Name: agents_tenant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agents_tenant_idx ON public.agents USING btree (tenant_id);


--
-- Name: agents_tenant_name_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX agents_tenant_name_uq ON public.agents USING btree (tenant_id, name);


--
-- Name: analytics_rollup_agent_usage_daily_tenant_day_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX analytics_rollup_agent_usage_daily_tenant_day_idx ON public.analytics_rollup_agent_usage_daily USING btree (tenant_id, day);


--
-- Name: analytics_rollup_deliveries_daily_tenant_day_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX analytics_rollup_deliveries_daily_tenant_day_idx ON public.analytics_rollup_deliveries_daily USING btree (tenant_id, day);


--
-- Name: analytics_rollup_events_daily_tenant_day_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX analytics_rollup_events_daily_tenant_day_idx ON public.analytics_rollup_events_daily USING btree (tenant_id, day);


--
-- Name: api_keys_prefix_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX api_keys_prefix_uq ON public.api_keys USING btree (key_prefix);


--
-- Name: api_keys_tenant_active_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX api_keys_tenant_active_idx ON public.api_keys USING btree (tenant_id, is_active);


--
-- Name: audit_events_action_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_events_action_idx ON public.audit_events USING btree (action);


--
-- Name: audit_events_tenant_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_events_tenant_created_idx ON public.audit_events USING btree (tenant_id, created_at);


--
-- Name: audit_events_user_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_events_user_created_idx ON public.audit_events USING btree (user_id, created_at);


--
-- Name: connection_secret_values_connection_field_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX connection_secret_values_connection_field_uq ON public.connection_secret_values USING btree (connection_id, field_name);


--
-- Name: connector_instances_owner_label_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX connector_instances_owner_label_uq ON public.connector_instances USING btree (COALESCE(owner_tenant_id, tenant_id), label);


--
-- Name: delivery_jobs_event_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delivery_jobs_event_idx ON public.delivery_jobs USING btree (event_id);


--
-- Name: delivery_jobs_event_subscription_non_replay_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX delivery_jobs_event_subscription_non_replay_uq ON public.delivery_jobs USING btree (event_id, subscription_id) WHERE (is_replay = false);


--
-- Name: delivery_jobs_replay_of_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delivery_jobs_replay_of_idx ON public.delivery_jobs USING btree (replay_of_event_id);


--
-- Name: delivery_jobs_subscription_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delivery_jobs_subscription_idx ON public.delivery_jobs USING btree (subscription_id);


--
-- Name: delivery_jobs_tenant_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delivery_jobs_tenant_status_idx ON public.delivery_jobs USING btree (tenant_id, status);


--
-- Name: event_schemas_event_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_schemas_event_type_idx ON public.event_schemas USING btree (event_type);


--
-- Name: event_schemas_event_type_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX event_schemas_event_type_uq ON public.event_schemas USING btree (event_type);


--
-- Name: event_schemas_source_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_schemas_source_idx ON public.event_schemas USING btree (source);


--
-- Name: events_tenant_origin_connection_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_tenant_origin_connection_id_idx ON public.events USING btree (tenant_id, origin_connection_id);


--
-- Name: events_tenant_source_connection_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_tenant_source_connection_id_idx ON public.events USING btree (tenant_id, source_connection_id);


--
-- Name: events_tenant_source_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_tenant_source_idx ON public.events USING btree (tenant_id, source);


--
-- Name: events_tenant_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_tenant_time_idx ON public.events USING btree (tenant_id, "timestamp" DESC);


--
-- Name: events_tenant_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_tenant_type_idx ON public.events USING btree (tenant_id, type);


--
-- Name: function_destinations_tenant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX function_destinations_tenant_idx ON public.function_destinations USING btree (tenant_id);


--
-- Name: idx_agent_run_tool_calls_run_key_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_agent_run_tool_calls_run_key_unique ON public.agent_run_tool_calls USING btree (agent_run_id, idempotency_key);


--
-- Name: idx_agent_run_tool_calls_session_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_run_tool_calls_session_created ON public.agent_run_tool_calls USING btree (agent_session_id, created_at DESC);


--
-- Name: idx_agent_session_histories_agent_run_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_agent_session_histories_agent_run_unique ON public.agent_session_histories USING btree (agent_run_id) WHERE (agent_run_id IS NOT NULL);


--
-- Name: idx_agent_session_waits_resume_event_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_agent_session_waits_resume_event_unique ON public.agent_session_waits USING btree (resume_event_id) WHERE (resume_event_id IS NOT NULL);


--
-- Name: idx_agent_session_waits_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_session_waits_session ON public.agent_session_waits USING btree (agent_session_id, created_at DESC);


--
-- Name: idx_agent_session_waits_subscription; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_session_waits_subscription ON public.agent_session_waits USING btree (subscription_id);


--
-- Name: idx_delivery_attempts_job_attempt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_delivery_attempts_job_attempt ON public.delivery_attempts USING btree (delivery_job_id, attempt, created_at DESC);


--
-- Name: idx_delivery_attempts_tenant_job_started; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_delivery_attempts_tenant_job_started ON public.delivery_attempts USING btree (tenant_id, delivery_job_id, started_at DESC, created_at DESC);


--
-- Name: idx_password_reset_tokens_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_password_reset_tokens_expires_at ON public.password_reset_tokens USING btree (expires_at);


--
-- Name: idx_password_reset_tokens_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_password_reset_tokens_user_id ON public.password_reset_tokens USING btree (user_id);


--
-- Name: idx_subscriptions_match_json; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_subscriptions_match_json ON public.subscriptions USING gin (match_json);


--
-- Name: idx_subscriptions_tenant_status_event_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_subscriptions_tenant_status_event_created ON public.subscriptions USING btree (tenant_id, status, match_event_type, created_at);


--
-- Name: inbound_routes_connection_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX inbound_routes_connection_uq ON public.inbound_routes USING btree (connector_instance_id);


--
-- Name: inbound_routes_connector_key_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX inbound_routes_connector_key_uq ON public.inbound_routes USING btree (connector_name, route_key);


--
-- Name: inbound_routes_tenant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inbound_routes_tenant_idx ON public.inbound_routes USING btree (tenant_id);


--
-- Name: resend_routes_tenant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX resend_routes_tenant_idx ON public.resend_routes USING btree (tenant_id);


--
-- Name: resend_routes_token_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX resend_routes_token_uq ON public.resend_routes USING btree (token);


--
-- Name: subscriptions_connector_instance_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX subscriptions_connector_instance_idx ON public.subscriptions USING btree (connector_instance_id);


--
-- Name: subscriptions_filter_json_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX subscriptions_filter_json_gin ON public.subscriptions USING gin (filter_json);


--
-- Name: tenant_invitations_email_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tenant_invitations_email_idx ON public.tenant_invitations USING btree (email, status);


--
-- Name: tenant_invitations_tenant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tenant_invitations_tenant_idx ON public.tenant_invitations USING btree (tenant_id, status);


--
-- Name: tenant_memberships_tenant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tenant_memberships_tenant_idx ON public.tenant_memberships USING btree (tenant_id, status);


--
-- Name: tenant_memberships_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tenant_memberships_user_idx ON public.tenant_memberships USING btree (user_id, status);


--
-- Name: user_identities_primary_per_user_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_identities_primary_per_user_uq ON public.user_identities USING btree (user_id) WHERE (is_primary = true);


--
-- Name: user_identities_provider_subject_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_identities_provider_subject_uq ON public.user_identities USING btree (provider_type, COALESCE(issuer, ''::text), external_subject);


--
-- Name: user_sessions_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_sessions_user_idx ON public.user_sessions USING btree (user_id, revoked_at, expires_at);


--
-- Name: agent_budgets agent_budgets_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_budgets
    ADD CONSTRAINT agent_budgets_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agents(id);


--
-- Name: agent_budgets agent_budgets_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_budgets
    ADD CONSTRAINT agent_budgets_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: agent_run_tool_calls agent_run_tool_calls_agent_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_run_tool_calls
    ADD CONSTRAINT agent_run_tool_calls_agent_run_id_fkey FOREIGN KEY (agent_run_id) REFERENCES public.agent_runs(id);


--
-- Name: agent_run_tool_calls agent_run_tool_calls_agent_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_run_tool_calls
    ADD CONSTRAINT agent_run_tool_calls_agent_session_id_fkey FOREIGN KEY (agent_session_id) REFERENCES public.agent_sessions(id);


--
-- Name: agent_run_tool_calls agent_run_tool_calls_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_run_tool_calls
    ADD CONSTRAINT agent_run_tool_calls_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: agent_runs agent_runs_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT agent_runs_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agents(id);


--
-- Name: agent_runs agent_runs_agent_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT agent_runs_agent_session_id_fkey FOREIGN KEY (agent_session_id) REFERENCES public.agent_sessions(id);


--
-- Name: agent_runs agent_runs_agent_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT agent_runs_agent_version_id_fkey FOREIGN KEY (agent_version_id) REFERENCES public.agent_versions(id);


--
-- Name: agent_runs agent_runs_input_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT agent_runs_input_event_id_fkey FOREIGN KEY (input_event_id) REFERENCES public.events(event_id);


--
-- Name: agent_runs agent_runs_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT agent_runs_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: agent_runs agent_runs_test_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_runs
    ADD CONSTRAINT agent_runs_test_run_id_fkey FOREIGN KEY (test_run_id) REFERENCES public.agent_test_runs(id);


--
-- Name: agent_session_events agent_session_events_agent_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_session_events
    ADD CONSTRAINT agent_session_events_agent_session_id_fkey FOREIGN KEY (agent_session_id) REFERENCES public.agent_sessions(id);


--
-- Name: agent_session_events agent_session_events_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_session_events
    ADD CONSTRAINT agent_session_events_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(event_id);


--
-- Name: agent_session_histories agent_session_histories_agent_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_session_histories
    ADD CONSTRAINT agent_session_histories_agent_run_id_fkey FOREIGN KEY (agent_run_id) REFERENCES public.agent_runs(id);


--
-- Name: agent_session_histories agent_session_histories_agent_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_session_histories
    ADD CONSTRAINT agent_session_histories_agent_session_id_fkey FOREIGN KEY (agent_session_id) REFERENCES public.agent_sessions(id);


--
-- Name: agent_session_histories agent_session_histories_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_session_histories
    ADD CONSTRAINT agent_session_histories_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: agent_session_waits agent_session_waits_agent_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_session_waits
    ADD CONSTRAINT agent_session_waits_agent_run_id_fkey FOREIGN KEY (agent_run_id) REFERENCES public.agent_runs(id);


--
-- Name: agent_session_waits agent_session_waits_agent_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_session_waits
    ADD CONSTRAINT agent_session_waits_agent_session_id_fkey FOREIGN KEY (agent_session_id) REFERENCES public.agent_sessions(id);


--
-- Name: agent_session_waits agent_session_waits_resume_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_session_waits
    ADD CONSTRAINT agent_session_waits_resume_event_id_fkey FOREIGN KEY (resume_event_id) REFERENCES public.events(event_id);


--
-- Name: agent_session_waits agent_session_waits_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_session_waits
    ADD CONSTRAINT agent_session_waits_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id);


--
-- Name: agent_session_waits agent_session_waits_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_session_waits
    ADD CONSTRAINT agent_session_waits_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: agent_sessions agent_sessions_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_sessions
    ADD CONSTRAINT agent_sessions_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agents(id);


--
-- Name: agent_sessions agent_sessions_last_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_sessions
    ADD CONSTRAINT agent_sessions_last_event_id_fkey FOREIGN KEY (last_event_id) REFERENCES public.events(event_id);


--
-- Name: agent_sessions agent_sessions_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_sessions
    ADD CONSTRAINT agent_sessions_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: agent_steps agent_steps_agent_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_steps
    ADD CONSTRAINT agent_steps_agent_run_id_fkey FOREIGN KEY (agent_run_id) REFERENCES public.agent_runs(id);


--
-- Name: agent_test_runs agent_test_runs_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_test_runs
    ADD CONSTRAINT agent_test_runs_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agents(id);


--
-- Name: agent_test_runs agent_test_runs_agent_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_test_runs
    ADD CONSTRAINT agent_test_runs_agent_run_id_fkey FOREIGN KEY (agent_run_id) REFERENCES public.agent_runs(id);


--
-- Name: agent_test_runs agent_test_runs_agent_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_test_runs
    ADD CONSTRAINT agent_test_runs_agent_session_id_fkey FOREIGN KEY (agent_session_id) REFERENCES public.agent_sessions(id);


--
-- Name: agent_test_runs agent_test_runs_input_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_test_runs
    ADD CONSTRAINT agent_test_runs_input_event_id_fkey FOREIGN KEY (input_event_id) REFERENCES public.events(event_id);


--
-- Name: agent_test_runs agent_test_runs_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_test_runs
    ADD CONSTRAINT agent_test_runs_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: agent_versions agent_versions_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_versions
    ADD CONSTRAINT agent_versions_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: agent_versions agent_versions_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_versions
    ADD CONSTRAINT agent_versions_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: agents agents_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: analytics_rollup_agent_usage_daily analytics_rollup_agent_usage_daily_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analytics_rollup_agent_usage_daily
    ADD CONSTRAINT analytics_rollup_agent_usage_daily_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: analytics_rollup_agent_usage_daily analytics_rollup_agent_usage_daily_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analytics_rollup_agent_usage_daily
    ADD CONSTRAINT analytics_rollup_agent_usage_daily_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: analytics_rollup_deliveries_daily analytics_rollup_deliveries_daily_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analytics_rollup_deliveries_daily
    ADD CONSTRAINT analytics_rollup_deliveries_daily_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: analytics_rollup_events_daily analytics_rollup_events_daily_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analytics_rollup_events_daily
    ADD CONSTRAINT analytics_rollup_events_daily_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: api_keys api_keys_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: audit_events audit_events_membership_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT audit_events_membership_id_fkey FOREIGN KEY (membership_id) REFERENCES public.tenant_memberships(id);


--
-- Name: audit_events audit_events_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT audit_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: audit_events audit_events_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT audit_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: connected_apps connected_apps_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connected_apps
    ADD CONSTRAINT connected_apps_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: connection_secret_values connection_secret_values_connection_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connection_secret_values
    ADD CONSTRAINT connection_secret_values_connection_id_fkey FOREIGN KEY (connection_id) REFERENCES public.connector_instances(id) ON DELETE CASCADE;


--
-- Name: connector_instances connector_instances_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connector_instances
    ADD CONSTRAINT connector_instances_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: events events_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: function_destinations function_destinations_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.function_destinations
    ADD CONSTRAINT function_destinations_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: inbound_routes inbound_routes_connector_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inbound_routes
    ADD CONSTRAINT inbound_routes_connector_instance_id_fkey FOREIGN KEY (connector_instance_id) REFERENCES public.connector_instances(id);


--
-- Name: inbound_routes inbound_routes_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inbound_routes
    ADD CONSTRAINT inbound_routes_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: password_credentials password_credentials_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_credentials
    ADD CONSTRAINT password_credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: password_reset_tokens password_reset_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: resend_routes resend_routes_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resend_routes
    ADD CONSTRAINT resend_routes_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: subscriptions subscriptions_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agents(id);


--
-- Name: subscriptions subscriptions_agent_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_agent_version_id_fkey FOREIGN KEY (agent_version_id) REFERENCES public.agent_versions(id);


--
-- Name: subscriptions subscriptions_connector_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_connector_instance_id_fkey FOREIGN KEY (connector_instance_id) REFERENCES public.connector_instances(id);


--
-- Name: subscriptions subscriptions_function_destination_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_function_destination_id_fkey FOREIGN KEY (function_destination_id) REFERENCES public.function_destinations(id);


--
-- Name: subscriptions subscriptions_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: tenant_budgets tenant_budgets_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_budgets
    ADD CONSTRAINT tenant_budgets_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: tenant_invitations tenant_invitations_accepted_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_invitations
    ADD CONSTRAINT tenant_invitations_accepted_by_user_id_fkey FOREIGN KEY (accepted_by_user_id) REFERENCES public.users(id);


--
-- Name: tenant_invitations tenant_invitations_created_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_invitations
    ADD CONSTRAINT tenant_invitations_created_by_user_id_fkey FOREIGN KEY (created_by_user_id) REFERENCES public.users(id);


--
-- Name: tenant_invitations tenant_invitations_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_invitations
    ADD CONSTRAINT tenant_invitations_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: tenant_memberships tenant_memberships_invited_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_memberships
    ADD CONSTRAINT tenant_memberships_invited_by_user_id_fkey FOREIGN KEY (invited_by_user_id) REFERENCES public.users(id);


--
-- Name: tenant_memberships tenant_memberships_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_memberships
    ADD CONSTRAINT tenant_memberships_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: tenant_memberships tenant_memberships_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_memberships
    ADD CONSTRAINT tenant_memberships_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: tenant_settings tenant_settings_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_settings
    ADD CONSTRAINT tenant_settings_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;


--
-- Name: user_identities user_identities_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_identities
    ADD CONSTRAINT user_identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_sessions user_sessions_active_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_active_tenant_id_fkey FOREIGN KEY (active_tenant_id) REFERENCES public.tenants(id);


--
-- Name: user_sessions user_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: connection_stream_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connection_stream_subscriptions (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    connection_id uuid NOT NULL,
    integration_name text NOT NULL,
    status text NOT NULL,
    lease_owner text,
    lease_expires_at timestamp with time zone,
    checkpoint_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    setup_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    last_error text,
    last_event_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

--
-- Name: connection_oauth_bootstraps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connection_oauth_bootstraps (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    integration_name text NOT NULL,
    status text NOT NULL,
    state_token text NOT NULL,
    config_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    redirect_path text,
    provider_context_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    result_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    error_text text,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: connection_stream_subscriptions connection_stream_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connection_stream_subscriptions
    ADD CONSTRAINT connection_stream_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: connection_stream_subscriptions_active_lease_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX connection_stream_subscriptions_active_lease_idx ON public.connection_stream_subscriptions USING btree (status, lease_expires_at, updated_at);


--
-- Name: connection_stream_subscriptions_connection_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX connection_stream_subscriptions_connection_uq ON public.connection_stream_subscriptions USING btree (connection_id, integration_name);


--
-- Name: connection_stream_subscriptions connection_stream_subscriptions_connection_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connection_stream_subscriptions
    ADD CONSTRAINT connection_stream_subscriptions_connection_id_fkey FOREIGN KEY (connection_id) REFERENCES public.connector_instances(id) ON DELETE CASCADE;


--
-- Name: connection_stream_subscriptions connection_stream_subscriptions_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connection_stream_subscriptions
    ADD CONSTRAINT connection_stream_subscriptions_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- PostgreSQL database dump complete
--
