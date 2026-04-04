ALTER TABLE tenant_budgets
    ADD COLUMN IF NOT EXISTS monthly_spend_limit_usd DOUBLE PRECISION NOT NULL DEFAULT 0;

ALTER TABLE tenant_budgets
    DROP CONSTRAINT IF EXISTS tenant_budgets_monthly_token_limit_chk;

ALTER TABLE tenant_budgets
    ADD CONSTRAINT tenant_budgets_monthly_spend_limit_usd_chk
        CHECK (monthly_spend_limit_usd >= 0);
