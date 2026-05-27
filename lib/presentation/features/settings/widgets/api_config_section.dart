import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
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
    final loc = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.get('apiConfigTitle'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Provider selection
            DropdownButtonFormField<LlmProviderType>(
              initialValue: defaultProvider,
              decoration: InputDecoration(
                labelText: loc.get('defaultProvider'),
              ),
              items: LlmProviderType.values
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.name.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) onUpdateProvider(val);
              },
            ),
            const SizedBox(height: 24),

            // OpenAI config
            Text(loc.get('openaiConfig'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey(
                '${AppConstants.keyOpenaiApiKey}_${values[AppConstants.keyOpenaiApiKey] ?? ''}',
              ),
              initialValue: values[AppConstants.keyOpenaiApiKey],
              decoration: InputDecoration(labelText: loc.get('apiKey')),
              obscureText: true,
              onChanged: (val) =>
                  onUpdateSetting(AppConstants.keyOpenaiApiKey, val),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey(
                '${AppConstants.keyOpenaiBaseUrl}_${values[AppConstants.keyOpenaiBaseUrl] ?? ''}',
              ),
              initialValue: values[AppConstants.keyOpenaiBaseUrl],
              decoration: InputDecoration(
                labelText: loc.get('baseUrlOptional'),
              ),
              onChanged: (val) =>
                  onUpdateSetting(AppConstants.keyOpenaiBaseUrl, val),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey(
                '${AppConstants.keyOpenaiModel}_${values[AppConstants.keyOpenaiModel] ?? ''}',
              ),
              initialValue: values[AppConstants.keyOpenaiModel],
              decoration: InputDecoration(labelText: loc.get('modelName')),
              onChanged: (val) =>
                  onUpdateSetting(AppConstants.keyOpenaiModel, val),
            ),
            const SizedBox(height: 24),

            // Anthropic config
            Text(loc.get('anthropicConfig'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey(
                '${AppConstants.keyAnthropicApiKey}_${values[AppConstants.keyAnthropicApiKey] ?? ''}',
              ),
              initialValue: values[AppConstants.keyAnthropicApiKey],
              decoration: InputDecoration(labelText: loc.get('apiKey')),
              obscureText: true,
              onChanged: (val) =>
                  onUpdateSetting(AppConstants.keyAnthropicApiKey, val),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey(
                '${AppConstants.keyAnthropicModel}_${values[AppConstants.keyAnthropicModel] ?? ''}',
              ),
              initialValue: values[AppConstants.keyAnthropicModel],
              decoration: InputDecoration(labelText: loc.get('modelName')),
              onChanged: (val) =>
                  onUpdateSetting(AppConstants.keyAnthropicModel, val),
            ),
            const SizedBox(height: 24),

            // Gemini config
            Text(loc.get('geminiConfig'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey(
                '${AppConstants.keyGeminiApiKey}_${values[AppConstants.keyGeminiApiKey] ?? ''}',
              ),
              initialValue: values[AppConstants.keyGeminiApiKey],
              decoration: InputDecoration(labelText: loc.get('apiKey')),
              obscureText: true,
              onChanged: (val) =>
                  onUpdateSetting(AppConstants.keyGeminiApiKey, val),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey(
                '${AppConstants.keyGeminiModel}_${values[AppConstants.keyGeminiModel] ?? ''}',
              ),
              initialValue: values[AppConstants.keyGeminiModel],
              decoration: InputDecoration(labelText: loc.get('modelName')),
              onChanged: (val) =>
                  onUpdateSetting(AppConstants.keyGeminiModel, val),
            ),
          ],
        ),
      ),
    );
  }
}
