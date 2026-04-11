# Groot Community 0.1.13

## Published Images

- `groot-community-api:0.1.13`
- `groot-community-ui:0.1.13`
- `groot-community-agent-runtime:0.1.13`
- `groot-community-ai-gateway:0.1.13`

## Shipped First-Party Plugins

- `asana.so`
- `clickup.so`
- `http.so`
- `hubspot.so`
- `notion.so`
- `pipedrive.so`
- `resend.so`
- `salesforce.so`
- `shopify.so`
- `slack.so`
- `stripe.so`
- `trello.so`

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

- Build community API with plugin-compatible cgo
