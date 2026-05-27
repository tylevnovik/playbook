import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class ThemeSection extends StatelessWidget {
  final Map<String, String> values;
  final Function(String, String) onUpdateSetting;

  const ThemeSection({
    super.key,
    required this.values,
    required this.onUpdateSetting,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentThemeMode = values[AppConstants.keyThemeMode] ?? 'system';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Text('System Default'),
              value: 'system',
              groupValue: currentThemeMode,
              onChanged: (val) {
                if (val != null) onUpdateSetting(AppConstants.keyThemeMode, val);
              },
            ),
            RadioListTile<String>(
              title: const Text('Light Mode'),
              value: 'light',
              groupValue: currentThemeMode,
              onChanged: (val) {
                if (val != null) onUpdateSetting(AppConstants.keyThemeMode, val);
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark Mode'),
              value: 'dark',
              groupValue: currentThemeMode,
              onChanged: (val) {
                if (val != null) onUpdateSetting(AppConstants.keyThemeMode, val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
