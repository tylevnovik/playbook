import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/llm_config.dart';

class ApiConfigSection extends StatelessWidget {
  final Map<String, String> values;
  final LlmProviderType defaultProvider;
  final Function(String, String) onUpdateSetting;
  final Function(LlmProviderType) onUpdateProvider;

  const ApiConfigSection({
    super.key,
    required this.values,
    required this.defaultProvider,
    required this.onUpdateSetting,
    required this.onUpdateProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API Configuration',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Provider selection
            DropdownButtonFormField<LlmProviderType>(
              value: defaultProvider,
              decoration: const InputDecoration(labelText: 'Default LLM Provider'),
              items: LlmProviderType.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) onUpdateProvider(val);
              },
            ),
            const SizedBox(height: 24),

            // OpenAI config
            Text('OpenAI Settings', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: values[AppConstants.keyOpenaiApiKey],
              decoration: const InputDecoration(labelText: 'API Key'),
              obscureText: true,
              onChanged: (val) => onUpdateSetting(AppConstants.keyOpenaiApiKey, val),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: values[AppConstants.keyOpenaiBaseUrl],
              decoration: const InputDecoration(labelText: 'Base URL (Optional)'),
              onChanged: (val) => onUpdateSetting(AppConstants.keyOpenaiBaseUrl, val),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: values[AppConstants.keyOpenaiModel],
              decoration: const InputDecoration(labelText: 'Model Name'),
              onChanged: (val) => onUpdateSetting(AppConstants.keyOpenaiModel, val),
            ),
            const SizedBox(height: 24),

            // Anthropic config
            Text('Anthropic Settings', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: values[AppConstants.keyAnthropicApiKey],
              decoration: const InputDecoration(labelText: 'API Key'),
              obscureText: true,
              onChanged: (val) => onUpdateSetting(AppConstants.keyAnthropicApiKey, val),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: values[AppConstants.keyAnthropicModel],
              decoration: const InputDecoration(labelText: 'Model Name'),
              onChanged: (val) => onUpdateSetting(AppConstants.keyAnthropicModel, val),
            ),
            const SizedBox(height: 24),

            // Gemini config
            Text('Gemini Settings', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: values[AppConstants.keyGeminiApiKey],
              decoration: const InputDecoration(labelText: 'API Key'),
              obscureText: true,
              onChanged: (val) => onUpdateSetting(AppConstants.keyGeminiApiKey, val),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: values[AppConstants.keyGeminiModel],
              decoration: const InputDecoration(labelText: 'Model Name'),
              onChanged: (val) => onUpdateSetting(AppConstants.keyGeminiModel, val),
            ),
          ],
        ),
      ),
    );
  }
}
