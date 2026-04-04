# Groot Community

![Groot Community banner](./groot-banner-1.png)

Groot Community is the self-hosted, single-tenant edition of Groot.

Groot is an event hub for event-driven automation. It gives you one place to:

- receive events from external systems
- normalize and store those events
- route them to subscriptions and agents
- track deliveries and retries

This bundle is the packaged Community install for running Groot on your own
machine or server with Docker Compose.

## Will This Work On A Fresh Machine?

Yes, if you are using an official Community release bundle and you have Docker
and Docker Compose installed.

On a fresh machine:

1. `./setup-community.sh` creates `.env`, generates internal secrets, and adds
   this bundle directory to your shell `PATH`
2. `./setup-community.sh` also starts Postgres and applies the bundled
   database migrations
3. `groot start` pulls the remaining images if needed and starts the full stack

The first run may take a few minutes because Docker may need to download the
images.

## What You Get

The Community stack includes:

- Groot API
- PostgreSQL
- Kafka
- Temporal
- AI Gateway
- agent runtime

This bundle also includes:

- `docker-compose.yml`
- `.env.example`
- `groot`
- `migrations/`
- `UPGRADE.md`

## Before You Start

You need:

- Docker
- Docker Compose

Optional but useful:

- an OpenAI, Anthropic, Groq, or Hugging Face credential if you want to use
  agent/model features immediately

## Quick Start

From this directory:

```sh
./setup-community.sh
source ~/.zshrc
groot start
```

If you are using Bash, reload `~/.bashrc` or `~/.bash_profile` instead.

Then open:

- API: `http://localhost:8080`
- Temporal UI: `http://localhost:8233`

If you are also running the full local development stack from the root repo,
change the Community ports in `.env` first so the two stacks do not collide.

## What `setup-community.sh` does

`./setup-community.sh`:

- checks Docker and Docker Compose
- creates `.env` from `.env.example` if needed
- asks for the minimum required settings
- generates safe defaults for internal secrets
- lets you optionally add AI provider credentials
- adds the bundle directory to your shell `PATH`
- starts Postgres and applies the bundled migrations

The guided setup is the normal first step. After it has added the bundle
directory to your `PATH`, you can also run the same flow again as:

```sh
groot setup
```

## Commands

- `groot setup`
  Re-runs the guided setup flow and updates `.env`
- `groot start`
  Starts the Community stack in detached mode
- `groot stop`
  Stops and removes the Community stack containers
- `groot restart`
  Restarts the Community stack
- `groot status`
  Shows container status for the Community stack
- `groot logs`
  Tails logs for the whole stack or one named service
- `groot migrate`
  Re-applies the SQL migrations from the bundled `migrations/` directory

## Why `groot migrate` Is Necessary

The setup flow runs the initial migration automatically because Postgres starts
empty.

Groot does not create or evolve the database schema automatically at runtime.
Instead, the supported setup is to apply the SQL migrations in the bundled
`migrations/` directory.

That means:

- `./setup-community.sh` prepares the database schema on first install
- `groot migrate` is still useful later for upgrades or manual reruns

You should also run `groot migrate` after upgrading to a release that includes
new migrations.

## Configuration

This bundle uses `.env` for deployment-level settings.

The most important ones are:

- image references:
  - `GROOT_API_IMAGE`
  - `AGENT_RUNTIME_IMAGE`
  - `AI_GATEWAY_IMAGE`
- runtime settings:
  - `GROOT_PUBLIC_BASE_URL`
  - `COMMUNITY_TENANT_NAME`
  - `GROOT_HTTP_PORT`
- optional AI provider credentials:
  - `OPENAI_API_KEY`
  - `ANTHROPIC_API_KEY`
  - `GROQ_API_KEY`
  - `HF_TOKEN`

Important distinction:

- deployment-level AI provider credentials belong in `.env`
- connection-specific integration secrets do not belong in the normal install
  section of this README

For example, Slack and Resend connection secrets are configured through Groot’s
normal product configuration flows, not as part of the basic Community install
steps here.

## Notes

- Community Edition is edition-stamped for single-tenant use.
- Changing `.env` does not convert it into Cloud or Internal mode.
- Groot API, agent runtime, and AI Gateway run as separate services in this
  stack.
- The Community bundle currently gives you the Groot backend stack. The
  Next.js UI is not part of this Docker Compose bundle.

## More

- Upgrade guidance: [UPGRADE.md](/Users/siddharthsameerambegaonkar/Desktop/Code/groot/deploy/docker-compose/community/UPGRADE.md)
