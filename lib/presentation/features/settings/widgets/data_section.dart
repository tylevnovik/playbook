import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class DataSection extends StatelessWidget {
  final Map<String, String> values;
  final Function(String, String) onUpdateSetting;
  final VoidCallback onClearAllData;

  const DataSection({
    super.key,
    required this.values,
    required this.onUpdateSetting,
    required this.onClearAllData,
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
              'Profile & Data Management',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Username field
            TextFormField(
              initialValue: values[AppConstants.keyUsername],
              decoration: const InputDecoration(
                labelText: 'User Profile Name',
                hintText: 'e.g. User',
              ),
              onChanged: (val) => onUpdateSetting(AppConstants.keyUsername, val),
            ),
            const SizedBox(height: 24),

            // Data actions
            ElevatedButton.icon(
              icon: Icon(Icons.delete_forever, color: theme.colorScheme.error),
              label: Text('Clear All Local Data', style: TextStyle(color: theme.colorScheme.error)),
              onPressed: onClearAllData,
            ),
          ],
        ),
      ),
    );
  }
}
