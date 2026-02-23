import 'package:flutter_test/flutter_test.dart';
import 'package:min_flutter_template/ollama_toolkit/models/ollama_tool.dart';

void main() {
  group('ToolDefinition', () {
    group('Constructor and properties', () {
      test('creates tool with required fields', () {
        final tool = ToolDefinition(
          name: 'get_weather',
          description: 'Get weather information',
          parameters: {
            'type': 'object',
            'properties': {
              'location': {'type': 'string'},
            },
          },
        );

        expect(tool.name, 'get_weather');
        expect(tool.description, 'Get weather information');
        expect(tool.parameters['type'], 'object');
      });

      test('handles complex parameter schemas', () {
        final parameters = {
          'type': 'object',
          'properties': {
            'location': {
              'type': 'string',
              'description': 'City name',
            },
            'units': {
              'type': 'string',
              'enum': ['celsius', 'fahrenheit'],
            },
            'date': {
              'type': 'string',
              'format': 'date',
            },
          },
          'required': ['location'],
        };
        final tool = ToolDefinition(
          name: 'complex_tool',
          description: 'Complex tool',
          parameters: parameters,
        );

        expect(tool.parameters['properties']['location']['type'], 'string');
        expect(tool.parameters['properties']['units']['enum'], ['celsius', 'fahrenheit']);
        expect(tool.parameters['required'], ['location']);
      });
    });

    group('JSON serialization', () {
      test('toJson returns proper OpenAI function format', () {
        final tool = ToolDefinition(
          name: 'test_tool',
          description: 'Test description',
          parameters: {
            'type': 'object',
            'properties': {
              'param1': {'type': 'string'},
            },
          },
        );
        final json = tool.toJson();

        expect(json['type'], 'function');
        expect(json['function'], isNotNull);
        expect(json['function']['name'], 'test_tool');
        expect(json['function']['description'], 'Test description');
        expect(json['function']['parameters'], isNotNull);
      });

      test('toJson preserves parameter schema', () {
        final parameters = {
          'type': 'object',
          'properties': {
            'input': {'type': 'string'},
          },
          'required': ['input'],
        };
        final tool = ToolDefinition(
          name: 'tool',
          description: 'desc',
          parameters: parameters,
        );
        final json = tool.toJson();

        expect(json['function']['parameters'], parameters);
      });
    });

    group('JSON deserialization', () {
      test('fromJson extracts tool from OpenAI function format', () {
        final json = {
          'type': 'function',
          'function': {
            'name': 'get_weather',
            'description': 'Get weather info',
            'parameters': {
              'type': 'object',
              'properties': {
                'location': {'type': 'string'},
              },
            },
          },
        };
        final tool = ToolDefinition.fromJson(json);

        expect(tool.name, 'get_weather');
        expect(tool.description, 'Get weather info');
        expect(tool.parameters['type'], 'object');
      });

      test('fromJson with complex parameters', () {
        final json = {
          'type': 'function',
          'function': {
            'name': 'complex',
            'description': 'Complex tool',
            'parameters': {
              'type': 'object',
              'properties': {
                'param1': {
                  'type': 'string',
                  'enum': ['a', 'b', 'c'],
                },
              },
              'required': ['param1'],
            },
          },
        };
        final tool = ToolDefinition.fromJson(json);

        expect(tool.parameters['properties']['param1']['enum'], ['a', 'b', 'c']);
        expect(tool.parameters['required'], ['param1']);
      });

      test('round-trip serialization preserves all data', () {
        final original = ToolDefinition(
          name: 'calculate',
          description: 'Perform calculations',
          parameters: {
            'type': 'object',
            'properties': {
              'expression': {'type': 'string'},
            },
            'required': ['expression'],
          },
        );

        final json = original.toJson();
        final restored = ToolDefinition.fromJson(json);

        expect(restored.name, original.name);
        expect(restored.description, original.description);
        expect(restored.parameters, original.parameters);
      });
    });

    group('toString', () {
      test('includes tool name', () {
        final tool = ToolDefinition(
          name: 'my_tool',
          description: 'desc',
          parameters: {},
        );
        final str = tool.toString();

        expect(str, contains('my_tool'));
      });
    });
  });

  group('ToolResult', () {
    group('Constructor and properties', () {
      test('creates successful result with required fields', () {
        final result = ToolResult(
          toolCallId: 'call-1',
          toolName: 'get_weather',
          result: 'Weather in NYC: 72F',
        );

        expect(result.toolCallId, 'call-1');
        expect(result.toolName, 'get_weather');
        expect(result.result, 'Weather in NYC: 72F');
        expect(result.success, true);
        expect(result.error, isNull);
      });

      test('creates failed result with error message', () {
        final result = ToolResult(
          toolCallId: 'call-1',
          toolName: 'get_weather',
          result: '',
          success: false,
          error: 'API connection failed',
        );

        expect(result.success, false);
        expect(result.error, 'API connection failed');
      });

      test('success defaults to true', () {
        final result = ToolResult(
          toolCallId: 'call-1',
          toolName: 'test',
          result: 'output',
        );

        expect(result.success, true);
      });
    });

    group('JSON serialization', () {
      test('toJson with successful result', () {
        final result = ToolResult(
          toolCallId: 'call-1',
          toolName: 'test_tool',
          result: 'Success!',
          success: true,
        );
        final json = result.toJson();

        expect(json['tool_call_id'], 'call-1');
        expect(json['tool_name'], 'test_tool');
        expect(json['result'], 'Success!');
        expect(json['success'], true);
        expect(json.containsKey('error'), false);
      });

      test('toJson with failed result includes error', () {
        final result = ToolResult(
          toolCallId: 'call-1',
          toolName: 'test_tool',
          result: '',
          success: false,
          error: 'Connection timeout',
        );
        final json = result.toJson();

        expect(json['success'], false);
        expect(json['error'], 'Connection timeout');
      });

      test('toJson omits error field when null', () {
        final result = ToolResult(
          toolCallId: 'call-1',
          toolName: 'test_tool',
          result: 'output',
          success: true,
        );
        final json = result.toJson();

        expect(json.containsKey('error'), false);
      });
    });

    group('JSON deserialization', () {
      test('fromJson with successful result', () {
        final json = {
          'tool_call_id': 'call-1',
          'tool_name': 'weather',
          'result': '72F and sunny',
          'success': true,
        };
        final result = ToolResult.fromJson(json);

        expect(result.toolCallId, 'call-1');
        expect(result.toolName, 'weather');
        expect(result.result, '72F and sunny');
        expect(result.success, true);
        expect(result.error, isNull);
      });

      test('fromJson with failed result', () {
        final json = {
          'tool_call_id': 'call-1',
          'tool_name': 'weather',
          'result': '',
          'success': false,
          'error': 'API error',
        };
        final result = ToolResult.fromJson(json);

        expect(result.success, false);
        expect(result.error, 'API error');
      });

      test('fromJson success defaults to true if not provided', () {
        final json = {
          'tool_call_id': 'call-1',
          'tool_name': 'test',
          'result': 'output',
        };
        final result = ToolResult.fromJson(json);

        expect(result.success, true);
      });

      test('fromJson with null error field', () {
        final json = {
          'tool_call_id': 'call-1',
          'tool_name': 'test',
          'result': 'output',
          'success': true,
          'error': null,
        };
        final result = ToolResult.fromJson(json);

        expect(result.error, isNull);
      });

      test('round-trip serialization preserves all fields', () {
        final original = ToolResult(
          toolCallId: 'call-123',
          toolName: 'my_tool',
          result: 'This is the result',
          success: true,
        );

        final json = original.toJson();
        final restored = ToolResult.fromJson(json);

        expect(restored.toolCallId, original.toolCallId);
        expect(restored.toolName, original.toolName);
        expect(restored.result, original.result);
        expect(restored.success, original.success);
      });

      test('round-trip with failed result', () {
        final original = ToolResult(
          toolCallId: 'call-456',
          toolName: 'failing_tool',
          result: '',
          success: false,
          error: 'Something went wrong',
        );

        final json = original.toJson();
        final restored = ToolResult.fromJson(json);

        expect(restored.toolCallId, original.toolCallId);
        expect(restored.toolName, original.toolName);
        expect(restored.success, false);
        expect(restored.error, 'Something went wrong');
      });
    });

    group('toString', () {
      test('shows tool name and success status', () {
        final result = ToolResult(
          toolCallId: 'call-1',
          toolName: 'my_tool',
          result: 'output',
          success: true,
        );
        final str = result.toString();

        expect(str, contains('my_tool'));
        expect(str, contains('success: true'));
      });

      test('shows failure status in toString', () {
        final result = ToolResult(
          toolCallId: 'call-1',
          toolName: 'tool',
          result: '',
          success: false,
        );
        final str = result.toString();

        expect(str, contains('success: false'));
      });
    });

    group('Usage patterns', () {
      test('typical successful tool execution pattern', () {
        final result = ToolResult(
          toolCallId: 'call-xyz',
          toolName: 'calculate_total',
          result: '42',
        );

        expect(result.success, true);
        expect(result.result, '42');
      });

      test('typical failed tool execution pattern', () {
        final result = ToolResult(
          toolCallId: 'call-xyz',
          toolName: 'fetch_data',
          result: '',
          success: false,
          error: 'Network timeout after 30s',
        );

        expect(result.success, false);
        expect(result.error, 'Network timeout after 30s');
      });

      test('tool with large result data', () {
        final largeData = List.generate(100, (i) => 'item_$i').join('\n');
        final result = ToolResult(
          toolCallId: 'call-1',
          toolName: 'list_items',
          result: largeData,
        );

        expect(result.result.length, greaterThan(500));
        expect(result.success, true);
      });
    });
  });
}
