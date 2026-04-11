# Groot Community 0.1.12

## Published Images

- `groot-community-api:0.1.12`
- `groot-community-ui:0.1.12`
- `groot-community-agent-runtime:0.1.12`
- `groot-community-ai-gateway:0.1.12`

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

- Fix pluginloader e2e connection store stub
