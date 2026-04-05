package main

import (
	"context"
	"fmt"

	sdkintegration "groot/sdk/integration"
)

const integrationName = "__INTEGRATION_NAME__"

type __STRUCT_NAME__ struct{}

var Integration sdkintegration.IntegrationPlugin = &__STRUCT_NAME__{}

func (__STRUCT_NAME__) Manifest() sdkintegration.Manifest {
	return sdkintegration.Manifest{
		Name:                integrationName,
		Summary:             "__DISPLAY_NAME__ integration plugin scaffold.",
		Category:            "Developer Tools",
		Availability:        sdkintegration.AvailabilityAvailable,
		SupportsTenantScope: true,
		SupportsGlobalScope: false,
		DocsURL:             "https://grootai.dev/docs/plugins",
		Publisher:           "community",
		Version:             "0.1.0",
		Schema: sdkintegration.ConnectionSchema{
			Fields: []sdkintegration.ConnectionField{
				{
					Name:        "api_key",
					Label:       "API key",
					Description: "Sample credential used by the scaffolded plugin.",
					InputKind:   sdkintegration.InputKindPassword,
					Required:    true,
					Secret:      true,
					Placeholder: "paste-a-token",
					Mutable:     true,
				},
			},
		},
		Setup: sdkintegration.SetupSpec{
			SupportsTest: true,
			Actions: []sdkintegration.SetupActionSpec{{
				Name:        "test_connection",
				Label:       "Test connection",
				Description: "Validate the sample API key and normalized config.",
				Idempotent:  true,
			}},
		},
		Operations: []sdkintegration.OperationSpec{
			{
				Name:             "ping",
				Description:      "Return a sample success response.",
				Summary:          "Return a sample success response.",
				ParamsSchemaJSON: pingParamsSchema,
				ResultSchemaJSON: pingResultSchema,
			},
		},
	}
}

func (__STRUCT_NAME__) ValidateConnectionConfig(config map[string]any, defaults sdkintegration.ConnectionValidationContext) error {
	return validateConnectionConfig(config)
}

func (__STRUCT_NAME__) ExecuteOperation(ctx context.Context, req sdkintegration.OperationRequest) (sdkintegration.OperationResult, error) {
	return executeOperation(ctx, req)
}

func (__STRUCT_NAME__) ExecuteSetupAction(ctx context.Context, req sdkintegration.SetupActionRequest) (sdkintegration.SetupActionResult, error) {
	if req.Action != "test_connection" {
		return sdkintegration.SetupActionResult{}, fmt.Errorf("unsupported setup action %s", req.Action)
	}
	return executeSetupAction(ctx, req)
}
