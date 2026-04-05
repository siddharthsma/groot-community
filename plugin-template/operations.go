package main

import (
	"context"
	"encoding/json"
	"fmt"

	sdkintegration "groot/sdk/integration"
)

func executeOperation(_ context.Context, req sdkintegration.OperationRequest) (sdkintegration.OperationResult, error) {
	if req.Operation != "ping" {
		return sdkintegration.OperationResult{}, fmt.Errorf("unsupported operation %s", req.Operation)
	}

	var cfg connectionConfig
	if err := sdkintegration.DecodeInto(req.Config, &cfg); err != nil {
		return sdkintegration.OperationResult{}, err
	}

	var params pingParams
	if len(req.Params) > 0 {
		if err := json.Unmarshal(req.Params, &params); err != nil {
			return sdkintegration.OperationResult{}, fmt.Errorf("decode params: %w", err)
		}
	}
	if params.Message == "" {
		params.Message = "pong"
	}

	output, err := json.Marshal(map[string]any{
		"message": params.Message,
		"status":  "ok",
		"config": map[string]any{
			"api_key_present": cfg.APIKey != "",
		},
	})
	if err != nil {
		return sdkintegration.OperationResult{}, fmt.Errorf("encode output: %w", err)
	}

	return sdkintegration.OperationResult{
		StatusCode: 200,
		Output:     output,
	}, nil
}

func executeSetupAction(_ context.Context, req sdkintegration.SetupActionRequest) (sdkintegration.SetupActionResult, error) {
	if req.Action != "test_connection" {
		return sdkintegration.SetupActionResult{}, fmt.Errorf("unsupported setup action %s", req.Action)
	}

	var cfg connectionConfig
	if err := sdkintegration.DecodeInto(req.Config, &cfg); err != nil {
		return sdkintegration.SetupActionResult{}, err
	}

	output, err := json.Marshal(map[string]any{
		"message":        "connection validated",
		"api_key_length": len(cfg.APIKey),
	})
	if err != nil {
		return sdkintegration.SetupActionResult{}, fmt.Errorf("encode setup output: %w", err)
	}

	return sdkintegration.SetupActionResult{
		Status:     "ready",
		OutputJSON: output,
	}, nil
}
