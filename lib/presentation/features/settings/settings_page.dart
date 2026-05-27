import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/di/injection.dart';
import '../../../../domain/repositories/settings_repository.dart';
import '../../../../data/datasources/local/database_service.dart';
import 'bloc/settings_bloc.dart';
import 'widgets/api_config_section.dart';
import 'widgets/theme_section.dart';
import 'widgets/data_section.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _clearDatabase(BuildContext context) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text('This will delete all characters, chats, messages, and settings. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.errorContainer),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: theme.colorScheme.onErrorContainer)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = await DatabaseService.database;
        // Delete all data in tables
        await db.transaction((txn) async {
          await txn.delete('characters');
          await txn.delete('chats');
          await txn.delete('messages');
          await txn.delete('world_books');
          await txn.delete('world_book_entries');
          await txn.delete('settings');
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All data cleared successfully.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear database: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsBloc(getIt<SettingsRepository>())..add(LoadSettings()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            final theme = Theme.of(context);
            final bloc = context.read<SettingsBloc>();

            if (state is SettingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SettingsError) {
              return Center(child: Text(state.message, style: TextStyle(color: theme.colorScheme.error)));
            }

            if (state is SettingsLoaded) {
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  ApiConfigSection(
                    values: state.values,
                    defaultProvider: state.defaultProvider,
                    onUpdateSetting: (key, val) {
                      bloc.add(UpdateStringSetting(key: key, value: val));
                    },
                    onUpdateProvider: (providerType) {
                      bloc.add(UpdateProviderSetting(providerType));
                    },
                  ),
                  const SizedBox(height: 16),
                  ThemeSection(
                    values: state.values,
                    onUpdateSetting: (key, val) {
                      bloc.add(UpdateStringSetting(key: key, value: val));
                    },
                  ),
                  const SizedBox(height: 16),
                  DataSection(
                    values: state.values,
                    onUpdateSetting: (key, val) {
                      bloc.add(UpdateStringSetting(key: key, value: val));
                    },
                    onClearAllData: () => _clearDatabase(context),
                  ),
                ],
              );
            }

            return const Center(child: Text('Initial State'));
          },
        ),
      ),
    );
  }
}
