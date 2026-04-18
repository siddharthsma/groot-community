# Groot Community 0.1.14

## Published Images

- `groot-community-api:0.1.14`
- `groot-community-ui:0.1.14`
- `groot-community-agent-runtime:0.1.14`
- `groot-community-ai-gateway:0.1.14`

## Shipped First-Party Plugins

- `asana.so`
- `clickup.so`
- `elevenlabs.so`
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

- Improve community bundle persistence and self-update flow
- Fix ElevenLabs integration and add live stack skill
- Add integration wait event and plugin updates
- Fix bootstrap tool inventory wiring
- Add agent reasoning controls and skills foundation
- Verify public community install in release pipeline
