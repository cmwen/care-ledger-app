/// Represents a message in an Ollama chat conversation.
class OllamaMessage {
  /// Role of the message sender: 'system', 'user', 'assistant', or 'tool'
  final String role;

  /// Content of the message
  final String content;

  /// Optional list of base64-encoded images for vision models
  final List<String>? images;

  /// Optional list of tool calls made by the assistant
  final List<ToolCall>? toolCalls;

  /// Optional thinking/reasoning trace (for thinking-capable models)
  final String? thinking;

  /// Tool name for tool role messages
  final String? toolName;

  /// Tool call ID for linking tool results to tool calls
  final String? toolId;

  const OllamaMessage({
    required this.role,
    required this.content,
    this.images,
    this.toolCalls,
    this.thinking,
    this.toolName,
    this.toolId,
  });

  factory OllamaMessage.system(String content) {
    return OllamaMessage(role: 'system', content: content);
  }

  factory OllamaMessage.user(String content, {List<String>? images}) {
    return OllamaMessage(role: 'user', content: content, images: images);
  }

  factory OllamaMessage.assistant(
    String content, {
    List<ToolCall>? toolCalls,
    String? thinking,
  }) {
    return OllamaMessage(
      role: 'assistant',
      content: content,
      toolCalls: toolCalls,
      thinking: thinking,
    );
  }

  factory OllamaMessage.tool(
    String content, {
    required String toolName,
    String? toolId,
  }) {
    return OllamaMessage(
      role: 'tool',
      content: content,
      toolName: toolName,
      toolId: toolId,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'role': role, 'content': content};

    if (images != null && images!.isNotEmpty) {
      json['images'] = images;
    }

    if (toolCalls != null && toolCalls!.isNotEmpty) {
      json['tool_calls'] = toolCalls!.map((tc) => tc.toJson()).toList();
    }

    if (thinking != null) {
      json['thinking'] = thinking;
    }

    if (toolName != null) {
      json['tool_name'] = toolName;
    }

    if (toolId != null) {
      json['tool_id'] = toolId;
    }

    return json;
  }

  factory OllamaMessage.fromJson(Map<String, dynamic> json) {
    return OllamaMessage(
      role: json['role'] as String,
      content: json['content'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)?.cast<String>(),
      toolCalls: (json['tool_calls'] as List<dynamic>?)
          ?.map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
          .toList(),
      thinking: json['thinking'] as String?,
      toolName: json['tool_name'] as String?,
      toolId: json['tool_id'] as String?,
    );
  }

  @override
  String toString() {
    return 'OllamaMessage(role: $role, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
  }
}

/// Represents a tool call made by the model
class ToolCall {
  /// Unique identifier for the tool call
  final String id;

  /// Name of the tool to call
  final String name;

  /// Arguments to pass to the tool as a JSON object
  final Map<String, dynamic> arguments;

  /// Index for parallel tool calling (optional)
  final int? index;

  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
    this.index,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'name': name,
      'arguments': arguments,
    };
    if (index != null) {
      json['index'] = index;
    }
    return json;
  }

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    // Debug: log the raw JSON to see what Ollama returns
    // ignore: avoid_print
    print('[ToolCall.fromJson] Raw JSON: $json');

    // Helper to convert Map<dynamic, dynamic> to Map<String, dynamic>
    Map<String, dynamic> toStringKeyMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value;
      } else if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return {};
    }

    return ToolCall(
      id: json['id'] as String? ?? '',
      name:
          json['name'] as String? ?? json['function']?['name'] as String? ?? '',
      arguments: toStringKeyMap(
        json['arguments'] ?? json['function']?['arguments'],
      ),
      index: json['index'] as int?,
    );
  }

  @override
  String toString() => 'ToolCall(id: $id, name: $name)';
}
