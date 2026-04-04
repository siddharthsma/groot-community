# Upgrading Groot Community

This Community bundle is intended to be mirrored into a small public deploy
repo later. In this source repo, the same bundle is kept as the canonical
source of truth.

## Upgrade flow

1. Back up your Postgres data.
2. Update the Community image references in `.env` to the new release tags.
3. Pull or build the new images.
4. Restart the stack.
5. Apply the SQL migrations.
6. Verify the stack is healthy.

## Repo-local validation flow

If you are validating the Community bundle directly from this private source
repo, you can rebuild the local images first:

```sh
./scripts/build-community-images.sh
cd deploy/docker-compose/community
./groot restart
./groot migrate
```

## Public mirror flow

When this bundle is mirrored into a public Community deploy repo, the same
operator flow should apply, but the image names in `.env` should point to
published registry tags instead of local image names.

## Post-upgrade checks

After upgrading:

- run `./groot status`
- review `./groot logs`
- open the API and UI
- verify the expected edition and tenancy mode in Settings or `/system/edition`
