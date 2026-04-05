# Plugin Development

Groot Community loads integration plugins from `integrations/plugins/`.

The Community bundle is the runtime host for compiled plugin artifacts. Your
plugin source code should live in its own repository.

Official first-party integrations are shipped the same way. Resend and Slack
are the first shipped examples of official external plugins. The bundle declares the
expected official plugin artifacts in `integrations/first_party_plugins.json`,
including release-aligned version, publisher, and sha256 metadata.

## Prerequisites

- a working Groot Community bundle set up with `./setup-community.sh`
- Go 1.23+
- a shell session that has reloaded your profile so `groot` and `GROOT_HOME`
  are available

`setup-community.sh` exports `GROOT_HOME` to the Community bundle root. That is
how `groot integration build` knows where to install plugin artifacts by
default.

## Scaffold A Plugin Repository

Create an empty repository directory and run:

```sh
groot integration init my_crm
```

Or scaffold into a specific path:

```sh
groot integration init my_crm --path /path/to/my-crm-groot-plugin
```

The scaffold includes:

- `go.mod`
- `provider.go`
- `config.go`
- `validate.go`
- `operations.go`
- `schemas.go`
- `README.md`
- `Makefile`
- `.gitignore`

The generated plugin is a simple outbound integration. It is meant to be a
safe starting point that you can replace with real API calls, schemas, and
validation logic.

## Build Into A Community Bundle

From inside the plugin repository:

```sh
groot integration build .
```

This command:

1. resolves the target Community bundle from `--groot-home`, `GROOT_HOME`, or
   the current directory
2. builds a Linux-compatible plugin artifact for the Dockerized Community API
3. verifies the exported `Integration` symbol can be opened
4. copies the resulting `.so` into `$GROOT_HOME/integrations/plugins/`

To target a specific bundle explicitly:

```sh
groot integration build . --groot-home /path/to/groot-community
```

After a successful build, restart Groot:

```sh
groot integration verify
cd "$GROOT_HOME"
groot restart
```

`groot integration verify` runs the actual `groot-api verify-plugins` command
inside the configured Community API image. It checks the required shipped
first-party plugin artifacts using the same Linux/runtime path that startup
uses, including metadata digest and manifest version/publisher checks.

## How Plugins Show Up In Groot

After `groot restart`:

- Groot loads plugin artifacts from `integrations/plugins/`
- the integration appears in the integrations catalog
- the generated connection schema appears in the UI and API
- you can create a connection and use the integration like any other provider

## Advanced Capabilities

The scaffold is intentionally simple, but the plugin SDK supports more advanced
integration behavior:

- setup actions
- inbound route resolution
- inbound event handling
- agent projection
- event schema registration

Use the existing first-party integrations in `plugins/firstparty/*` in the main
Groot source tree as references when you need to add those behaviors. Official
first-party plugins use an `impl/` subdirectory so Groot can import and test
their implementation without importing `package main`, but external plugin
authors do not need that pattern unless their plugin grows large.
