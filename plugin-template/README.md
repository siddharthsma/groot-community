# __DISPLAY_NAME__ Groot Plugin

This repository contains a standalone Groot integration plugin scaffold for
`__INTEGRATION_NAME__`.

## Build Into A Community Bundle

Once you have a Groot Community bundle set up locally and `GROOT_HOME` exported,
run:

```bash
groot integration build .
```

Or target a specific bundle explicitly:

```bash
groot integration build . --groot-home /path/to/groot-community
```

The build command compiles this repository into a Go plugin and installs the
resulting `.so` into the target bundle's `integrations/plugins/` directory.
The Community API container runs on Linux, so `groot integration build`
produces a Linux-compatible plugin artifact automatically.

## Next Steps

1. Update the manifest in `provider.go`.
2. Replace the sample config and operation logic in `config.go`, `validate.go`,
   and `operations.go`.
3. Rebuild the plugin with `groot integration build .`.
4. Verify the target bundle sees the plugin:

```bash
groot integration verify
```

5. Restart Groot from the target bundle:

```bash
cd "$GROOT_HOME"
groot restart
```
