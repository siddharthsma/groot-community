package main

import (
	"errors"
	"strings"

	sdkintegration "groot/sdk/integration"
)

func validateConnectionConfig(config map[string]any) error {
	var decoded connectionConfig
	if err := sdkintegration.DecodeInto(config, &decoded); err != nil {
		return err
	}
	if strings.TrimSpace(decoded.APIKey) == "" {
		return errors.New("config.api_key is required")
	}
	decoded.APIKey = strings.TrimSpace(decoded.APIKey)
	return sdkintegration.RewriteConfig(config, decoded)
}
