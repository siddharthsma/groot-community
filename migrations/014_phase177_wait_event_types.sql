ALTER TABLE subscriptions
    ADD COLUMN IF NOT EXISTS match_event_types JSONB NULL;
