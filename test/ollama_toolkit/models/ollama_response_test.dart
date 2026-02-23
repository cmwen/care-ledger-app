import 'package:flutter_test/flutter_test.dart';
import 'package:min_flutter_template/ollama_toolkit/models/ollama_message.dart';
import 'package:min_flutter_template/ollama_toolkit/models/ollama_response.dart';

void main() {
  group('OllamaGenerateResponse', () {
    group('Constructor and properties', () {
      test('creates response with required fields', () {
        final response = OllamaGenerateResponse(
          model: 'llama3.1',
          response: 'Hello, world!',
          done: true,
        );

        expect(response.model, 'llama3.1');
        expect(response.response, 'Hello, world!');
        expect(response.done, true);
        expect(response.context, isNull);
        expect(response.evalCount, isNull);
        expect(response.evalDuration, isNull);
        expect(response.thinking, isNull);
      });

      test('creates response with all fields', () {
        final response = OllamaGenerateResponse(
          model: 'llama3.1',
          response: 'Test response',
          done: true,
          context: [1, 2, 3],
          evalCount: 100,
          evalDuration: 1500000000,
          thinking: 'Processing...',
        );

        expect(response.context, [1, 2, 3]);
        expect(response.evalCount, 100);
        expect(response.evalDuration, 1500000000);
        expect(response.thinking, 'Processing...');
      });
    });

    group('JSON deserialization', () {
      test('fromJson with minimal fields', () {
        final json = {
          'model': 'llama3.1',
          'response': 'Hello',
          'done': true,
        };
        final response = OllamaGenerateResponse.fromJson(json);

        expect(response.model, 'llama3.1');
        expect(response.response, 'Hello');
        expect(response.done, true);
      });

      test('fromJson with missing response defaults to empty string', () {
        final json = {
          'model': 'llama3.1',
          'response': null,
          'done': true,
        };
        final response = OllamaGenerateResponse.fromJson(json);

        expect(response.response, '');
      });

      test('fromJson with all fields', () {
        final json = {
          'model': 'llama3.1:8b',
          'response': 'Test content',
          'done': false,
          'context': [1, 2, 3, 4],
          'eval_count': 50,
          'eval_duration': 2000000000,
          'thinking': 'Analyzing...',
        };
        final response = OllamaGenerateResponse.fromJson(json);

        expect(response.model, 'llama3.1:8b');
        expect(response.response, 'Test content');
        expect(response.done, false);
        expect(response.context, [1, 2, 3, 4]);
        expect(response.evalCount, 50);
        expect(response.evalDuration, 2000000000);
        expect(response.thinking, 'Analyzing...');
      });

      test('fromJson handles context as integer list', () {
        final json = {
          'model': 'test',
          'response': 'test',
          'done': true,
          'context': [10, 20, 30],
        };
        final response = OllamaGenerateResponse.fromJson(json);

        expect(response.context, [10, 20, 30]);
      });
    });

    group('Duration calculation', () {
      test('evalTime converts nanoseconds to Duration', () {
        final response = OllamaGenerateResponse(
          model: 'test',
          response: 'test',
          done: true,
          evalDuration: 1000000000, // 1 second in nanoseconds
        );

        expect(response.evalTime, isNotNull);
        expect(response.evalTime!.inMicroseconds, 1000000); // 1 billion nanoseconds / 1000 = 1 million microseconds = 1 second
      });

      test('evalTime returns null when evalDuration is null', () {
        final response = OllamaGenerateResponse(
          model: 'test',
          response: 'test',
          done: true,
        );

        expect(response.evalTime, isNull);
      });

      test('evalTime handles various durations', () {
        final response = OllamaGenerateResponse(
          model: 'test',
          response: 'test',
          done: true,
          evalDuration: 500000000, // 500 milliseconds in nanoseconds
        );

        expect(response.evalTime, isNotNull);
        expect(response.evalTime!.inMicroseconds, 500000); // 500 milliseconds
      });
    });

    group('toString', () {
      test('includes model, done status and truncated response', () {
        final response = OllamaGenerateResponse(
          model: 'llama3.1',
          response: 'This is a very long response',
          done: true,
        );
        final str = response.toString();

        expect(str, contains('llama3.1'));
        expect(str, contains('done: true'));
        expect(str, contains('This is a very long'));
      });

      test('toString with short response shows full content', () {
        final response = OllamaGenerateResponse(
          model: 'test',
          response: 'Short',
          done: false,
        );
        final str = response.toString();

        expect(str, contains('Short'));
      });
    });
  });

  group('OllamaChatResponse', () {
    group('Constructor and properties', () {
      test('creates response with required fields', () {
        final message = OllamaMessage.assistant('Test');
        final response = OllamaChatResponse(
          model: 'llama3.1',
          message: message,
          done: true,
        );

        expect(response.model, 'llama3.1');
        expect(response.message, message);
        expect(response.done, true);
        expect(response.evalCount, isNull);
        expect(response.evalDuration, isNull);
      });

      test('creates response with all fields', () {
        final message = OllamaMessage.assistant('Test');
        final response = OllamaChatResponse(
          model: 'llama3.1',
          message: message,
          done: false,
          evalCount: 150,
          evalDuration: 2500000000,
        );

        expect(response.evalCount, 150);
        expect(response.evalDuration, 2500000000);
      });
    });

    group('JSON deserialization', () {
      test('fromJson with basic message', () {
        final json = {
          'model': 'llama3.1',
          'message': {
            'role': 'assistant',
            'content': 'Hello!',
          },
          'done': true,
        };
        final response = OllamaChatResponse.fromJson(json);

        expect(response.model, 'llama3.1');
        expect(response.message.role, 'assistant');
        expect(response.message.content, 'Hello!');
        expect(response.done, true);
      });

      test('fromJson with complex message including tool calls', () {
        final json = {
          'model': 'llama3.1',
          'message': {
            'role': 'assistant',
            'content': 'I will help',
            'tool_calls': [
              {
                'id': 'call-1',
                'name': 'test_tool',
                'arguments': {'param': 'value'},
              }
            ],
          },
          'done': true,
        };
        final response = OllamaChatResponse.fromJson(json);

        expect(response.message.toolCalls, isNotEmpty);
        expect(response.message.toolCalls!.first.name, 'test_tool');
      });

      test('fromJson with eval metrics', () {
        final json = {
          'model': 'test',
          'message': {
            'role': 'assistant',
            'content': 'test',
          },
          'done': true,
          'eval_count': 200,
          'eval_duration': 3000000000,
        };
        final response = OllamaChatResponse.fromJson(json);

        expect(response.evalCount, 200);
        expect(response.evalDuration, 3000000000);
      });
    });

    group('Duration calculation', () {
      test('evalTime converts nanoseconds to Duration', () {
        final message = OllamaMessage.assistant('Test');
        final response = OllamaChatResponse(
          model: 'test',
          message: message,
          done: true,
          evalDuration: 2000000000, // 2 seconds in nanoseconds
        );

        expect(response.evalTime, isNotNull);
        expect(response.evalTime!.inMicroseconds, 2000000); // 2 seconds
      });

      test('evalTime returns null when evalDuration is null', () {
        final message = OllamaMessage.assistant('Test');
        final response = OllamaChatResponse(
          model: 'test',
          message: message,
          done: true,
        );

        expect(response.evalTime, isNull);
      });
    });

    group('toString', () {
      test('includes model and done status', () {
        final message = OllamaMessage.assistant('Response');
        final response = OllamaChatResponse(
          model: 'llama3.1',
          message: message,
          done: true,
        );
        final str = response.toString();

        expect(str, contains('llama3.1'));
        expect(str, contains('done: true'));
      });
    });
  });

  group('OllamaEmbeddingResponse', () {
    group('Constructor and properties', () {
      test('creates response with embedding vector', () {
        final embedding = [0.1, 0.2, 0.3, 0.4];
        final response = OllamaEmbeddingResponse(embedding: embedding);

        expect(response.embedding, embedding);
        expect(response.embedding.length, 4);
      });

      test('handles large embedding vectors', () {
        final embedding = List<double>.generate(1024, (i) => i * 0.001);
        final response = OllamaEmbeddingResponse(embedding: embedding);

        expect(response.embedding.length, 1024);
      });
    });

    group('JSON deserialization', () {
      test('fromJson with embedding vector', () {
        final json = {
          'embedding': [0.1, 0.2, 0.3, 0.4],
        };
        final response = OllamaEmbeddingResponse.fromJson(json);

        expect(response.embedding, [0.1, 0.2, 0.3, 0.4]);
      });

      test('fromJson with large vector', () {
        final embedding = List<double>.generate(256, (i) => i * 0.01);
        final json = {
          'embedding': embedding,
        };
        final response = OllamaEmbeddingResponse.fromJson(json);

        expect(response.embedding.length, 256);
        expect(response.embedding.first, 0.0);
        expect(response.embedding.last, lessThan(2.56));
      });
    });

    group('toString', () {
      test('shows embedding dimensions', () {
        final response = OllamaEmbeddingResponse(
          embedding: [0.1, 0.2, 0.3],
        );
        final str = response.toString();

        expect(str, contains('dimensions: 3'));
      });

      test('handles large dimension count', () {
        final embedding = List<double>.generate(1024, (i) => i * 0.001);
        final response = OllamaEmbeddingResponse(embedding: embedding);
        final str = response.toString();

        expect(str, contains('1024'));
      });
    });
  });

  group('OllamaModelInfo', () {
    group('Constructor and properties', () {
      test('creates model info with required fields', () {
        final info = OllamaModelInfo(
          name: 'llama3.1:8b',
          modifiedAt: DateTime(2024, 1, 1),
          size: 4700000000, // ~4.7GB
          digest: 'sha256:abc123',
        );

        expect(info.name, 'llama3.1:8b');
        expect(info.modifiedAt.year, 2024);
        expect(info.size, 4700000000);
        expect(info.digest, 'sha256:abc123');
        expect(info.details, isNull);
      });

      test('creates model info with details', () {
        final details = {
          'parameter_size': '8B',
          'quantization_level': 'Q4_0',
        };
        final info = OllamaModelInfo(
          name: 'test',
          modifiedAt: DateTime.now(),
          size: 1000,
          digest: 'xyz',
          details: details,
        );

        expect(info.details, details);
      });
    });

    group('JSON deserialization', () {
      test('fromJson with all fields', () {
        final json = {
          'name': 'llama3.1:8b',
          'modified_at': '2024-01-01T12:00:00Z',
          'size': 4700000000,
          'digest': 'sha256:abc123def456',
          'details': {'parameter_size': '8B'},
        };
        final info = OllamaModelInfo.fromJson(json);

        expect(info.name, 'llama3.1:8b');
        expect(info.size, 4700000000);
        expect(info.digest, 'sha256:abc123def456');
        expect(info.details, isNotNull);
      });
    });

    group('Size formatting', () {
      test('formats bytes correctly', () {
        final info = OllamaModelInfo(
          name: 'test',
          modifiedAt: DateTime.now(),
          size: 512,
          digest: 'xyz',
        );

        expect(info.sizeFormatted, '512 B');
      });

      test('formats kilobytes correctly', () {
        final info = OllamaModelInfo(
          name: 'test',
          modifiedAt: DateTime.now(),
          size: 2048, // 2 KB
          digest: 'xyz',
        );

        expect(info.sizeFormatted, contains('KB'));
      });

      test('formats megabytes correctly', () {
        final info = OllamaModelInfo(
          name: 'test',
          modifiedAt: DateTime.now(),
          size: 52428800, // 50 MB
          digest: 'xyz',
        );

        expect(info.sizeFormatted, contains('MB'));
        expect(info.sizeFormatted, '50.0 MB');
      });

      test('formats gigabytes correctly', () {
        final info = OllamaModelInfo(
          name: 'test',
          modifiedAt: DateTime.now(),
          size: 4700000000, // ~4.7 GB
          digest: 'xyz',
        );

        expect(info.sizeFormatted, contains('GB'));
        expect(info.sizeFormatted, '4.4 GB'); // 4700000000 / (1024^3)
      });
    });

    group('Model family and details', () {
      test('family getter extracts base model name', () {
        final info = OllamaModelInfo(
          name: 'llama3.2:latest',
          modifiedAt: DateTime.now(),
          size: 1000,
          digest: 'xyz',
        );

        expect(info.family, 'llama3.2');
      });

      test('family getter handles names without tags', () {
        final info = OllamaModelInfo(
          name: 'llama3.2',
          modifiedAt: DateTime.now(),
          size: 1000,
          digest: 'xyz',
        );

        expect(info.family, 'llama3.2');
      });

      test('parameterCount extracts from details', () {
        final info = OllamaModelInfo(
          name: 'test',
          modifiedAt: DateTime.now(),
          size: 1000,
          digest: 'xyz',
          details: {'parameter_size': '8B'},
        );

        expect(info.parameterCount, '8B');
      });

      test('parameterCount returns null when details is null', () {
        final info = OllamaModelInfo(
          name: 'test',
          modifiedAt: DateTime.now(),
          size: 1000,
          digest: 'xyz',
        );

        expect(info.parameterCount, isNull);
      });
    });

    group('Capabilities', () {
      test('capabilities returns known model capabilities', () {
        final info = OllamaModelInfo(
          name: 'llama3.1',
          modifiedAt: DateTime.now(),
          size: 1000,
          digest: 'xyz',
        );

        expect(info.capabilities, isNotNull);
        expect(info.capabilities!.supportsToolCalling, true);
      });

      test('capabilities returns null for unknown model', () {
        final info = OllamaModelInfo(
          name: 'unknown_model_xyz',
          modifiedAt: DateTime.now(),
          size: 1000,
          digest: 'xyz',
        );

        expect(info.capabilities, isNull);
      });
    });

    group('toString', () {
      test('includes name and formatted size', () {
        final info = OllamaModelInfo(
          name: 'llama3.1:8b',
          modifiedAt: DateTime.now(),
          size: 4700000000,
          digest: 'xyz',
        );
        final str = info.toString();

        expect(str, contains('llama3.1:8b'));
        expect(str, contains('GB'));
      });
    });
  });

  group('OllamaModelsResponse', () {
    group('Constructor and properties', () {
      test('creates response with model list', () {
        final models = [
          OllamaModelInfo(
            name: 'llama3.1:8b',
            modifiedAt: DateTime.now(),
            size: 4700000000,
            digest: 'abc',
          ),
          OllamaModelInfo(
            name: 'llama3.2:vision',
            modifiedAt: DateTime.now(),
            size: 5500000000,
            digest: 'def',
          ),
        ];
        final response = OllamaModelsResponse(models: models);

        expect(response.models, models);
        expect(response.models.length, 2);
      });

      test('handles empty model list', () {
        final response = OllamaModelsResponse(models: []);

        expect(response.models, isEmpty);
      });
    });

    group('JSON deserialization', () {
      test('fromJson with multiple models', () {
        final json = {
          'models': [
            {
              'name': 'llama3.1:8b',
              'modified_at': '2024-01-01T00:00:00Z',
              'size': 4700000000,
              'digest': 'abc',
            },
            {
              'name': 'llama3.2:vision',
              'modified_at': '2024-01-02T00:00:00Z',
              'size': 5500000000,
              'digest': 'def',
            },
          ],
        };
        final response = OllamaModelsResponse.fromJson(json);

        expect(response.models.length, 2);
        expect(response.models[0].name, 'llama3.1:8b');
        expect(response.models[1].name, 'llama3.2:vision');
      });

      test('fromJson with empty models list', () {
        final json = {
          'models': [],
        };
        final response = OllamaModelsResponse.fromJson(json);

        expect(response.models, isEmpty);
      });
    });

    group('toString', () {
      test('shows model count', () {
        final models = [
          OllamaModelInfo(
            name: 'test1',
            modifiedAt: DateTime.now(),
            size: 1000,
            digest: 'a',
          ),
          OllamaModelInfo(
            name: 'test2',
            modifiedAt: DateTime.now(),
            size: 2000,
            digest: 'b',
          ),
        ];
        final response = OllamaModelsResponse(models: models);
        final str = response.toString();

        expect(str, contains('count: 2'));
      });
    });
  });
}
