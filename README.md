# Groot Community Bundle

This directory is the canonical Community self-hosted bundle in the main Groot
repo.

It is intended to be mirrored later into a small public Community deploy repo,
but this in-repo copy is the source of truth for:

- `docker-compose.yml`
- `.env.example`
- `setup-community.sh`
- `groot`
- `migrations/`
- Community install and upgrade docs

This bundle is edition-stamped for Community deployment. Changing `.env` does
not convert it into Cloud or Internal mode.

## What this bundle expects

The bundle is image-based:

- `GROOT_API_IMAGE`
- `AGENT_RUNTIME_IMAGE`
- `AI_GATEWAY_IMAGE`

In this private source repo, `.env.example` points at local release-style image
names so the bundle can be validated in-place. A public Community mirror should
replace those values with published versioned registry tags for each release.

## Repo-local validation flow

To validate the Community bundle directly from this repo:

```sh
./scripts/build-community-images.sh
cd deploy/docker-compose/community
./groot setup --non-interactive
./groot start
./groot migrate
```

That flow builds local Community images, configures `.env`, starts the stack,
and applies the bundle-local SQL migrations.

## Operator commands

The Community operator interface is:

```sh
./groot setup
./groot start
./groot migrate
./groot status
./groot logs
./groot stop
```

### `./groot setup`

This command:

- checks Docker and Docker Compose
- creates `.env` from `.env.example` if needed
- prompts for the minimum required values
- generates safe defaults for secrets if placeholders are still present

### `./groot start`

Starts the Community stack in detached mode.

### `./groot migrate`

Applies every SQL file in `./migrations/` to the bundle’s Postgres container.

### `./groot status`

Shows container status for the Community stack.

### `./groot logs`

Tails logs for the Community stack or a named service.

### `./groot stop`

Stops and removes the Community stack containers.

## Default endpoints

- API: `http://localhost:8080`
- AI Gateway: `http://localhost:8787`
- Agent runtime: `http://localhost:8090`
- Temporal frontend: `localhost:7233`
- Temporal UI: `http://localhost:8233`

## Notes for public mirroring

When this bundle is mirrored into a public Community deploy repo:

- keep the same helper command UX
- replace local image names with published release image tags
- keep `migrations/` bundled with the release
- keep `.env.example` as the canonical Community env template

In the private source repo, that mirroring is now automated by the
tag-triggered Community release workflow. Maintainer steps live in
[community-release-process.md](/Users/siddharthsameerambegaonkar/Desktop/Code/groot/docs/community-release-process.md).

## Supported runtime boundary

This bundle includes the same normal runtime posture as the main product:

- Groot Go code calls the agent runtime over HTTP
- the agent runtime owns model execution
- the agent runtime uses AI Gateway for model access when gateway mode is enabled
- the runtime uses Groot’s internal tool endpoints for outbound actions and wait tools
