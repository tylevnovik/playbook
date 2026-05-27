import 'package:flutter/material.dart';
import '../../../../domain/entities/world_book.dart';

class EntryCard extends StatelessWidget {
  final WorldBookEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onToggleEnabled;

  const EntryCard({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: entry.enabled ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
            Switch(
              value: entry.enabled,
              onChanged: onToggleEnabled,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.category,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Priority: ${entry.priority}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: entry.keywords
                  .map((k) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          k,
                          style: theme.textTheme.labelSmall,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  entry.content,
                  style: theme.textTheme.bodyMedium,
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      onPressed: onEdit,
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: Icon(Icons.delete, size: 18, color: theme.colorScheme.error),
                      label: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
