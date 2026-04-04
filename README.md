# Groot Community Bundle

This directory is the canonical self-hosted Community deployment bundle for
Groot.

It is intended to be mirrored into the public `groot-community` repo, but this
copy in the main repo is the source of truth.

## What it includes

- `docker-compose.yml`
- `.env.example`
- `setup-community.sh`
- `groot`
- `migrations/`
- `UPGRADE.md`

## What it is for

Use this bundle when you want to run Groot Community Edition as a
single-tenant self-hosted stack.

It is not the same as the root development stack used by `make up`.

## Quick Start

```sh
./groot setup
./groot start
./groot migrate
```

Then open:

- API: `http://localhost:8080`
- AI Gateway: `http://localhost:8787`
- Agent runtime: `http://localhost:8090`
- Temporal UI: `http://localhost:8233`

## Operator Commands

```sh
./groot setup
./groot start
./groot stop
./groot restart
./groot status
./groot logs
./groot migrate
```

## Configuration

Copy or generate `.env` from `.env.example`.

The most important settings are:

- image references:
  - `GROOT_API_IMAGE`
  - `AGENT_RUNTIME_IMAGE`
  - `AI_GATEWAY_IMAGE`
- public runtime settings:
  - `GROOT_PUBLIC_BASE_URL`
  - `COMMUNITY_TENANT_NAME`
  - `GROOT_HTTP_PORT`
- optional provider keys:
  - `OPENAI_API_KEY`
  - `ANTHROPIC_API_KEY`
  - `GROQ_API_KEY`
  - `RESEND_API_KEY`
  - `SLACK_SIGNING_SECRET`

`./groot setup` will generate safe defaults for secrets if placeholder values
are still present.

## Repo-local validation

When validating this bundle inside the private source repo, first build the
local release-style images:

```sh
./scripts/build-community-images.sh
cd deploy/docker-compose/community
./groot setup --non-interactive
./groot start
./groot migrate
```

## Notes

- Community Edition is edition-stamped for single-tenant use.
- Changing `.env` does not convert this bundle into Cloud or Internal mode.
- The bundle runs the same normal runtime boundary as the main product:
  Groot API, agent runtime, and AI gateway work together as separate services.

## More

- Upgrade guidance: [UPGRADE.md](/Users/siddharthsameerambegaonkar/Desktop/Code/groot/deploy/docker-compose/community/UPGRADE.md)
- Maintainer release flow: [community-release-process.md](/Users/siddharthsameerambegaonkar/Desktop/Code/groot/docs/community-release-process.md)
