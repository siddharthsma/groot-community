package integration

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"
)

const (
	AvailabilityAvailable  = "available"
	AvailabilityComingSoon = "coming_soon"
)

const (
	InputKindText     = "text"
	InputKindTextarea = "textarea"
	InputKindPassword = "password"
	InputKindSelect   = "select"
	InputKindURL      = "url"
	InputKindEmail    = "email"
	InputKindNumber   = "number"
	InputKindBoolean  = "boolean"
)

const (
	OperationKindDefault = ""
	OperationKindAgent   = "agent"
)

const (
	RouteKeySourceRequest     = "request"
	RouteKeySourceConfigField = "config_field"
	RouteKeySourceGenerated   = "generated"
)

const (
	SetupSystemGroot      = "groot"
	SetupSystemThirdParty = "third_party"
	SetupSystemBoth       = "both"
)

type Manifest struct {
	Name                               string
	Summary                            string
	Category                           string
	Availability                       string
	DocsURL                            string
	Publisher                          string
	Version                            string
	InternalOnly                       bool
	SupportsTenantScope                bool
	SupportsGlobalScope                bool
	AllowGlobalWhenHostGlobalsDisabled bool
	HostRequirements                   []string
	Schema                             ConnectionSchema
	Setup                              SetupSpec
	SetupGuide                         *SetupGuide
	Operations                         []OperationSpec
	Inbound                            *InboundSpec
	Correlation                        *CorrelationSpec
	Schemas                            []SchemaSpec
}

type ConnectionSchema struct {
	Fields []ConnectionField
}

type ConnectionField struct {
	Name        string
	Label       string
	Description string
	InputKind   string
	Required    bool
	Secret      bool
	Placeholder string
	DefaultJSON json.RawMessage
	ExampleJSON json.RawMessage
	Group       string
	Mutable     bool
	HelpText    string
}

type SetupSpec struct {
	SupportsDraft        bool
	RequiresProvisioning bool
	SupportsTest         bool
	Actions              []SetupActionSpec
	Outputs              []SetupOutputSpec
}

type SetupGuide struct {
	Title string
	Steps []SetupStep
}

type SetupStep struct {
	Title       string
	Description string
	System      string
	FieldNames  []string
	LinkText    string
	LinkURL     string
}

type SetupActionSpec struct {
	Name          string
	Label         string
	Description   string
	MutatesRemote bool
	Idempotent    bool
}

type SetupOutputSpec struct {
	Name        string
	Label       string
	Description string
	Copyable    bool
}

type CorrelationSpec struct {
	Fields     []CorrelationFieldHint
	Strategies []CorrelationStrategyHint
	Templates  []SessionKeyTemplateHint
}

type CorrelationFieldHint struct {
	Path        string
	Label       string
	Description string
}

type CorrelationStrategyHint struct {
	Name        string
	Label       string
	Description string
	Paths       []string
	Template    string
}

type SessionKeyTemplateHint struct {
	Name        string
	Label       string
	Description string
	Template    string
}

type IntegrationSpec struct {
	Name                               string
	Summary                            string
	Category                           string
	Availability                       string
	InternalOnly                       bool
	AllowGlobalWhenHostGlobalsDisabled bool
	HostRequirements                   []string
	SupportsTenantScope                bool
	SupportsGlobalScope                bool
	Config                             ConfigSpec
	Setup                              SetupSpec
	Inbound                            *InboundSpec
	Correlation                        *CorrelationSpec
	Operations                         []OperationSpec
	Schemas                            []SchemaSpec
}

type ConfigSpec struct {
	Fields []ConfigField
}

type ConfigField struct {
	Name     string
	Required bool
	Secret   bool
}

type InboundSpec struct {
	RouteKeyStrategy      string
	RouteKeySource        string
	RouteKeyConfigField   string
	SignatureVerification string
	SupportsChallenge     bool
	EventTypes            []string
}

type OperationSpec struct {
	Name             string
	Description      string
	Summary          string
	Kind             string
	ParamsSchemaJSON json.RawMessage
	ResultSchemaJSON json.RawMessage
	AgentSafe        bool
}

type SchemaSpec struct {
	EventType  string
	Version    int
	SourceKind string
	SchemaJSON json.RawMessage
}

type Source struct {
	Kind              string  `json:"kind"`
	Integration       string  `json:"integration,omitempty"`
	ConnectionID      *string `json:"connection_id,omitempty"`
	ConnectionName    string  `json:"connection_name,omitempty"`
	ExternalAccountID string  `json:"external_account_id,omitempty"`
}

type Origin struct {
	Integration       string  `json:"integration,omitempty"`
	ConnectionID      *string `json:"connection_id,omitempty"`
	ConnectionName    string  `json:"connection_name,omitempty"`
	ExternalAccountID string  `json:"external_account_id,omitempty"`
}

type Event struct {
	EventID    string          `json:"event_id"`
	TenantID   string          `json:"tenant_id"`
	Type       string          `json:"type"`
	Source     Source          `json:"source"`
	Origin     *Origin         `json:"origin,omitempty"`
	ChainDepth int             `json:"chain_depth"`
	Timestamp  time.Time       `json:"timestamp"`
	Payload    json.RawMessage `json:"payload"`
}

type SlackRuntimeConfig struct {
	APIBaseURL    string
	SigningSecret string
}

type ResendRuntimeConfig struct {
	APIKey           string
	APIBaseURL       string
	WebhookPublicURL string
	ReceivingDomain  string
	WebhookEvents    []string
}

type NotionRuntimeConfig struct {
	APIBaseURL string
	APIVersion string
}

type StripeRuntimeConfig struct {
	WebhookToleranceSeconds int
}

type RuntimeConfig struct {
	Slack  SlackRuntimeConfig
	Resend ResendRuntimeConfig
	Stripe StripeRuntimeConfig
	Notion NotionRuntimeConfig
}

type ConnectionContext struct {
	ID              string `json:"id"`
	TenantID        string `json:"tenant_id"`
	IntegrationName string `json:"integration_name"`
	Scope           string `json:"scope"`
	Status          string `json:"status"`
}

type OperationRequest struct {
	Operation  string
	Config     map[string]any
	Params     json.RawMessage
	Event      Event
	HTTPClient *http.Client
	Runtime    RuntimeConfig
}

type SetupActionRequest struct {
	Action     string
	Connection ConnectionContext
	Config     map[string]any
	Input      json.RawMessage
	HTTPClient *http.Client
	Runtime    RuntimeConfig
}

type Usage struct {
	PromptTokens     int `json:"prompt_tokens,omitempty"`
	CompletionTokens int `json:"completion_tokens,omitempty"`
	TotalTokens      int `json:"total_tokens,omitempty"`
}

type OperationResult struct {
	ExternalID  string          `json:"external_id,omitempty"`
	StatusCode  int             `json:"status_code,omitempty"`
	Channel     string          `json:"channel,omitempty"`
	Text        string          `json:"text,omitempty"`
	Output      json.RawMessage `json:"output,omitempty"`
	Integration string          `json:"integration,omitempty"`
	Model       string          `json:"model,omitempty"`
	Usage       Usage           `json:"usage,omitempty"`
}

type SetupDiagnostic struct {
	Code      string          `json:"code"`
	Severity  string          `json:"severity"`
	Summary   string          `json:"summary"`
	Field     string          `json:"field,omitempty"`
	Action    string          `json:"action,omitempty"`
	Retryable bool            `json:"retryable"`
	Metadata  json.RawMessage `json:"metadata,omitempty"`
}

type SetupActionResult struct {
	Status       string            `json:"status"`
	StatusReason string            `json:"status_reason,omitempty"`
	Diagnostics  []SetupDiagnostic `json:"diagnostics,omitempty"`
	OutputJSON   json.RawMessage   `json:"output_json,omitempty"`
}

type IntegrationPlugin interface {
	Manifest() Manifest
	ValidateConnectionConfig(map[string]any, ConnectionValidationContext) error
	ExecuteOperation(context.Context, OperationRequest) (OperationResult, error)
}

type SetupActionPlugin interface {
	ExecuteSetupAction(context.Context, SetupActionRequest) (SetupActionResult, error)
}

type Integration interface {
	Spec() IntegrationSpec
	ValidateConfig(config map[string]any) error
	ExecuteOperation(context.Context, OperationRequest) (OperationResult, error)
}

type InboundPlugin interface {
	HandleInbound(context.Context, InboundRequest) (InboundResult, error)
}

type InboundRouteResolver interface {
	ResolveInboundRoute(context.Context, InboundRouteRequest) (InboundRouteResult, error)
}

type AgentProjection struct {
	Kind        string          `json:"kind,omitempty"`
	Text        string          `json:"text,omitempty"`
	Participant map[string]any  `json:"participant,omitempty"`
	ThreadKey   string          `json:"thread_key,omitempty"`
	MessageID   string          `json:"message_id,omitempty"`
	ReplyTo     map[string]any  `json:"reply_to,omitempty"`
	Channel     string          `json:"channel,omitempty"`
	Subject     string          `json:"subject,omitempty"`
	Metadata    json.RawMessage `json:"metadata,omitempty"`
}

type AgentProjector interface {
	ProjectAgentInput(context.Context, Event) (*AgentProjection, error)
}

type InboundHandler interface {
	HandleInbound(context.Context, InboundRequest) (InboundResult, error)
}

type InboundHost interface {
	GetConnectionConfig(context.Context, string, string) (json.RawMessage, error)
}

type ConnectionValidationContext struct {
	DefaultIntegration string
}

type ConnectionConfigDefaults = ConnectionValidationContext

type ConnectionConfigValidator interface {
	ValidateConnectionConfig(config map[string]any, defaults ConnectionConfigDefaults) error
}

type InboundRuntimeConfig struct {
	Slack  SlackRuntimeConfig
	Resend ResendRuntimeConfig
	Stripe StripeRuntimeConfig
	Notion NotionRuntimeConfig
}

type InboundEndpoint struct {
	IntegrationName string
	RouteKey        string
	TenantID        string
	ConnectionID    string
	Metadata        json.RawMessage
	Status          string
}

type InboundRouteRequest struct {
	Method  string
	Headers http.Header
	Query   url.Values
	Body    []byte
	Runtime InboundRuntimeConfig
	Host    InboundHost
}

type InboundHTTPResponse struct {
	StatusCode  int               `json:"status_code,omitempty"`
	ContentType string            `json:"content_type,omitempty"`
	Headers     map[string]string `json:"headers,omitempty"`
	Body        []byte            `json:"body,omitempty"`
}

type InboundRouteResult struct {
	RouteKey string               `json:"route_key,omitempty"`
	Response *InboundHTTPResponse `json:"response,omitempty"`
}

type InboundRequest struct {
	Method   string
	Headers  http.Header
	Query    url.Values
	Body     []byte
	Endpoint InboundEndpoint
	Runtime  InboundRuntimeConfig
	Host     InboundHost
}

type InboundEvent struct {
	Type       string          `json:"type"`
	Source     string          `json:"source"`
	SourceInfo Source          `json:"source_info"`
	Payload    json.RawMessage `json:"payload"`
}

type InboundResult struct {
	Response *InboundHTTPResponse `json:"response,omitempty"`
	Events   []InboundEvent       `json:"events,omitempty"`
}

func ValidateManifest(manifest Manifest) error {
	name := strings.TrimSpace(manifest.Name)
	if name == "" {
		return errors.New("integration name is required")
	}
	if strings.TrimSpace(manifest.Summary) == "" {
		return fmt.Errorf("integration %s summary is required", name)
	}
	if strings.TrimSpace(manifest.Category) == "" {
		return fmt.Errorf("integration %s category is required", name)
	}
	switch strings.TrimSpace(manifest.Availability) {
	case AvailabilityAvailable, AvailabilityComingSoon:
	default:
		return fmt.Errorf("integration %s availability is invalid", name)
	}
	if !manifest.SupportsTenantScope && !manifest.SupportsGlobalScope {
		return fmt.Errorf("integration %s must support at least one scope", name)
	}
	if err := validateConnectionFields(name, manifest.Schema.Fields); err != nil {
		return err
	}
	if err := validateSetupSpec(name, manifest.Setup); err != nil {
		return err
	}
	if err := validateInboundSpec(name, manifest.Inbound); err != nil {
		return err
	}
	if err := validateCorrelationSpec(name, manifest.Correlation); err != nil {
		return err
	}
	if err := validateHostRequirements(name, manifest.HostRequirements); err != nil {
		return err
	}
	if err := validateOperations(name, manifest.Operations); err != nil {
		return err
	}
	if err := validateSchemas(name, manifest.Schemas); err != nil {
		return err
	}
	return nil
}

func ValidateSpec(spec IntegrationSpec) error {
	return ValidateManifest(LegacySpecToManifest(spec))
}

func FullSchemaName(eventType string, version int) string {
	return strings.TrimSpace(eventType) + fmt.Sprintf(".v%d", version)
}

func ValidateConfigFields(integrationName string, fields []ConfigField) error {
	return validateConnectionFields(integrationName, legacyFieldsToConnectionFields(fields))
}

func LegacySpecToManifest(spec IntegrationSpec) Manifest {
	ops := make([]OperationSpec, 0, len(spec.Operations))
	for _, op := range spec.Operations {
		ops = append(ops, OperationSpec{
			Name:             op.Name,
			Description:      op.Description,
			Summary:          firstNonEmpty(op.Summary, op.Description),
			Kind:             op.Kind,
			ParamsSchemaJSON: cloneRawMessage(op.ParamsSchemaJSON),
			ResultSchemaJSON: cloneRawMessage(op.ResultSchemaJSON),
			AgentSafe:        op.AgentSafe,
		})
	}

	manifest := Manifest{
		Name:                               spec.Name,
		Summary:                            spec.Summary,
		Category:                           spec.Category,
		Availability:                       spec.Availability,
		InternalOnly:                       spec.InternalOnly,
		SupportsTenantScope:                spec.SupportsTenantScope,
		SupportsGlobalScope:                spec.SupportsGlobalScope,
		AllowGlobalWhenHostGlobalsDisabled: spec.AllowGlobalWhenHostGlobalsDisabled,
		HostRequirements:                   append([]string(nil), spec.HostRequirements...),
		Schema: ConnectionSchema{
			Fields: legacyFieldsToConnectionFields(spec.Config.Fields),
		},
		Setup:       cloneSetupSpec(spec.Setup),
		Operations:  ops,
		Inbound:     cloneInboundSpec(spec.Inbound),
		Correlation: cloneCorrelationSpec(spec.Correlation),
		Schemas:     cloneSchemas(spec.Schemas),
	}
	return manifest
}

func ManifestToLegacySpec(manifest Manifest) IntegrationSpec {
	ops := make([]OperationSpec, 0, len(manifest.Operations))
	for _, op := range manifest.Operations {
		ops = append(ops, OperationSpec{
			Name:             op.Name,
			Description:      firstNonEmpty(op.Description, op.Summary),
			Summary:          op.Summary,
			Kind:             op.Kind,
			ParamsSchemaJSON: cloneRawMessage(op.ParamsSchemaJSON),
			ResultSchemaJSON: cloneRawMessage(op.ResultSchemaJSON),
			AgentSafe:        op.AgentSafe,
		})
	}

	return IntegrationSpec{
		Name:                               manifest.Name,
		Summary:                            manifest.Summary,
		Category:                           manifest.Category,
		Availability:                       manifest.Availability,
		InternalOnly:                       manifest.InternalOnly,
		AllowGlobalWhenHostGlobalsDisabled: manifest.AllowGlobalWhenHostGlobalsDisabled,
		HostRequirements:                   append([]string(nil), manifest.HostRequirements...),
		SupportsTenantScope:                manifest.SupportsTenantScope,
		SupportsGlobalScope:                manifest.SupportsGlobalScope,
		Config: ConfigSpec{
			Fields: connectionFieldsToLegacyFields(manifest.Schema.Fields),
		},
		Setup:       cloneSetupSpec(manifest.Setup),
		Inbound:     cloneInboundSpec(manifest.Inbound),
		Correlation: cloneCorrelationSpec(manifest.Correlation),
		Operations:  ops,
		Schemas:     cloneSchemas(manifest.Schemas),
	}
}

func validateConnectionFields(integrationName string, fields []ConnectionField) error {
	seen := make(map[string]struct{}, len(fields))
	for _, field := range fields {
		name := strings.TrimSpace(field.Name)
		if name == "" {
			return fmt.Errorf("integration %s has empty config field name", integrationName)
		}
		if _, exists := seen[name]; exists {
			return fmt.Errorf("integration %s has duplicate config field %s", integrationName, name)
		}
		if err := validateInputKind(integrationName, name, field.InputKind); err != nil {
			return err
		}
		if err := validateOptionalJSON(integrationName, "default", name, field.DefaultJSON); err != nil {
			return err
		}
		if err := validateOptionalJSON(integrationName, "example", name, field.ExampleJSON); err != nil {
			return err
		}
		seen[name] = struct{}{}
	}
	return nil
}

func validateSetupSpec(integrationName string, setup SetupSpec) error {
	seen := make(map[string]struct{}, len(setup.Actions))
	for _, action := range setup.Actions {
		name := strings.TrimSpace(action.Name)
		if name == "" {
			return fmt.Errorf("integration %s has empty setup action name", integrationName)
		}
		if _, exists := seen[name]; exists {
			return fmt.Errorf("integration %s has duplicate setup action %s", integrationName, name)
		}
		seen[name] = struct{}{}
	}
	return nil
}

func validateInboundSpec(integrationName string, spec *InboundSpec) error {
	if spec == nil {
		return nil
	}
	if strings.TrimSpace(spec.RouteKeyStrategy) == "" {
		return fmt.Errorf("integration %s inbound route key strategy is required", integrationName)
	}
	switch strings.TrimSpace(spec.RouteKeySource) {
	case RouteKeySourceRequest, RouteKeySourceConfigField, RouteKeySourceGenerated:
	default:
		return fmt.Errorf("integration %s inbound route key source is invalid", integrationName)
	}
	if strings.TrimSpace(spec.RouteKeySource) == RouteKeySourceConfigField && strings.TrimSpace(spec.RouteKeyConfigField) == "" {
		return fmt.Errorf("integration %s inbound route key config field is required", integrationName)
	}
	if len(spec.EventTypes) == 0 {
		return fmt.Errorf("integration %s inbound event types are required", integrationName)
	}
	eventTypes := make(map[string]struct{}, len(spec.EventTypes))
	for _, eventType := range spec.EventTypes {
		trimmed := strings.TrimSpace(eventType)
		if trimmed == "" {
			return fmt.Errorf("integration %s has empty inbound event type", integrationName)
		}
		if _, exists := eventTypes[trimmed]; exists {
			return fmt.Errorf("integration %s has duplicate inbound event type %s", integrationName, trimmed)
		}
		eventTypes[trimmed] = struct{}{}
	}
	return nil
}

func validateCorrelationSpec(integrationName string, spec *CorrelationSpec) error {
	if spec == nil {
		return nil
	}
	strategies := make(map[string]struct{}, len(spec.Strategies))
	for _, field := range spec.Fields {
		if strings.TrimSpace(field.Path) == "" {
			return fmt.Errorf("integration %s has empty correlation field path", integrationName)
		}
	}
	for _, strategy := range spec.Strategies {
		name := strings.TrimSpace(strategy.Name)
		if name == "" {
			return fmt.Errorf("integration %s has empty correlation strategy name", integrationName)
		}
		if _, exists := strategies[name]; exists {
			return fmt.Errorf("integration %s has duplicate correlation strategy %s", integrationName, name)
		}
		if strings.TrimSpace(strategy.Template) == "" {
			return fmt.Errorf("integration %s correlation strategy %s missing template", integrationName, name)
		}
		if len(strategy.Paths) == 0 {
			return fmt.Errorf("integration %s correlation strategy %s missing paths", integrationName, name)
		}
		for _, path := range strategy.Paths {
			if strings.TrimSpace(path) == "" {
				return fmt.Errorf("integration %s correlation strategy %s has empty path", integrationName, name)
			}
		}
		strategies[name] = struct{}{}
	}
	templates := make(map[string]struct{}, len(spec.Templates))
	for _, template := range spec.Templates {
		name := strings.TrimSpace(template.Name)
		if name == "" {
			return fmt.Errorf("integration %s has empty session template name", integrationName)
		}
		if _, exists := templates[name]; exists {
			return fmt.Errorf("integration %s has duplicate session template %s", integrationName, name)
		}
		if strings.TrimSpace(template.Template) == "" {
			return fmt.Errorf("integration %s session template %s missing template", integrationName, name)
		}
		templates[name] = struct{}{}
	}
	return nil
}

func validateHostRequirements(integrationName string, requirements []string) error {
	seen := make(map[string]struct{}, len(requirements))
	for _, requirement := range requirements {
		trimmed := strings.TrimSpace(requirement)
		if trimmed == "" {
			return fmt.Errorf("integration %s has empty host requirement", integrationName)
		}
		if _, exists := seen[trimmed]; exists {
			return fmt.Errorf("integration %s has duplicate host requirement %s", integrationName, trimmed)
		}
		seen[trimmed] = struct{}{}
	}
	return nil
}

func validateOperations(integrationName string, ops []OperationSpec) error {
	seen := make(map[string]struct{}, len(ops))
	for _, op := range ops {
		name := strings.TrimSpace(op.Name)
		if name == "" {
			return fmt.Errorf("integration %s has empty operation name", integrationName)
		}
		switch strings.TrimSpace(op.Kind) {
		case OperationKindDefault, OperationKindAgent:
		default:
			return fmt.Errorf("integration %s operation %s has invalid kind %s", integrationName, name, strings.TrimSpace(op.Kind))
		}
		if err := validateOptionalJSON(integrationName, "params schema", name, op.ParamsSchemaJSON); err != nil {
			return err
		}
		if err := validateOptionalJSON(integrationName, "result schema", name, op.ResultSchemaJSON); err != nil {
			return err
		}
		if _, exists := seen[name]; exists {
			return fmt.Errorf("integration %s has duplicate operation %s", integrationName, name)
		}
		seen[name] = struct{}{}
	}
	return nil
}

func validateSchemas(integrationName string, specs []SchemaSpec) error {
	seen := make(map[string]struct{}, len(specs))
	for _, declared := range specs {
		if strings.TrimSpace(declared.EventType) == "" || declared.Version <= 0 {
			return fmt.Errorf("integration %s has invalid schema declaration", integrationName)
		}
		if strings.TrimSpace(declared.SourceKind) == "" {
			return fmt.Errorf("integration %s schema %s missing source kind", integrationName, declared.EventType)
		}
		if len(declared.SchemaJSON) == 0 || !json.Valid(declared.SchemaJSON) {
			return fmt.Errorf("integration %s schema %s has invalid schema json", integrationName, declared.EventType)
		}
		key := FullSchemaName(declared.EventType, declared.Version)
		if _, exists := seen[key]; exists {
			return fmt.Errorf("integration %s has duplicate schema %s", integrationName, key)
		}
		seen[key] = struct{}{}
	}
	return nil
}

func validateInputKind(integrationName string, fieldName string, inputKind string) error {
	switch strings.TrimSpace(inputKind) {
	case "", InputKindText, InputKindTextarea, InputKindPassword, InputKindSelect, InputKindURL, InputKindEmail, InputKindNumber, InputKindBoolean:
		return nil
	default:
		return fmt.Errorf("integration %s config field %s has invalid input kind %s", integrationName, fieldName, strings.TrimSpace(inputKind))
	}
}

func validateOptionalJSON(integrationName string, fieldType string, fieldName string, value json.RawMessage) error {
	if len(value) == 0 {
		return nil
	}
	if json.Valid(value) {
		return nil
	}
	return fmt.Errorf("integration %s %s %s has invalid json", integrationName, fieldType, fieldName)
}

func legacyFieldsToConnectionFields(fields []ConfigField) []ConnectionField {
	out := make([]ConnectionField, 0, len(fields))
	for _, field := range fields {
		inputKind := InputKindText
		if field.Secret {
			inputKind = InputKindPassword
		}
		out = append(out, ConnectionField{
			Name:      field.Name,
			Label:     field.Name,
			InputKind: inputKind,
			Required:  field.Required,
			Secret:    field.Secret,
			Mutable:   true,
		})
	}
	return out
}

func connectionFieldsToLegacyFields(fields []ConnectionField) []ConfigField {
	out := make([]ConfigField, 0, len(fields))
	for _, field := range fields {
		out = append(out, ConfigField{
			Name:     field.Name,
			Required: field.Required,
			Secret:   field.Secret,
		})
	}
	return out
}

func cloneInboundSpec(spec *InboundSpec) *InboundSpec {
	if spec == nil {
		return nil
	}
	routeKeySource := spec.RouteKeySource
	if strings.TrimSpace(routeKeySource) == "" {
		routeKeySource = RouteKeySourceRequest
	}
	return &InboundSpec{
		RouteKeyStrategy:      spec.RouteKeyStrategy,
		RouteKeySource:        routeKeySource,
		RouteKeyConfigField:   spec.RouteKeyConfigField,
		SignatureVerification: spec.SignatureVerification,
		SupportsChallenge:     spec.SupportsChallenge,
		EventTypes:            append([]string(nil), spec.EventTypes...),
	}
}

func cloneSetupSpec(spec SetupSpec) SetupSpec {
	actions := make([]SetupActionSpec, 0, len(spec.Actions))
	for _, action := range spec.Actions {
		actions = append(actions, SetupActionSpec{
			Name:          action.Name,
			Label:         action.Label,
			Description:   action.Description,
			MutatesRemote: action.MutatesRemote,
			Idempotent:    action.Idempotent,
		})
	}
	return SetupSpec{
		SupportsDraft:        spec.SupportsDraft,
		RequiresProvisioning: spec.RequiresProvisioning,
		SupportsTest:         spec.SupportsTest,
		Actions:              actions,
	}
}

func cloneCorrelationSpec(spec *CorrelationSpec) *CorrelationSpec {
	if spec == nil {
		return nil
	}
	fields := make([]CorrelationFieldHint, 0, len(spec.Fields))
	for _, field := range spec.Fields {
		fields = append(fields, CorrelationFieldHint{
			Path:        field.Path,
			Label:       field.Label,
			Description: field.Description,
		})
	}
	strategies := make([]CorrelationStrategyHint, 0, len(spec.Strategies))
	for _, strategy := range spec.Strategies {
		strategies = append(strategies, CorrelationStrategyHint{
			Name:        strategy.Name,
			Label:       strategy.Label,
			Description: strategy.Description,
			Paths:       append([]string(nil), strategy.Paths...),
			Template:    strategy.Template,
		})
	}
	templates := make([]SessionKeyTemplateHint, 0, len(spec.Templates))
	for _, template := range spec.Templates {
		templates = append(templates, SessionKeyTemplateHint{
			Name:        template.Name,
			Label:       template.Label,
			Description: template.Description,
			Template:    template.Template,
		})
	}
	return &CorrelationSpec{
		Fields:     fields,
		Strategies: strategies,
		Templates:  templates,
	}
}

func cloneSchemas(specs []SchemaSpec) []SchemaSpec {
	out := make([]SchemaSpec, 0, len(specs))
	for _, spec := range specs {
		out = append(out, SchemaSpec{
			EventType:  spec.EventType,
			Version:    spec.Version,
			SourceKind: spec.SourceKind,
			SchemaJSON: cloneRawMessage(spec.SchemaJSON),
		})
	}
	return out
}

func cloneRawMessage(value json.RawMessage) json.RawMessage {
	if len(value) == 0 {
		return nil
	}
	return append(json.RawMessage(nil), value...)
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return value
		}
	}
	return ""
}
