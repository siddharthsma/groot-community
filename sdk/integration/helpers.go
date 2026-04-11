package integration

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
)

type ValidationDetail struct {
	Path     string         `json:"path"`
	Expected string         `json:"expected,omitempty"`
	Received string         `json:"received,omitempty"`
	Message  string         `json:"message,omitempty"`
	Example  map[string]any `json:"example,omitempty"`
}

type ValidationError struct {
	Message    string             `json:"message"`
	Details    []ValidationDetail `json:"details,omitempty"`
	SchemaHint string             `json:"schema_hint,omitempty"`
	Retryable  bool               `json:"retryable"`
}

func (e *ValidationError) Error() string {
	if e == nil {
		return ""
	}
	return e.Message
}

func ParseWaitTimeoutHours(args json.RawMessage) (int, error) {
	var payload struct {
		Wait struct {
			TimeoutHours int `json:"timeout_hours"`
		} `json:"wait"`
	}
	if err := json.Unmarshal(args, &payload); err != nil {
		return 0, fmt.Errorf("decode wait settings: %w", err)
	}
	if payload.Wait.TimeoutHours <= 0 {
		return 0, &ValidationError{
			Message: "wait.timeout_hours must be greater than zero",
			Details: []ValidationDetail{
				{
					Path:     "$/wait/timeout_hours",
					Expected: "integer >= 1",
					Received: fmt.Sprintf("%d", payload.Wait.TimeoutHours),
					Message:  "wait.timeout_hours must be greater than zero",
					Example:  map[string]any{"wait": map[string]any{"timeout_hours": 72}},
				},
			},
			SchemaHint: "$/wait/timeout_hours should be a positive integer such as 72.",
			Retryable:  true,
		}
	}
	return payload.Wait.TimeoutHours, nil
}

func DecodeInto(config map[string]any, target any) error {
	body, err := json.Marshal(config)
	if err != nil {
		return fmt.Errorf("marshal config: %w", err)
	}
	if err := json.Unmarshal(body, target); err != nil {
		return fmt.Errorf("decode config: %w", err)
	}
	return nil
}

func RewriteConfig(config map[string]any, value any) error {
	body, err := json.Marshal(value)
	if err != nil {
		return fmt.Errorf("marshal normalized config: %w", err)
	}
	var normalized map[string]any
	if err := json.Unmarshal(body, &normalized); err != nil {
		return fmt.Errorf("decode normalized config: %w", err)
	}
	clear(config)
	for key, value := range normalized {
		config[key] = value
	}
	return nil
}

func CanonicalSpecJSON(spec IntegrationSpec) ([]byte, error) {
	body, err := json.Marshal(spec)
	if err != nil {
		return nil, fmt.Errorf("marshal integration spec: %w", err)
	}
	return body, nil
}

func SpecHash(spec IntegrationSpec) (string, error) {
	body, err := CanonicalSpecJSON(spec)
	if err != nil {
		return "", err
	}
	sum := sha256.Sum256(body)
	return fmt.Sprintf("sha256:%x", sum[:]), nil
}

func CanonicalManifestJSON(manifest Manifest) ([]byte, error) {
	body, err := json.Marshal(manifest)
	if err != nil {
		return nil, fmt.Errorf("marshal integration manifest: %w", err)
	}
	return body, nil
}

func ManifestHash(manifest Manifest) (string, error) {
	body, err := CanonicalManifestJSON(manifest)
	if err != nil {
		return "", err
	}
	sum := sha256.Sum256(body)
	return fmt.Sprintf("sha256:%x", sum[:]), nil
}
