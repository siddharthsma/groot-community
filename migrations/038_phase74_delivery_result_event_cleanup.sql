ALTER TABLE delivery_jobs
    DROP COLUMN IF EXISTS workflow_run_id,
    DROP COLUMN IF EXISTS workflow_node_id;

DROP INDEX IF EXISTS delivery_jobs_workflow_run_id_idx;
