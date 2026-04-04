ALTER TABLE IF EXISTS events
    DROP COLUMN IF EXISTS workflow_run_id,
    DROP COLUMN IF EXISTS workflow_node_id;

ALTER TABLE IF EXISTS agent_runs
    DROP COLUMN IF EXISTS workflow_run_id,
    DROP COLUMN IF EXISTS workflow_node_id;

DROP INDEX IF EXISTS agent_runs_workflow_run_id_idx;
DROP INDEX IF EXISTS events_workflow_run_id_idx;

DROP TABLE IF EXISTS workflow_entry_bindings CASCADE;
DROP TABLE IF EXISTS workflow_run_steps CASCADE;
DROP TABLE IF EXISTS workflow_runs CASCADE;
DROP TABLE IF EXISTS workflow_versions CASCADE;
DROP TABLE IF EXISTS workflows CASCADE;
