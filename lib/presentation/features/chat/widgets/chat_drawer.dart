import 'package:flutter/material.dart';

class ChatDrawer extends StatefulWidget {
  final double initialTemperature;
  final int initialMaxTokens;
  final String? initialSystemPrompt;
  final Function(double, int, String?) onSettingsChanged;

  const ChatDrawer({
    super.key,
    required this.initialTemperature,
    required this.initialMaxTokens,
    this.initialSystemPrompt,
    required this.onSettingsChanged,
  });

  @override
  State<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends State<ChatDrawer> {
  late double _temperature;
  late int _maxTokens;
  final _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _temperature = widget.initialTemperature;
    _maxTokens = widget.initialMaxTokens;
    _promptController.text = widget.initialSystemPrompt ?? '';
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _triggerChanged() {
    widget.onSettingsChanged(_temperature, _maxTokens, _promptController.text.trim().isEmpty ? null : _promptController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Session Configuration',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Temperature slider
            Text(
              'Temperature: ${_temperature.toStringAsFixed(1)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Slider(
              value: _temperature,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              label: _temperature.toStringAsFixed(1),
              onChanged: (val) {
                setState(() {
                  _temperature = val;
                });
                _triggerChanged();
              },
            ),
            Text(
              'Lower values are more focused/deterministic, higher values are more creative/random.',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            // Max Tokens
            Text(
              'Max Response Tokens: $_maxTokens',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _maxTokens.toDouble(),
                    min: 100,
                    max: 4000,
                    divisions: 39,
                    label: '$_maxTokens',
                    onChanged: (val) {
                      setState(() {
                        _maxTokens = val.toInt();
                      });
                      _triggerChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // System prompt override
            Text(
              'System Instruction Override',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'e.g. Speak like a pirate...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _triggerChanged(),
            ),
          ],
        ),
      ),
    );
  }
}
