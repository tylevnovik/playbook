import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';

class DataSection extends StatelessWidget {
  final Map<String, String> values;
  final Function(String, String) onUpdateSetting;
  final VoidCallback onClearAllData;
  final VoidCallback onExportData;
  final VoidCallback onImportData;

  const DataSection({
    super.key,
    required this.values,
    required this.onUpdateSetting,
    required this.onClearAllData,
    required this.onExportData,
    required this.onImportData,
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
              loc.get('profileDataTitle'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Username field
            TextFormField(
              key: ValueKey(
                '${AppConstants.keyUsername}_${values[AppConstants.keyUsername] ?? ''}',
              ),
              initialValue: values[AppConstants.keyUsername],
              decoration: InputDecoration(
                labelText: loc.get('profileName'),
                hintText: loc.get('profileNameHint'),
              ),
              onChanged: (val) =>
                  onUpdateSetting(AppConstants.keyUsername, val),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: ValueKey(
                '${AppConstants.keyUserDescription}_${values[AppConstants.keyUserDescription] ?? ''}',
              ),
              initialValue: values[AppConstants.keyUserDescription],
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '玩家设定',
                hintText: '描述你在聊天中扮演的玩家角色的背景、身份或性格...',
              ),
              onChanged: (val) =>
                  onUpdateSetting(AppConstants.keyUserDescription, val),
            ),
            const SizedBox(height: 24),

            // Data actions
            Text(
              loc.get('clearData'),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: Text(loc.get('exportBackup')),
                    onPressed: onExportData,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload),
                    label: Text(loc.get('importBackup')),
                    onPressed: onImportData,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(
                  Icons.delete_forever,
                  color: theme.colorScheme.error,
                ),
                label: Text(
                  loc.get('clearData'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onPressed: onClearAllData,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
