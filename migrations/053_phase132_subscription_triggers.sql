ALTER TABLE subscriptions
    ADD COLUMN trigger_type TEXT NOT NULL DEFAULT 'event',
    ADD COLUMN trigger_json JSONB NOT NULL DEFAULT '{}'::jsonb;

UPDATE subscriptions
SET trigger_type = 'event',
    trigger_json = jsonb_build_object(
        'type', 'event',
        'match', COALESCE(match_json, '[]'::jsonb)
    )
WHERE trigger_json = '{}'::jsonb;
