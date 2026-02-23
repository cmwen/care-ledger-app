import 'package:flutter_test/flutter_test.dart';
import 'package:min_flutter_template/ollama_toolkit/models/ollama_model.dart';

void main() {
  group('ModelCapabilities', () {
    group('Constructor', () {
      test('can create with all fields', () {
        final caps = ModelCapabilities(
          supportsToolCalling: true,
          supportsVision: true,
          supportsThinking: false,
          contextWindow: 128000,
          modelFamily: 'llama',
          aliases: ['llama3.2:8b'],
          description: 'Test model',
          useCases: ['chat', 'tools'],
        );

        expect(caps.supportsToolCalling, true);
        expect(caps.supportsVision, true);
        expect(caps.supportsThinking, false);
        expect(caps.contextWindow, 128000);
        expect(caps.modelFamily, 'llama');
        expect(caps.aliases, ['llama3.2:8b']);
        expect(caps.description, 'Test model');
        expect(caps.useCases, ['chat', 'tools']);
      });

      test('aliases defaults to empty list', () {
        final caps = ModelCapabilities(
          supportsToolCalling: false,
          supportsVision: false,
          supportsThinking: false,
          contextWindow: 8192,
        );

        expect(caps.aliases, []);
      });

      test('optional fields default to null', () {
        final caps = ModelCapabilities(
          supportsToolCalling: false,
          supportsVision: false,
          supportsThinking: false,
          contextWindow: 8192,
        );

        expect(caps.modelFamily, isNull);
        expect(caps.description, isNull);
        expect(caps.useCases, isNull);
      });
    });

    group('Aliases and getters', () {
      test('supportsTools getter returns supportsToolCalling value', () {
        final caps = ModelCapabilities(
          supportsToolCalling: true,
          supportsVision: false,
          supportsThinking: false,
          contextWindow: 8192,
        );

        expect(caps.supportsTools, true);
      });

      test('contextLength getter returns contextWindow value', () {
        final caps = ModelCapabilities(
          supportsToolCalling: false,
          supportsVision: false,
          supportsThinking: false,
          contextWindow: 128000,
        );

        expect(caps.contextLength, 128000);
      });

      test('family getter returns modelFamily when set', () {
        final caps = ModelCapabilities(
          supportsToolCalling: false,
          supportsVision: false,
          supportsThinking: false,
          contextWindow: 8192,
          modelFamily: 'qwen',
        );

        expect(caps.family, 'qwen');
      });

      test('family getter returns "unknown" when modelFamily is null', () {
        final caps = ModelCapabilities(
          supportsToolCalling: false,
          supportsVision: false,
          supportsThinking: false,
          contextWindow: 8192,
        );

        expect(caps.family, 'unknown');
      });
    });

    group('toString', () {
      test('includes features when available', () {
        final caps = ModelCapabilities(
          supportsToolCalling: true,
          supportsVision: true,
          supportsThinking: false,
          contextWindow: 128000,
        );
        final str = caps.toString();

        expect(str, contains('tools'));
        expect(str, contains('vision'));
      });

      test('formats context window in thousands', () {
        final caps = ModelCapabilities(
          supportsToolCalling: false,
          supportsVision: false,
          supportsThinking: false,
          contextWindow: 128000,
        );
        final str = caps.toString();

        expect(str, contains('128k'));
      });

      test('shows correct context for 8k window', () {
        final caps = ModelCapabilities(
          supportsToolCalling: false,
          supportsVision: false,
          supportsThinking: false,
          contextWindow: 8192,
        );
        final str = caps.toString();

        expect(str, contains('8k'));
      });
    });
  });

  group('ModelRegistry', () {
    group('getCapabilities', () {
      test('returns capabilities for exact model name', () {
        final caps = ModelRegistry.getCapabilities('llama3.1');

        expect(caps, isNotNull);
        expect(caps!.modelFamily, 'llama');
        expect(caps.supportsToolCalling, true);
      });

      test('handles model names with tags by normalizing', () {
        final caps1 = ModelRegistry.getCapabilities('llama3.1:8b');
        final caps2 = ModelRegistry.getCapabilities('llama3.1:70b');

        expect(caps1, isNotNull);
        expect(caps2, isNotNull);
        expect(caps1!.modelFamily, caps2!.modelFamily);
      });

      test('returns null for unknown model', () {
        final caps = ModelRegistry.getCapabilities('unknown_model_xyz');

        expect(caps, isNull);
      });

      test('finds capabilities by alias', () {
        final caps = ModelRegistry.getCapabilities('llama3.2:vision');

        expect(caps, isNotNull);
        expect(caps!.supportsVision, true);
      });

      test('returns non-null for qwen models', () {
        final caps = ModelRegistry.getCapabilities('qwen2.5');

        expect(caps, isNotNull);
        expect(caps!.modelFamily, 'qwen');
      });

      test('returns non-null for deepseek models', () {
        final caps = ModelRegistry.getCapabilities('deepseek-v3');

        expect(caps, isNotNull);
        expect(caps!.supportsThinking, true);
      });
    });

    group('findModelsByCapability', () {
      test('finds models supporting tool calling', () {
        final models = ModelRegistry.findModelsByCapability(
          supportsToolCalling: true,
        );

        expect(models, isNotEmpty);
        expect(models.length, greaterThan(10));
      });

      test('finds models supporting vision', () {
        final models = ModelRegistry.findModelsByCapability(
          supportsVision: true,
        );

        expect(models, isNotEmpty);
        expect(models, contains('llama3.2'));
      });

      test('finds models supporting thinking', () {
        final models = ModelRegistry.findModelsByCapability(
          supportsThinking: true,
        );

        expect(models, isNotEmpty);
        expect(models, contains('deepseek-v3'));
      });

      test('finds models with minimum context window', () {
        final models = ModelRegistry.findModelsByCapability(
          minContextWindow: 100000,
        );

        expect(models, isNotEmpty);
        // Most modern models should have 128k context
        expect(
          models.where((m) {
            final caps = ModelRegistry.getCapabilities(m);
            return caps!.contextWindow >= 100000;
          }).length,
          equals(models.length),
        );
      });

      test('finds models by family', () {
        final models = ModelRegistry.findModelsByCapability(
          modelFamily: 'llama',
        );

        expect(models, isNotEmpty);
        expect(models, contains('llama3.1'));
        expect(models, contains('llama3.2'));
      });

      test('combines multiple capability filters', () {
        final models = ModelRegistry.findModelsByCapability(
          supportsToolCalling: true,
          supportsVision: true,
          modelFamily: 'mistral',
        );

        // Should find pixtral (mistral's vision model)
        expect(models, contains('pixtral'));
      });

      test('returns empty list for impossible combination', () {
        final models = ModelRegistry.findModelsByCapability(
          supportsVision: true,
          modelFamily: 'deepseek',
        );

        // DeepSeek doesn't have vision models in registry
        expect(models, isEmpty);
      });
    });

    group('getAllModelNames', () {
      test('returns non-empty list of model names', () {
        final names = ModelRegistry.getAllModelNames();

        expect(names, isNotEmpty);
        expect(names.length, greaterThan(20));
      });

      test('includes well-known models', () {
        final names = ModelRegistry.getAllModelNames();

        expect(names, contains('llama3.1'));
        expect(names, contains('llama3.2'));
        expect(names, contains('qwen2.5'));
        expect(names, contains('deepseek-v3'));
        expect(names, contains('mistral'));
      });
    });

    group('getAllModelFamilies', () {
      test('returns sorted list of model families', () {
        final families = ModelRegistry.getAllModelFamilies();

        expect(families, isNotEmpty);
        expect(families, contains('llama'));
        expect(families, contains('qwen'));
        expect(families, contains('mistral'));
        // Check that list is sorted
        final isSorted = families
            .asMap()
            .entries
            .every((entry) {
              if (entry.key == families.length - 1) return true;
              return entry.value.compareTo(families[entry.key + 1]) <= 0;
            });
        expect(isSorted, true);
      });

      test('no duplicate families', () {
        final families = ModelRegistry.getAllModelFamilies();
        final unique = {...families};

        expect(families.length, unique.length);
      });
    });

    group('Convenience methods', () {
      test('supportsToolCalling returns true for llama3.1', () {
        expect(ModelRegistry.supportsToolCalling('llama3.1'), true);
      });

      test('supportsToolCalling returns false for unknown model', () {
        expect(ModelRegistry.supportsToolCalling('unknown_model'), false);
      });

      test('supportsVision returns true for llama3.2', () {
        expect(ModelRegistry.supportsVision('llama3.2'), true);
      });

      test('supportsVision returns false for llama3.1', () {
        expect(ModelRegistry.supportsVision('llama3.1'), false);
      });

      test('supportsThinking returns true for deepseek-v3', () {
        expect(ModelRegistry.supportsThinking('deepseek-v3'), true);
      });

      test('supportsThinking returns false for llama3.1', () {
        expect(ModelRegistry.supportsThinking('llama3.1'), false);
      });
    });

    group('Edge cases', () {
      test('handles empty string model name', () {
        final caps = ModelRegistry.getCapabilities('');

        expect(caps, isNull);
      });

      test('handles model name with multiple colons', () {
        final caps = ModelRegistry.getCapabilities('llama3.1:8b:latest');

        expect(caps, isNotNull);
        expect(caps!.modelFamily, 'llama');
      });

      test('case sensitive model lookups', () {
        final caps1 = ModelRegistry.getCapabilities('llama3.1');
        final caps2 = ModelRegistry.getCapabilities('LLAMA3.1');

        expect(caps1, isNotNull);
        expect(caps2, isNull); // Registry is case-sensitive
      });

      test('handles model names with special characters', () {
        final caps = ModelRegistry.getCapabilities('deepseek-v3');

        expect(caps, isNotNull);
      });
    });

    group('Model registry consistency', () {
      test('every capability with modelFamily has non-null family', () {
        for (final model in ModelRegistry.getAllModelNames()) {
          final caps = ModelRegistry.getCapabilities(model);
          expect(caps, isNotNull);
          expect(caps!.family, isNotEmpty);
        }
      });

      test('no model capability has both null and empty aliases', () {
        for (final model in ModelRegistry.getAllModelNames()) {
          final caps = ModelRegistry.getCapabilities(model);
          expect(caps!.aliases, isNotNull);
        }
      });

      test('all aliases are findable in registry', () {
        for (final model in ModelRegistry.getAllModelNames()) {
          final caps = ModelRegistry.getCapabilities(model);
          for (final alias in caps!.aliases) {
            final aliasCaps = ModelRegistry.getCapabilities(alias);
            expect(aliasCaps, isNotNull);
            expect(aliasCaps!.modelFamily, caps.modelFamily);
          }
        }
      });
    });
  });
}
