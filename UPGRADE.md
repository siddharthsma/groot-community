# Upgrading Groot Community

Use this guide when upgrading an existing Groot Community installation.

## Upgrade flow

1. Back up your Postgres data.
2. Update the Community image references in `.env` to the new release tags.
3. Pull or build the new images.
4. Restart the stack.
5. Apply the SQL migrations.
6. Verify the stack is healthy.

## If You Are Running From Source Locally

If you are running the Community bundle directly from source instead of
published images, rebuild the local images first:

```sh
./scripts/build-community-images.sh
cd deploy/docker-compose/community
groot restart
groot migrate
```

## Post-upgrade checks

After upgrading:

- run `groot status`
- review `groot logs`
- check the API and Temporal UI
- verify the expected edition and tenancy mode in Settings or `/system/edition`
