package integration

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestValidateSpecRejectsBlankInboundEventType(t *testing.T) {
	spec := validSpec()
	spec.Inbound = &InboundSpec{
		RouteKeyStrategy: "route",
		RouteKeySource:   RouteKeySourceRequest,
		EventTypes:       []string{"example.created.v1", "   "},
	}
	err := ValidateSpec(spec)
	if err == nil || !strings.Contains(err.Error(), "empty inbound event type") {
		t.Fatalf("ValidateSpec() error = %v, want empty inbound event type", err)
	}
}

func TestValidateSpecRejectsDuplicateInboundEventType(t *testing.T) {
	spec := validSpec()
	spec.Inbound = &InboundSpec{
		RouteKeyStrategy: "route",
		RouteKeySource:   RouteKeySourceRequest,
		EventTypes:       []string{"example.created.v1", " example.created.v1 "},
	}
	err := ValidateSpec(spec)
	if err == nil || !strings.Contains(err.Error(), "duplicate inbound event type") {
		t.Fatalf("ValidateSpec() error = %v, want duplicate inbound event type", err)
	}
}

func TestValidateSpecRejectsBlankHostRequirement(t *testing.T) {
	spec := validSpec()
	spec.HostRequirements = []string{"webhook_ingress", " "}
	err := ValidateSpec(spec)
	if err == nil || !strings.Contains(err.Error(), "empty host requirement") {
		t.Fatalf("ValidateSpec() error = %v, want empty host requirement", err)
	}
}

func TestValidateSpecRejectsDuplicateHostRequirement(t *testing.T) {
	spec := validSpec()
	spec.HostRequirements = []string{"webhook_ingress", " webhook_ingress "}
	err := ValidateSpec(spec)
	if err == nil || !strings.Contains(err.Error(), "duplicate host requirement") {
		t.Fatalf("ValidateSpec() error = %v, want duplicate host requirement", err)
	}
}

func TestValidateSpecRejectsInvalidOperationKind(t *testing.T) {
	spec := validSpec()
	spec.Operations = []OperationSpec{{Name: "echo", Kind: "weird"}}
	err := ValidateSpec(spec)
	if err == nil || !strings.Contains(err.Error(), "invalid kind") {
		t.Fatalf("ValidateSpec() error = %v, want invalid kind", err)
	}
}

func TestValidateManifestRejectsInvalidInputKind(t *testing.T) {
	manifest := validManifest()
	manifest.Schema.Fields[0].InputKind = "unsupported"

	err := ValidateManifest(manifest)
	if err == nil || !strings.Contains(err.Error(), "invalid input kind") {
		t.Fatalf("ValidateManifest() error = %v, want invalid input kind", err)
	}
}

func TestValidateManifestRejectsInvalidJSONBlocks(t *testing.T) {
	manifest := validManifest()
	manifest.Schema.Fields[0].DefaultJSON = json.RawMessage(`{`)

	err := ValidateManifest(manifest)
	if err == nil || !strings.Contains(err.Error(), "invalid json") {
		t.Fatalf("ValidateManifest() error = %v, want invalid json", err)
	}
}

func TestValidateManifestRejectsDuplicateSetupActions(t *testing.T) {
	manifest := validManifest()
	manifest.Setup.Actions = []SetupActionSpec{
		{Name: "test_connection"},
		{Name: " test_connection "},
	}

	err := ValidateManifest(manifest)
	if err == nil || !strings.Contains(err.Error(), "duplicate setup action") {
		t.Fatalf("ValidateManifest() error = %v, want duplicate setup action", err)
	}
}

func TestLegacySpecToManifestAppliesCompatibilityDefaults(t *testing.T) {
	manifest := LegacySpecToManifest(validSpec())

	if manifest.DocsURL != "" || manifest.Publisher != "" || manifest.Version != "" {
		t.Fatalf("LegacySpecToManifest() expected empty metadata defaults, got docs=%q publisher=%q version=%q", manifest.DocsURL, manifest.Publisher, manifest.Version)
	}
	if manifest.Schema.Fields[0].Label != "token" {
		t.Fatalf("LegacySpecToManifest() label = %q, want token", manifest.Schema.Fields[0].Label)
	}
	if manifest.Schema.Fields[0].InputKind != InputKindText {
		t.Fatalf("LegacySpecToManifest() input kind = %q, want %q", manifest.Schema.Fields[0].InputKind, InputKindText)
	}
	if !manifest.Schema.Fields[0].Mutable {
		t.Fatalf("LegacySpecToManifest() mutable = false, want true")
	}
	if manifest.Setup.SupportsDraft || manifest.Setup.RequiresProvisioning || manifest.Setup.SupportsTest || len(manifest.Setup.Actions) != 0 {
		t.Fatalf("LegacySpecToManifest() setup defaults were not empty: %+v", manifest.Setup)
	}
	if manifest.Operations[0].Summary != "Echo the input." {
		t.Fatalf("LegacySpecToManifest() summary = %q, want compatibility description", manifest.Operations[0].Summary)
	}
	if manifest.Operations[0].AgentSafe {
		t.Fatalf("LegacySpecToManifest() agent_safe = true, want false")
	}
	if manifest.Inbound == nil || manifest.Inbound.SignatureVerification != "" || manifest.Inbound.SupportsChallenge {
		t.Fatalf("LegacySpecToManifest() inbound defaults not preserved: %+v", manifest.Inbound)
	}
}

func validSpec() IntegrationSpec {
	return IntegrationSpec{
		Name:                "example",
		Summary:             "Example integration.",
		Category:            "Developer Tools",
		Availability:        AvailabilityAvailable,
		SupportsTenantScope: true,
		Config: ConfigSpec{
			Fields: []ConfigField{{Name: "token"}},
		},
		Inbound: &InboundSpec{
			RouteKeyStrategy: "route",
			RouteKeySource:   RouteKeySourceRequest,
			EventTypes:       []string{"example.created.v1"},
		},
		Operations: []OperationSpec{{Name: "echo", Description: "Echo the input."}},
		Schemas: []SchemaSpec{{
			EventType:  "example.created",
			Version:    1,
			SourceKind: "external",
			SchemaJSON: json.RawMessage(`{"type":"object"}`),
		}},
	}
}

func validManifest() Manifest {
	return Manifest{
		Name:                "example",
		Summary:             "Example integration.",
		Category:            "Developer Tools",
		Availability:        AvailabilityAvailable,
		SupportsTenantScope: true,
		Schema: ConnectionSchema{
			Fields: []ConnectionField{{
				Name:      "token",
				Label:     "Token",
				InputKind: InputKindPassword,
				Secret:    true,
				Mutable:   true,
			}},
		},
		Setup: SetupSpec{
			SupportsTest: true,
			Actions: []SetupActionSpec{{
				Name:        "test_connection",
				Label:       "Test connection",
				Description: "Verify credentials.",
			}},
		},
		Inbound: &InboundSpec{
			RouteKeyStrategy:      "route",
			RouteKeySource:        RouteKeySourceRequest,
			SignatureVerification: "hmac_sha256",
			SupportsChallenge:     true,
			EventTypes:            []string{"example.created.v1"},
		},
		Operations: []OperationSpec{{
			Name:             "echo",
			Summary:          "Echo the input.",
			ParamsSchemaJSON: json.RawMessage(`{"type":"object"}`),
			ResultSchemaJSON: json.RawMessage(`{"type":"object"}`),
		}},
		Schemas: []SchemaSpec{{
			EventType:  "example.created",
			Version:    1,
			SourceKind: "external",
			SchemaJSON: json.RawMessage(`{"type":"object"}`),
		}},
	}
}
