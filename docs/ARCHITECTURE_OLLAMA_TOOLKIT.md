# Ollama Toolkit Architecture Design

## Overview

A comprehensive, reusable Ollama integration toolkit for Flutter Android apps that provides:
- Ollama API client with full REST API support
- Model registry with capabilities metadata (tool calling, vision, thinking)
- LangChain-inspired thinking loop framework
- MCP (Model Context Protocol) remote support
- Configuration UI components
- Android SharedPreferences-based storage (no external dependencies)
- Agent skill for AI-powered integration

## Design Principles

1. **Zero External Dependencies**: Use only Flutter SDK and existing dependencies (shared_preferences, http)
2. **AI-First Design**: Easy for AI agents to understand and integrate
3. **Modular Architecture**: Each component can be used independently
4. **Type Safety**: Leverage Dart's type system for robustness
5. **Testability**: Comprehensive test coverage
6. **Documentation**: Rich inline documentation for AI consumption

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Ollama Config UI │  │ Model Selector   │                │
│  └──────────────────┘  └──────────────────┘                │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    Toolkit Layer                             │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Thinking Loop    │  │ MCP Client       │                │
│  │ Framework        │  │ (Tool Calling)   │                │
│  └──────────────────┘  └──────────────────┘                │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    Service Layer                             │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Ollama Client    │  │ Model Registry   │                │
│  │ (API)            │  │ (Capabilities)   │                │
│  └──────────────────┘  └──────────────────┘                │
│                 │                 │                          │
│  ┌──────────────────────────────────────┐                  │
│  │     Configuration Service             │                  │
│  │     (SharedPreferences)               │                  │
│  └──────────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
lib/
├── ollama_toolkit/
│   ├── README.md                           # Toolkit documentation
│   ├── models/                             # Data models
│   │   ├── ollama_model.dart              # Model info & capabilities
│   │   ├── ollama_message.dart            # Chat messages
│   │   ├── ollama_request.dart            # API requests
│   │   ├── ollama_response.dart           # API responses
│   │   ├── ollama_tool.dart               # Tool calling definitions
│   │   └── mcp_protocol.dart              # MCP protocol models
│   ├── services/                           # Core services
│   │   ├── ollama_client.dart             # HTTP API client
│   │   ├── model_registry.dart            # Model capabilities DB
│   │   └── ollama_config_service.dart     # Configuration storage
│   ├── thinking_loop/                      # LangChain-inspired framework
│   │   ├── agent.dart                     # Agent base class
│   │   ├── chain.dart                     # Chain abstraction
│   │   ├── memory.dart                    # Conversation memory
│   │   ├── tools.dart                     # Tool abstractions
│   │   └── mcp_tool.dart                  # MCP integration
│   ├── ui/                                # UI components
│   │   ├── ollama_config_screen.dart      # Configuration screen
│   │   ├── model_selector_widget.dart     # Model dropdown
│   │   └── connection_indicator.dart      # Status indicator
│   └── ollama_toolkit.dart                # Public API exports
│
test/
└── ollama_toolkit/
    ├── services/
    │   ├── ollama_client_test.dart
    │   ├── model_registry_test.dart
    │   └── ollama_config_service_test.dart
    ├── thinking_loop/
    │   ├── agent_test.dart
    │   └── chain_test.dart
    └── ui/
        └── widget_tests.dart
```

## Component Details

### 1. Ollama Client Service

**Purpose**: HTTP client for Ollama REST API

**Key Features**:
- Generate completions (streaming & non-streaming)
- Chat interactions with message history
- List available models
- Show model info
- Pull/delete models
- Embeddings generation
- Error handling with typed exceptions

**API Surface**:
```dart
class OllamaClient {
  Future<OllamaResponse> generate(String model, String prompt);
  Stream<OllamaResponse> generateStream(String model, String prompt);
  Future<OllamaChatResponse> chat(String model, List<OllamaMessage> messages);
  Stream<OllamaChatResponse> chatStream(String model, List<OllamaMessage> messages);
  Future<List<OllamaModel>> listModels();
  Future<OllamaModelInfo> showModel(String model);
  Future<void> pullModel(String model);
  Future<void> deleteModel(String model);
  Future<List<double>> embeddings(String model, String prompt);
}
```

### 2. Model Registry

**Purpose**: Metadata database for model capabilities

**Data Structure**:
```dart
class ModelCapabilities {
  final bool supportsToolCalling;
  final bool supportsVision;
  final bool supportsThinking;
  final int contextWindow;
  final String? modelFamily;
  final List<String> aliases;
}

class ModelRegistry {
  static const Map<String, ModelCapabilities> registry = {
    'llama3.2': ModelCapabilities(...),
    'qwen2.5': ModelCapabilities(...),
    'mistral': ModelCapabilities(...),
    // ... more models
  };
}
```

**Supported Models** (initial set):
- **Llama 3.2**: Tool calling, 128K context
- **Qwen 2.5**: Tool calling, vision, 32K context
- **Mistral**: Basic chat, 32K context
- **DeepSeek**: Thinking mode, 64K context
- **Phi-3**: Small model, 4K context
- **Gemma 2**: Basic chat, 8K context

**Features**:
- Query by capability (e.g., "find models with tool calling")
- Fuzzy model name matching
- Extensible registry (add custom models)

### 3. Configuration Service

**Purpose**: Persist Ollama settings using SharedPreferences

**Storage Keys**:
```dart
class OllamaConfigKeys {
  static const baseUrl = 'ollama_base_url';
  static const timeout = 'ollama_timeout';
  static const defaultModel = 'ollama_default_model';
  static const lastUsedModel = 'ollama_last_used_model';
  static const streamEnabled = 'ollama_stream_enabled';
}
```

**API**:
```dart
class OllamaConfigService {
  Future<void> setBaseUrl(String url);
  Future<String> getBaseUrl();
  Future<void> setDefaultModel(String model);
  Future<String?> getDefaultModel();
  Future<void> saveModelHistory(List<String> models);
  Future<List<String>> getModelHistory();
}
```

### 4. Thinking Loop Framework

**Purpose**: LangChain-inspired framework for building AI agents

**Core Abstractions**:

```dart
// Agent - orchestrates thinking loop
abstract class Agent {
  Future<AgentResponse> run(String input);
  Future<AgentResponse> runWithTools(String input, List<Tool> tools);
}

// Chain - composable processing units
abstract class Chain {
  Future<ChainOutput> call(ChainInput input);
}

// Memory - conversation history
abstract class Memory {
  void addMessage(OllamaMessage message);
  List<OllamaMessage> getMessages();
  void clear();
}

// Tool - external capabilities
abstract class Tool {
  String get name;
  String get description;
  Future<String> execute(Map<String, dynamic> args);
}
```

**Implementation**:
```dart
class OllamaAgent extends Agent {
  final OllamaClient client;
  final String model;
  final Memory memory;
  
  @override
  Future<AgentResponse> runWithTools(String input, List<Tool> tools) {
    // 1. Add user message to memory
    // 2. Generate with tool definitions
    // 3. If tool call requested, execute tool
    // 4. Add tool result to memory
    // 5. Continue until final answer
  }
}
```

**Chains**:
- `PromptChain`: Simple prompt → response
- `ConversationChain`: Multi-turn conversation with memory
- `ToolChain`: Tool-augmented generation
- `ThinkingChain`: Reasoning with explicit thinking steps

### 5. MCP (Model Context Protocol) Support

**Purpose**: Remote tool calling via MCP servers

**Features**:
- Connect to remote MCP servers (HTTP/WebSocket)
- Discover available tools
- Execute remote tools
- Handle tool schemas

**API**:
```dart
class MCPClient {
  Future<void> connect(String serverUrl);
  Future<List<MCPTool>> listTools();
  Future<MCPToolResult> executeTool(String name, Map<String, dynamic> args);
}

class MCPTool extends Tool {
  final String name;
  final String description;
  final Map<String, dynamic> schema;
  final MCPClient client;
}
```

### 6. UI Components

#### OllamaConfigScreen
- Base URL input with validation
- Connection test button
- Model selection dropdown
- Timeout configuration
- Stream toggle
- Save/Reset buttons

#### ModelSelectorWidget
- Dropdown with model names
- Capability badges (🔧 tools, 👁️ vision, 🧠 thinking)
- Context window display
- Recent models section

#### ConnectionIndicator
- Status: Connected/Disconnected/Error
- Visual indicator (colored dot)
- Click to test connection

## Data Models

### Core Models

```dart
class OllamaMessage {
  final String role; // system, user, assistant, tool
  final String content;
  final List<String>? images; // Base64 for vision
  final List<ToolCall>? toolCalls;
}

class OllamaRequest {
  final String model;
  final String? prompt;
  final List<OllamaMessage>? messages;
  final bool stream;
  final Map<String, dynamic>? options;
  final List<ToolDefinition>? tools;
}

class OllamaResponse {
  final String model;
  final String response;
  final bool done;
  final int? evalCount;
  final Duration? evalDuration;
}

class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;
}

class ToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> parameters; // JSON Schema
}
```

## Dependencies

**Required** (add to pubspec.yaml):
```yaml
dependencies:
  http: ^1.2.0  # For Ollama API calls
  # Already included:
  shared_preferences: ^2.5.4
```

**Dev Dependencies**:
```yaml
dev_dependencies:
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

## Agent Skill Definition

Create `.github/skills/ollama-integration/SKILL.md`:

```markdown
# Ollama Integration Skill

## Overview
Integrate Ollama LLM capabilities into your Flutter app using the built-in toolkit.

## When to Use
- Adding AI chat functionality
- Implementing tool-calling agents
- Creating conversational interfaces
- Building AI-powered features

## Prerequisites
- Ollama installed and running
- Network access to Ollama server

## Usage Examples

### Basic Chat Integration
<prompt>
Use the ollama_toolkit to add a chat screen that connects to my local Ollama server at http://localhost:11434 and uses the llama3.2 model.
</prompt>

### Tool-Calling Agent
<prompt>
Create an agent using ollama_toolkit that can use tools to search the web and answer questions. Use the thinking_loop framework with MCP support.
</prompt>

### Configuration UI
<prompt>
Add an Ollama configuration screen using the built-in UI components from ollama_toolkit.
</prompt>
```

## Implementation Plan

### Phase 1: Core Infrastructure (Day 1)
1. ✅ Design architecture
2. Create project structure
3. Implement data models
4. Implement OllamaClient service
5. Add comprehensive tests

### Phase 2: Registry & Config (Day 2)
6. Implement ModelRegistry
7. Implement OllamaConfigService
8. Add model capability queries
9. Test configuration persistence

### Phase 3: Thinking Loop (Day 3)
10. Implement base Agent/Chain/Memory abstractions
11. Create OllamaAgent implementation
12. Add tool calling support
13. Test thinking loops

### Phase 4: MCP Integration (Day 4)
14. Implement MCPClient
15. Create MCPTool wrapper
16. Test remote tool execution
17. Add connection handling

### Phase 5: UI Components (Day 5)
18. Create OllamaConfigScreen
19. Create ModelSelectorWidget
20. Create ConnectionIndicator
21. Add widget tests

### Phase 6: Documentation & Skills (Day 6)
22. Write toolkit README
23. Create agent skill
24. Add usage examples
25. Update main README

## Example Usage

### Basic Chat
```dart
final client = OllamaClient(baseUrl: 'http://localhost:11434');
final response = await client.generate('llama3.2', 'Hello, Ollama!');
print(response.response);
```

### Agent with Tools
```dart
final agent = OllamaAgent(
  client: client,
  model: 'llama3.2',
  memory: ConversationMemory(),
);

final tools = [
  SearchTool(),
  CalculatorTool(),
];

final result = await agent.runWithTools('What is 2+2 and search for Flutter', tools);
```

### Configuration UI
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => OllamaConfigScreen()),
);
```

## Testing Strategy

1. **Unit Tests**: Each service/model independently
2. **Integration Tests**: Client + API interactions (mock server)
3. **Widget Tests**: UI components
4. **Agent Tests**: Thinking loop with mock tools

## Success Criteria

- ✅ Zero external dependencies beyond http
- ✅ Comprehensive model registry (10+ models)
- ✅ Full Ollama API coverage
- ✅ Working thinking loop with tools
- ✅ MCP remote tool support
- ✅ Reusable UI components
- ✅ 80%+ test coverage
- ✅ AI agent skill ready
- ✅ Complete documentation

## Future Enhancements

- Stream handling for UI (real-time typing effect)
- Multi-modal support (image inputs)
- RAG (Retrieval Augmented Generation) toolkit
- Vector database integration
- Prompt template library
- Agent orchestration (multi-agent systems)
