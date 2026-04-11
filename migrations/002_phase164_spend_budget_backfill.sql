-- Reconcile pre-baseline local databases that were adopted into the new tracked
-- migration system before the spend-budget schema landed.

ALTER TABLE public.tenant_budgets
    ADD COLUMN IF NOT EXISTS monthly_spend_limit_usd DOUBLE PRECISION NOT NULL DEFAULT 0;

ALTER TABLE public.tenant_budgets
    DROP CONSTRAINT IF EXISTS tenant_budgets_monthly_token_limit_chk;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'tenant_budgets_monthly_spend_limit_usd_chk'
          AND conrelid = 'public.tenant_budgets'::regclass
    ) THEN
        ALTER TABLE public.tenant_budgets
            ADD CONSTRAINT tenant_budgets_monthly_spend_limit_usd_chk
                CHECK (monthly_spend_limit_usd >= 0);
    END IF;
END $$;

ALTER TABLE public.agent_budgets
    ADD COLUMN IF NOT EXISTS monthly_spend_limit_usd DOUBLE PRECISION NOT NULL DEFAULT 0;

ALTER TABLE public.agent_budgets
    DROP CONSTRAINT IF EXISTS agent_budgets_monthly_token_limit_chk;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'agent_budgets_monthly_spend_limit_usd_chk'
          AND conrelid = 'public.agent_budgets'::regclass
    ) THEN
        ALTER TABLE public.agent_budgets
            ADD CONSTRAINT agent_budgets_monthly_spend_limit_usd_chk
                CHECK (monthly_spend_limit_usd >= 0);
    END IF;
END $$;
