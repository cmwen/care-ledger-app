# Ollama Toolkit Design Pack (Orchestrated)

This document consolidates outputs from four roles:
- Product Owner
- Experience Designer
- Researcher
- Architect

## 1) Product Owner Output

### 1.1 Product Goal
Provide a reusable Flutter toolkit that makes Ollama integration fast, safe, and maintainable for app teams.

### 1.2 Product Surface (Current + Next)
Current foundation:
- API client
- Model capability registry
- Agent/thinking-loop abstractions
- Configuration persistence

Planned completion scope:
- Opinionated UI integration kit for model/config selection
- Stronger runtime diagnostics and error messaging
- Feature-level examples for host apps

### 1.3 Release Roadmap
P0:
1. Stabilize toolkit API contracts
2. Add integration examples for host app usage
3. Define compatibility matrix by Ollama version and model families

P1:
1. UI widgets for connection/model/config
2. Retry and timeout profiles by operation type
3. Telemetry hooks (optional)

P2:
1. MCP remote tool execution support
2. Tool safety policies (allowlist/limits)

## 2) Experience Designer Output

### 2.1 Developer Experience (DX) Flow
1. Import toolkit
2. Configure base URL + model
3. Test connection
4. Run chat/generation
5. Add tools and memory strategy

### 2.2 Host-App UI Patterns
Required UX modules for integration:
1. **Connection Card**
   - Base URL input
   - Ping/test action
   - Last success timestamp
2. **Model Selector**
   - Default model dropdown
   - Capability chips (tool/vision/thinking)
3. **Agent Debug Panel**
   - Show step trace in thinking loop
   - Tool calls and outputs
4. **Failure States**
   - Unreachable server
   - Unknown model
   - Timeout and partial stream interruptions

### 2.3 UX Rules
- Every failure must return actionable message + retry path.
- Connection and model validity should be preflight-checked before running agent tasks.
- Streaming UX should display partial output with cancel action.

## 3) Researcher Output

### 3.1 Model Capability Governance
- Keep static registry for curated defaults.
- Add optional runtime augmentation from `listModels()` + `showModel()`.
- Resolve model names through alias mapping first, fallback to exact match.

### 3.2 Tool Calling Safety
- Enforce schema validation before execution.
- Add per-tool timeout and max-call limits.
- Persist an execution trace for debugging and trust.

### 3.3 Reliability Recommendations
- Timeout tiers:
  - Connection test: short
  - Chat/generate: medium
  - Pull model: long
- Add exponential backoff for transient HTTP failures.
- Distinguish transport errors from model/runtime errors.

### 3.4 Testing Strategy
- Unit tests for serializers, registry lookups, and tool router.
- Contract tests for streaming parser boundaries.
- Integration smoke tests against a local Ollama instance (optional in CI).

## 4) Architect Output

### 4.1 Architecture Baseline
`ui adapters -> toolkit facade -> client/services -> models`

### 4.2 Public API Stability Rules
- Keep `ollama_toolkit.dart` exports as the only stable integration surface.
- Mark experimental APIs under a clearly named namespace.
- Version breaking API changes with migration notes.

### 4.3 Module Contracts
- `OllamaClient`: transport and endpoint semantics
- `OllamaConfigService`: persisted runtime config
- `ModelRegistry`: capability decisions and discovery fallback
- `OllamaAgent`: reasoning loop orchestration with memory and tools

### 4.4 Planned Additions
1. `ui/` module with optional widgets
2. `diagnostics/` module for tracing and health reporting
3. `mcp/` module for remote tool discovery and execution

### 4.5 Milestones
1. **T1**: API stabilization + docs refresh
2. **T2**: UI module (config + selector)
3. **T3**: diagnostics/tracing hooks
4. **T4**: MCP support and safety controls

## 5) Final Design Decisions (Approved)

1. Toolkit remains dependency-light and host-app friendly.
2. Capability registry remains explicit, with optional runtime enrichment.
3. Tool execution safety is first-class (validation, limits, traceability).
4. UI layer is optional and decoupled from core service contracts.
