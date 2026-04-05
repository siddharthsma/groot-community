# Groot Community 0.1.6

## Published Images

- `groot-community-api:0.1.6`
- `groot-community-ui:0.1.6`
- `groot-community-agent-runtime:0.1.6`
- `groot-community-ai-gateway:0.1.6`

## Shipped First-Party Plugins

- `resend.so`
- `slack.so`

## Install

Use the helper commands in this repo:

```sh
./setup-community.sh
source ~/.zshrc
groot start
```

## Upgrading

```sh
groot update --check
groot update
```

## Changes

- Refactor integrations to first-party plugin model
