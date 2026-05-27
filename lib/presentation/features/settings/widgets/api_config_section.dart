import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../data/services/api_diagnostics_service.dart';
import '../../../../domain/entities/llm_config.dart';
import '../bloc/settings_bloc.dart';

class ApiConfigSection extends StatelessWidget {
  final Map<String, String> values;
  final LlmProviderType defaultProvider;
  final Map<LlmProviderType, ProviderDiagnostics> diagnostics;
  final Function(String, String) onUpdateSetting;
  final Function(LlmProviderType) onUpdateProvider;
  final Function(LlmProviderType) onTestProvider;
  final Function(LlmProviderType) onDiscoverModels;

  const ApiConfigSection({
    super.key,
    required this.values,
    required this.defaultProvider,
    required this.diagnostics,
    required this.onUpdateSetting,
    required this.onUpdateProvider,
    required this.onTestProvider,
    required this.onDiscoverModels,
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
            _ProviderConfigFields(
              providerType: LlmProviderType.openai,
              title: loc.get('openaiConfig'),
              apiKeyKey: AppConstants.keyOpenaiApiKey,
              baseUrlKey: AppConstants.keyOpenaiBaseUrl,
              modelKey: AppConstants.keyOpenaiModel,
              values: values,
              diagnostics:
                  diagnostics[LlmProviderType.openai] ??
                  const ProviderDiagnostics(),
              onUpdateSetting: onUpdateSetting,
              onTestProvider: onTestProvider,
              onDiscoverModels: onDiscoverModels,
            ),
            const SizedBox(height: 24),
            _ProviderConfigFields(
              providerType: LlmProviderType.anthropic,
              title: loc.get('anthropicConfig'),
              apiKeyKey: AppConstants.keyAnthropicApiKey,
              baseUrlKey: AppConstants.keyAnthropicBaseUrl,
              modelKey: AppConstants.keyAnthropicModel,
              values: values,
              diagnostics:
                  diagnostics[LlmProviderType.anthropic] ??
                  const ProviderDiagnostics(),
              onUpdateSetting: onUpdateSetting,
              onTestProvider: onTestProvider,
              onDiscoverModels: onDiscoverModels,
            ),
            const SizedBox(height: 24),
            _ProviderConfigFields(
              providerType: LlmProviderType.gemini,
              title: loc.get('geminiConfig'),
              apiKeyKey: AppConstants.keyGeminiApiKey,
              baseUrlKey: AppConstants.keyGeminiBaseUrl,
              modelKey: AppConstants.keyGeminiModel,
              values: values,
              diagnostics:
                  diagnostics[LlmProviderType.gemini] ??
                  const ProviderDiagnostics(),
              onUpdateSetting: onUpdateSetting,
              onTestProvider: onTestProvider,
              onDiscoverModels: onDiscoverModels,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderConfigFields extends StatelessWidget {
  final LlmProviderType providerType;
  final String title;
  final String apiKeyKey;
  final String baseUrlKey;
  final String modelKey;
  final Map<String, String> values;
  final ProviderDiagnostics diagnostics;
  final Function(String, String) onUpdateSetting;
  final Function(LlmProviderType) onTestProvider;
  final Function(LlmProviderType) onDiscoverModels;

  const _ProviderConfigFields({
    required this.providerType,
    required this.title,
    required this.apiKeyKey,
    required this.baseUrlKey,
    required this.modelKey,
    required this.values,
    required this.diagnostics,
    required this.onUpdateSetting,
    required this.onTestProvider,
    required this.onDiscoverModels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final defaultBaseUrl = ApiDiagnosticsService.fallbackBaseUrl(providerType);
    final defaultModel = ApiDiagnosticsService.fallbackModel(providerType);
    final contextTokens = ApiDiagnosticsService.fallbackContextTokens(
      providerType,
    );
    final responseTokens = ApiDiagnosticsService.fallbackResponseTokens(
      providerType,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(
          '${loc.get('defaultEndpoint')}: $defaultBaseUrl\n'
          '${loc.get('defaultModel')}: $defaultModel · '
          '${loc.get('contextWindow')}: ${_formatTokens(contextTokens)} · '
          '${loc.get('responseTokens')}: ${_formatTokens(responseTokens)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: ValueKey('$apiKeyKey-${values[apiKeyKey] ?? ''}'),
          initialValue: values[apiKeyKey],
          decoration: InputDecoration(labelText: loc.get('apiKey')),
          obscureText: true,
          onChanged: (val) => onUpdateSetting(apiKeyKey, val),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey('$baseUrlKey-${values[baseUrlKey] ?? ''}'),
          initialValue: _valueOrDefault(values[baseUrlKey], defaultBaseUrl),
          decoration: InputDecoration(labelText: loc.get('endpointUrl')),
          onChanged: (val) => onUpdateSetting(baseUrlKey, val),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey('$modelKey-${values[modelKey] ?? ''}'),
          initialValue: _valueOrDefault(values[modelKey], defaultModel),
          decoration: InputDecoration(labelText: loc.get('modelName')),
          onChanged: (val) => onUpdateSetting(modelKey, val),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              icon: diagnostics.isTesting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering_outlined),
              label: Text(loc.get('testConnection')),
              onPressed: diagnostics.isTesting
                  ? null
                  : () => onTestProvider(providerType),
            ),
            OutlinedButton.icon(
              icon: diagnostics.isDiscovering
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.manage_search_outlined),
              label: Text(loc.get('discoverModels')),
              onPressed: diagnostics.isDiscovering
                  ? null
                  : () => onDiscoverModels(providerType),
            ),
          ],
        ),
        if (diagnostics.connectionMessage != null) ...[
          const SizedBox(height: 8),
          _StatusText(
            ok: diagnostics.connectionOk,
            message: diagnostics.connectionMessage!,
          ),
        ],
        if (diagnostics.discoveryMessage != null) ...[
          const SizedBox(height: 8),
          _StatusText(
            ok: diagnostics.discoveryOk,
            message:
                '${diagnostics.discoveryMessage!}'
                '${diagnostics.models.isEmpty ? '' : ' (${diagnostics.models.length})'}',
          ),
        ],
        if (diagnostics.models.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(loc.get('discoveredModels'), style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: diagnostics.models.take(12).map((model) {
              return ActionChip(
                label: Text(model),
                avatar: const Icon(Icons.check_circle_outline, size: 16),
                tooltip: loc.get('applyModel'),
                onPressed: () => onUpdateSetting(modelKey, model),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  String _valueOrDefault(String? value, String fallback) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  String _formatTokens(int tokens) {
    if (tokens >= 1000000) {
      final millions = tokens / 1000000;
      return '${millions.toStringAsFixed(millions == millions.roundToDouble() ? 0 : 1)}M';
    }
    if (tokens >= 1000) {
      final thousands = tokens / 1000;
      return '${thousands.toStringAsFixed(thousands == thousands.roundToDouble() ? 0 : 1)}K';
    }
    return tokens.toString();
  }
}

class _StatusText extends StatelessWidget {
  final bool? ok;
  final String message;

  const _StatusText({required this.ok, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ok == true
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    final icon = ok == true ? Icons.check_circle_outline : Icons.error_outline;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
