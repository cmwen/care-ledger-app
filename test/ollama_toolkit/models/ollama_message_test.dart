import 'package:flutter_test/flutter_test.dart';
import 'package:min_flutter_template/ollama_toolkit/models/ollama_message.dart';

void main() {
  group('OllamaMessage', () {
    group('Factory constructors', () {
      test('system message factory sets correct role and content', () {
        final message = OllamaMessage.system('You are a helpful assistant');

        expect(message.role, 'system');
        expect(message.content, 'You are a helpful assistant');
        expect(message.images, isNull);
        expect(message.toolCalls, isNull);
        expect(message.thinking, isNull);
        expect(message.toolName, isNull);
        expect(message.toolId, isNull);
      });

      test('user message factory sets correct role and content', () {
        final message = OllamaMessage.user('Hello, how are you?');

        expect(message.role, 'user');
        expect(message.content, 'Hello, how are you?');
        expect(message.images, isNull);
        expect(message.toolCalls, isNull);
      });

      test('user message factory with images includes images list', () {
        final imageList = ['base64image1', 'base64image2'];
        final message = OllamaMessage.user(
          'What is in these images?',
          images: imageList,
        );

        expect(message.role, 'user');
        expect(message.content, 'What is in these images?');
        expect(message.images, imageList);
        expect(message.toolCalls, isNull);
      });

      test('assistant message factory sets correct role and content', () {
        final message = OllamaMessage.assistant('I am doing well!');

        expect(message.role, 'assistant');
        expect(message.content, 'I am doing well!');
        expect(message.images, isNull);
        expect(message.toolCalls, isNull);
        expect(message.thinking, isNull);
      });

      test('assistant message factory with tool calls', () {
        final toolCall = ToolCall(
          id: 'call-1',
          name: 'get_weather',
          arguments: {'location': 'NYC'},
        );
        final message = OllamaMessage.assistant(
          'I will check the weather for you',
          toolCalls: [toolCall],
        );

        expect(message.role, 'assistant');
        expect(message.toolCalls, isNotEmpty);
        expect(message.toolCalls!.first.name, 'get_weather');
      });

      test('assistant message factory with thinking', () {
        final message = OllamaMessage.assistant(
          'The answer is 42',
          thinking: 'Let me work through this problem...',
        );

        expect(message.thinking, 'Let me work through this problem...');
      });

      test('tool message factory sets correct role and fields', () {
        final message = OllamaMessage.tool(
          'Weather in NYC: 72F and sunny',
          toolName: 'get_weather',
          toolId: 'call-1',
        );

        expect(message.role, 'tool');
        expect(message.content, 'Weather in NYC: 72F and sunny');
        expect(message.toolName, 'get_weather');
        expect(message.toolId, 'call-1');
        expect(message.images, isNull);
        expect(message.toolCalls, isNull);
      });
    });

    group('JSON serialization', () {
      test('toJson includes role and content', () {
        final message = OllamaMessage.user('Hello');
        final json = message.toJson();

        expect(json['role'], 'user');
        expect(json['content'], 'Hello');
      });

      test('toJson omits null optional fields', () {
        final message = OllamaMessage.user('Hello');
        final json = message.toJson();

        expect(json.containsKey('images'), false);
        expect(json.containsKey('tool_calls'), false);
        expect(json.containsKey('thinking'), false);
        expect(json.containsKey('tool_name'), false);
        expect(json.containsKey('tool_id'), false);
      });

      test('toJson includes non-empty images list', () {
        final message = OllamaMessage.user(
          'What is this?',
          images: ['img1', 'img2'],
        );
        final json = message.toJson();

        expect(json['images'], ['img1', 'img2']);
      });

      test('toJson omits empty images list', () {
        final message = OllamaMessage.user(
          'What is this?',
          images: [],
        );
        final json = message.toJson();

        expect(json.containsKey('images'), false);
      });

      test('toJson includes non-empty tool calls', () {
        final toolCall = ToolCall(
          id: 'call-1',
          name: 'test',
          arguments: {'key': 'value'},
        );
        final message = OllamaMessage.assistant(
          'Test',
          toolCalls: [toolCall],
        );
        final json = message.toJson();

        expect(json['tool_calls'], isNotEmpty);
        expect(json['tool_calls']![0]['name'], 'test');
      });

      test('toJson omits empty tool calls list', () {
        final message = OllamaMessage.assistant(
          'Test',
          toolCalls: [],
        );
        final json = message.toJson();

        expect(json.containsKey('tool_calls'), false);
      });

      test('toJson includes thinking when present', () {
        final message = OllamaMessage.assistant(
          'Answer',
          thinking: 'Some thinking',
        );
        final json = message.toJson();

        expect(json['thinking'], 'Some thinking');
      });

      test('toJson includes tool-related fields for tool role messages', () {
        final message = OllamaMessage.tool(
          'Result',
          toolName: 'my_tool',
          toolId: 'id-1',
        );
        final json = message.toJson();

        expect(json['tool_name'], 'my_tool');
        expect(json['tool_id'], 'id-1');
      });
    });

    group('JSON deserialization', () {
      test('fromJson with minimal fields', () {
        final json = {
          'role': 'user',
          'content': 'Hello',
        };
        final message = OllamaMessage.fromJson(json);

        expect(message.role, 'user');
        expect(message.content, 'Hello');
        expect(message.images, isNull);
        expect(message.toolCalls, isNull);
      });

      test('fromJson with empty content defaults to empty string', () {
        final json = {
          'role': 'user',
          'content': null,
        };
        final message = OllamaMessage.fromJson(json);

        expect(message.content, '');
      });

      test('fromJson with images', () {
        final json = {
          'role': 'user',
          'content': 'What is this?',
          'images': ['img1', 'img2'],
        };
        final message = OllamaMessage.fromJson(json);

        expect(message.images, ['img1', 'img2']);
      });

      test('fromJson with tool calls', () {
        final json = {
          'role': 'assistant',
          'content': 'Test',
          'tool_calls': [
            {
              'id': 'call-1',
              'name': 'test_tool',
              'arguments': {'param': 'value'},
            }
          ],
        };
        final message = OllamaMessage.fromJson(json);

        expect(message.toolCalls, isNotEmpty);
        expect(message.toolCalls!.first.id, 'call-1');
        expect(message.toolCalls!.first.name, 'test_tool');
      });

      test('fromJson with thinking', () {
        final json = {
          'role': 'assistant',
          'content': 'Answer',
          'thinking': 'Working through problem...',
        };
        final message = OllamaMessage.fromJson(json);

        expect(message.thinking, 'Working through problem...');
      });

      test('fromJson with tool role fields', () {
        final json = {
          'role': 'tool',
          'content': 'Result here',
          'tool_name': 'my_tool',
          'tool_id': 'id-1',
        };
        final message = OllamaMessage.fromJson(json);

        expect(message.role, 'tool');
        expect(message.toolName, 'my_tool');
        expect(message.toolId, 'id-1');
      });

      test('round-trip serialization preserves all fields', () {
        final original = OllamaMessage.assistant(
          'Test content',
          toolCalls: [
            ToolCall(
              id: 'call-1',
              name: 'test',
              arguments: {'key': 'value'},
            ),
          ],
          thinking: 'Some thoughts',
        );

        final json = original.toJson();
        final restored = OllamaMessage.fromJson(json);

        expect(restored.role, original.role);
        expect(restored.content, original.content);
        expect(restored.thinking, original.thinking);
        expect(restored.toolCalls?.length, original.toolCalls?.length);
        expect(restored.toolCalls?.first.id, original.toolCalls?.first.id);
      });
    });

    group('toString', () {
      test('toString includes role and truncated content', () {
        final message = OllamaMessage.user('This is a very long message');
        final str = message.toString();

        expect(str, contains('user'));
        expect(str, contains('This is a very long me'));
      });

      test('toString with short content shows full content', () {
        final message = OllamaMessage.user('Short');
        final str = message.toString();

        expect(str, contains('Short'));
      });
    });
  });

  group('ToolCall', () {
    group('Constructor and properties', () {
      test('ToolCall can be created with required fields', () {
        final toolCall = ToolCall(
          id: 'call-123',
          name: 'get_weather',
          arguments: {'city': 'NYC'},
        );

        expect(toolCall.id, 'call-123');
        expect(toolCall.name, 'get_weather');
        expect(toolCall.arguments, {'city': 'NYC'});
        expect(toolCall.index, isNull);
      });

      test('ToolCall can be created with index', () {
        final toolCall = ToolCall(
          id: 'call-1',
          name: 'test',
          arguments: {},
          index: 0,
        );

        expect(toolCall.index, 0);
      });

      test('ToolCall with complex nested arguments', () {
        final arguments = {
          'location': 'NYC',
          'filter': {
            'min_temp': 60,
            'max_temp': 80,
          },
          'units': ['celsius', 'fahrenheit'],
        };
        final toolCall = ToolCall(
          id: 'call-1',
          name: 'complex_tool',
          arguments: arguments,
        );

        expect(toolCall.arguments, arguments);
        expect(toolCall.arguments['filter']['min_temp'], 60);
      });
    });

    group('JSON serialization', () {
      test('toJson includes all required fields', () {
        final toolCall = ToolCall(
          id: 'call-1',
          name: 'test_tool',
          arguments: {'param': 'value'},
        );
        final json = toolCall.toJson();

        expect(json['id'], 'call-1');
        expect(json['name'], 'test_tool');
        expect(json['arguments'], {'param': 'value'});
      });

      test('toJson includes index when present', () {
        final toolCall = ToolCall(
          id: 'call-1',
          name: 'test',
          arguments: {},
          index: 2,
        );
        final json = toolCall.toJson();

        expect(json['index'], 2);
      });

      test('toJson omits index when null', () {
        final toolCall = ToolCall(
          id: 'call-1',
          name: 'test',
          arguments: {},
        );
        final json = toolCall.toJson();

        expect(json.containsKey('index'), false);
      });
    });

    group('JSON deserialization', () {
      test('fromJson with basic fields', () {
        final json = {
          'id': 'call-1',
          'name': 'test_tool',
          'arguments': {'key': 'value'},
        };
        final toolCall = ToolCall.fromJson(json);

        expect(toolCall.id, 'call-1');
        expect(toolCall.name, 'test_tool');
        expect(toolCall.arguments, {'key': 'value'});
      });

      test('fromJson with missing id defaults to empty string', () {
        final json = {
          'name': 'test',
          'arguments': {},
        };
        final toolCall = ToolCall.fromJson(json);

        expect(toolCall.id, '');
      });

      test('fromJson with missing name defaults to empty string', () {
        final json = {
          'id': 'call-1',
          'arguments': {},
        };
        final toolCall = ToolCall.fromJson(json);

        expect(toolCall.name, '');
      });

      test('fromJson with function wrapper (alternative format)', () {
        final json = {
          'id': 'call-1',
          'function': {
            'name': 'test_tool',
          },
          'arguments': {'key': 'value'},
        };
        final toolCall = ToolCall.fromJson(json);

        expect(toolCall.name, 'test_tool');
      });

      test('fromJson with function.arguments wrapper', () {
        final json = {
          'id': 'call-1',
          'function': {
            'name': 'test',
            'arguments': {'key': 'value'},
          },
        };
        final toolCall = ToolCall.fromJson(json);

        expect(toolCall.arguments, {'key': 'value'});
      });

      test('fromJson with index', () {
        final json = {
          'id': 'call-1',
          'name': 'test',
          'arguments': {},
          'index': 1,
        };
        final toolCall = ToolCall.fromJson(json);

        expect(toolCall.index, 1);
      });

      test('fromJson with Map<dynamic, dynamic> arguments', () {
        final json = {
          'id': 'call-1',
          'name': 'test',
          'arguments': <dynamic, dynamic>{'key': 'value'},
        };
        final toolCall = ToolCall.fromJson(json);

        expect(toolCall.arguments, {'key': 'value'});
      });

      test('round-trip serialization preserves all fields', () {
        final original = ToolCall(
          id: 'call-123',
          name: 'test_tool',
          arguments: {'param1': 'value1', 'param2': 42},
          index: 0,
        );

        final json = original.toJson();
        final restored = ToolCall.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.arguments, original.arguments);
        expect(restored.index, original.index);
      });
    });

    group('toString', () {
      test('toString includes id and name', () {
        final toolCall = ToolCall(
          id: 'call-1',
          name: 'test_tool',
          arguments: {},
        );
        final str = toolCall.toString();

        expect(str, contains('call-1'));
        expect(str, contains('test_tool'));
      });
    });
  });
}
