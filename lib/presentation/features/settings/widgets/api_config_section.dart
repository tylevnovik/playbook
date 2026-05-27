import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../data/services/api_diagnostics_service.dart';
import '../../../../domain/entities/llm_config.dart';
import '../bloc/settings_bloc.dart';

class ApiConfigSection extends StatefulWidget {
  final List<LlmProviderProfile> providerProfiles;
  final String defaultProviderProfileId;
  final Map<String, ProviderDiagnostics> diagnostics;
  final Function(LlmProviderProfile) onSaveProvider;
  final Function(LlmProviderProfile) onAddProvider;
  final Function(String) onDeleteProvider;
  final Function(String) onSetDefaultProvider;
  final Function(LlmProviderProfile) onTestProvider;
  final Function(LlmProviderProfile) onDiscoverModels;

  const ApiConfigSection({
    super.key,
    required this.providerProfiles,
    required this.defaultProviderProfileId,
    required this.diagnostics,
    required this.onSaveProvider,
    required this.onAddProvider,
    required this.onDeleteProvider,
    required this.onSetDefaultProvider,
    required this.onTestProvider,
    required this.onDiscoverModels,
  });

  @override
  State<ApiConfigSection> createState() => _ApiConfigSectionState();
}

class _ApiConfigSectionState extends State<ApiConfigSection> {
  String? _editingProfileId;

  @override
  void didUpdateWidget(covariant ApiConfigSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_editingProfileId == null ||
        !widget.providerProfiles.any(
          (profile) => profile.id == _editingProfileId,
        )) {
      _editingProfileId = widget.defaultProviderProfileId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final profiles = widget.providerProfiles;
    final editingId = _editingProfileId ?? widget.defaultProviderProfileId;
    final editingProfile = profiles.firstWhere(
      (profile) => profile.id == editingId,
      orElse: () => profiles.first,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.get('apiConfigTitle'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(loc.get('addProvider')),
                  onPressed: _addProvider,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey('default_${widget.defaultProviderProfileId}'),
              initialValue: widget.defaultProviderProfileId,
              decoration: InputDecoration(
                labelText: loc.get('defaultProvider'),
              ),
              items: profiles.map((profile) {
                return DropdownMenuItem(
                  value: profile.id,
                  child: Text(profile.name),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                widget.onSetDefaultProvider(val);
                setState(() => _editingProfileId = val);
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profiles.map((profile) {
                final selected = profile.id == editingProfile.id;
                return ChoiceChip(
                  selected: selected,
                  label: Text(profile.name),
                  avatar: Icon(
                    profile.id == widget.defaultProviderProfileId
                        ? Icons.star
                        : _formatIcon(profile.providerType),
                    size: 16,
                  ),
                  onSelected: (_) {
                    setState(() => _editingProfileId = profile.id);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _ProviderEditor(
              key: ValueKey(editingProfile.id),
              profile: editingProfile,
              isDefault: editingProfile.id == widget.defaultProviderProfileId,
              diagnostics:
                  widget.diagnostics[editingProfile.id] ??
                  const ProviderDiagnostics(),
              onSaveProvider: widget.onSaveProvider,
              onDeleteProvider: editingProfile.isBuiltIn
                  ? null
                  : () => widget.onDeleteProvider(editingProfile.id),
              onSetDefault: () =>
                  widget.onSetDefaultProvider(editingProfile.id),
              onTestProvider: widget.onTestProvider,
              onDiscoverModels: widget.onDiscoverModels,
            ),
          ],
        ),
      ),
    );
  }

  void _addProvider() {
    final loc = AppLocalizations.of(context)!;
    final profile = LlmProviderProfile(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: loc.get('customProvider'),
      providerType: LlmProviderType.openai,
      apiKey: '',
      baseUrl: AppConstants.defaultOpenaiBaseUrl,
      model: AppConstants.defaultOpenaiModel,
      contextWindow: AppConstants.defaultOpenaiContextTokens,
      maxTokens: AppConstants.defaultOpenaiMaxResponseTokens,
    );
    widget.onAddProvider(profile);
    setState(() => _editingProfileId = profile.id);
  }

  IconData _formatIcon(LlmProviderType type) {
    return switch (type) {
      LlmProviderType.openai => Icons.hub_outlined,
      LlmProviderType.anthropic => Icons.psychology_outlined,
      LlmProviderType.gemini => Icons.auto_awesome_outlined,
    };
  }
}

class _ProviderEditor extends StatefulWidget {
  final LlmProviderProfile profile;
  final bool isDefault;
  final ProviderDiagnostics diagnostics;
  final Function(LlmProviderProfile) onSaveProvider;
  final VoidCallback? onDeleteProvider;
  final VoidCallback onSetDefault;
  final Function(LlmProviderProfile) onTestProvider;
  final Function(LlmProviderProfile) onDiscoverModels;

  const _ProviderEditor({
    super.key,
    required this.profile,
    required this.isDefault,
    required this.diagnostics,
    required this.onSaveProvider,
    required this.onDeleteProvider,
    required this.onSetDefault,
    required this.onTestProvider,
    required this.onDiscoverModels,
  });

  @override
  State<_ProviderEditor> createState() => _ProviderEditorState();
}

class _ProviderEditorState extends State<_ProviderEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _apiKeyController = TextEditingController(text: widget.profile.apiKey);
    _baseUrlController = TextEditingController(text: widget.profile.baseUrl);
    _modelController = TextEditingController(text: widget.profile.model);
  }

  @override
  void didUpdateWidget(covariant _ProviderEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_nameController, widget.profile.name);
    _syncController(_apiKeyController, widget.profile.apiKey);
    _syncController(_baseUrlController, widget.profile.baseUrl);
    _syncController(_modelController, widget.profile.model);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final profile = widget.profile;
    final diagnostics = widget.diagnostics;
    final onDeleteProvider = widget.onDeleteProvider;
    final defaultBaseUrl = ApiDiagnosticsService.fallbackBaseUrl(
      profile.providerType,
    );
    final defaultModel = ApiDiagnosticsService.fallbackModel(
      profile.providerType,
    );
    final contextTokens = ApiDiagnosticsService.fallbackContextTokens(
      profile.providerType,
    );
    final responseTokens = ApiDiagnosticsService.fallbackResponseTokens(
      profile.providerType,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    profile.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!widget.isDefault)
                  IconButton(
                    icon: const Icon(Icons.star_border),
                    tooltip: loc.get('setDefaultProvider'),
                    onPressed: widget.onSetDefault,
                  ),
                if (onDeleteProvider != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: loc.get('delete'),
                    onPressed: onDeleteProvider,
                  ),
              ],
            ),
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
              key: ValueKey('name_${profile.id}'),
              controller: _nameController,
              decoration: InputDecoration(labelText: loc.get('providerName')),
              onChanged: (val) =>
                  widget.onSaveProvider(_currentProfile().copyWith(name: val)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<LlmProviderType>(
              initialValue: profile.providerType,
              decoration: InputDecoration(labelText: loc.get('apiFormat')),
              items: LlmProviderType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_formatLabel(context, type)),
                );
              }).toList(),
              onChanged: (type) {
                if (type == null) return;
                final updated = _currentProfile().copyWith(
                  providerType: type,
                  baseUrl: ApiDiagnosticsService.fallbackBaseUrl(type),
                  model: ApiDiagnosticsService.fallbackModel(type),
                  contextWindow: ApiDiagnosticsService.fallbackContextTokens(
                    type,
                  ),
                  maxTokens: ApiDiagnosticsService.fallbackResponseTokens(type),
                );
                _syncController(_baseUrlController, updated.baseUrl);
                _syncController(_modelController, updated.model);
                widget.onSaveProvider(updated);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('key_${profile.id}'),
              controller: _apiKeyController,
              decoration: InputDecoration(labelText: loc.get('apiKey')),
              obscureText: true,
              onChanged: (val) => widget.onSaveProvider(
                _currentProfile().copyWith(apiKey: val),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('endpoint_${profile.id}'),
              controller: _baseUrlController,
              decoration: InputDecoration(labelText: loc.get('endpointUrl')),
              onChanged: (val) => widget.onSaveProvider(
                _currentProfile().copyWith(baseUrl: val),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('model_${profile.id}'),
              controller: _modelController,
              decoration: InputDecoration(labelText: loc.get('modelName')),
              onChanged: (val) =>
                  widget.onSaveProvider(_currentProfile().copyWith(model: val)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  ApiDiagnosticsService.fallbackModels(
                    profile.providerType,
                  ).map((model) {
                    return ActionChip(
                      label: Text(model),
                      tooltip: loc.get('applyModel'),
                      onPressed: () => _applyModel(model),
                    );
                  }).toList(),
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
                      : () => widget.onTestProvider(_currentProfile()),
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
                      : () => widget.onDiscoverModels(_currentProfile()),
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
              Text(
                loc.get('discoveredModels'),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: diagnostics.models.take(16).map((model) {
                  return ActionChip(
                    label: Text(model),
                    avatar: const Icon(Icons.check_circle_outline, size: 16),
                    tooltip: loc.get('applyModel'),
                    onPressed: () => _applyModel(model),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  LlmProviderProfile _currentProfile() {
    return widget.profile.copyWith(
      name: _nameController.text,
      apiKey: _apiKeyController.text,
      baseUrl: _baseUrlController.text,
      model: _modelController.text,
    );
  }

  void _applyModel(String model) {
    _syncController(_modelController, model);
    widget.onSaveProvider(_currentProfile().copyWith(model: model));
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  String _formatLabel(BuildContext context, LlmProviderType type) {
    final loc = AppLocalizations.of(context)!;
    return switch (type) {
      LlmProviderType.openai => loc.get('openaiCompatibleFormat'),
      LlmProviderType.anthropic => loc.get('anthropicCompatibleFormat'),
      LlmProviderType.gemini => loc.get('geminiCompatibleFormat'),
    };
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
