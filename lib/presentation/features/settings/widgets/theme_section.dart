import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';

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
    final loc = AppLocalizations.of(context)!;
    final currentThemeMode = values[AppConstants.keyThemeMode] ?? 'system';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.get('themeTitle'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RadioGroup<String>(
              groupValue: currentThemeMode,
              onChanged: (val) {
                if (val != null) {
                  onUpdateSetting(AppConstants.keyThemeMode, val);
                }
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: Text(loc.get('themeSystem')),
                    value: 'system',
                  ),
                  RadioListTile<String>(
                    title: Text(loc.get('themeLight')),
                    value: 'light',
                  ),
                  RadioListTile<String>(
                    title: Text(loc.get('themeDark')),
                    value: 'dark',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              loc.get('language'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: values[AppConstants.keyLanguage]?.isEmpty == true
                  ? 'zh'
                  : (values[AppConstants.keyLanguage] ?? 'zh'),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'zh',
                  child: Text(loc.get('langChinese')),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(loc.get('langEnglish')),
                ),
              ],
              onChanged: (val) {
                if (val != null) onUpdateSetting(AppConstants.keyLanguage, val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
