import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/file_saver/file_saver.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/datasources/local/database_service.dart';
import '../../../data/datasources/local/export_service.dart';
import '../../common/widgets/responsive_layout.dart';
import '../home/bloc/home_bloc.dart';
import 'bloc/settings_bloc.dart';
import 'widgets/api_config_section.dart';
import 'widgets/theme_section.dart';
import 'widgets/data_section.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _clearDatabase(BuildContext context) async {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.get('clearDataConfirmTitle')),
        content: Text(loc.get('clearDataConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.get('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              loc.get('delete'),
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = await DatabaseService.database;
        await db.transaction((txn) async {
          await txn.delete('characters');
          await txn.delete('chats');
          await txn.delete('messages');
          await txn.delete('world_books');
          await txn.delete('world_book_entries');
          await txn.delete('settings');
        });
        if (context.mounted) {
          context.read<HomeBloc>().add(LoadCharacters());
          context.read<SettingsBloc>().add(LoadSettings());
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(loc.get('clearSuccess'))));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${loc.get('clearDataFailed')}: $e')),
          );
        }
      }
    }
  }

  void _exportDatabase(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    try {
      final exportService = getIt<ExportService>();
      final json = await exportService.exportBackup();
      final fileName =
          'playbook_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      await saveFileContent(json, fileName);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.get('exportSuccess'))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.get('exportBackupFailed')}: $e')),
        );
      }
    }
  }

  void _importDatabase(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.get('importConfirmTitle')),
        content: Text(loc.get('importConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.get('importBackup')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String content;
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        throw Exception(loc.get('fileReadFailed'));
      }

      final exportService = getIt<ExportService>();
      await exportService.importBackup(content);

      if (context.mounted) {
        context.read<HomeBloc>().add(LoadCharacters());
        context.read<SettingsBloc>().add(LoadSettings());

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.get('importSuccess'))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.get('importBackupFailed')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final loc = AppLocalizations.of(context)!;
        final bloc = context.read<SettingsBloc>();

        if (state is SettingsLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is SettingsError) {
          return Scaffold(
            appBar: AppBar(title: Text(loc.get('settings'))),
            body: Center(
              child: Text(
                state.message,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          );
        }

        if (state is SettingsLoaded) {
          return ResponsiveLayout(
            mobileBody: _buildMobileBody(context, state, bloc, theme),
            desktopBody: _buildDesktopBody(context, state, bloc, theme),
          );
        }

        return Scaffold(body: Center(child: Text(loc.get('initialState'))));
      },
    );
  }

  Widget _buildMobileBody(
    BuildContext context,
    SettingsLoaded state,
    SettingsBloc bloc,
    ThemeData theme,
  ) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.get('settings'))),
      body: _buildSettingsList(context, state, bloc),
    );
  }

  Widget _buildDesktopBody(
    BuildContext context,
    SettingsLoaded state,
    SettingsBloc bloc,
    ThemeData theme,
  ) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.get('settings'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildSettingsList(context, state, bloc),
        ),
      ),
    );
  }

  Widget _buildSettingsList(
    BuildContext context,
    SettingsLoaded state,
    SettingsBloc bloc,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ApiConfigSection(
          providerProfiles: state.providerProfiles,
          defaultProviderProfileId: state.defaultProviderProfileId,
          diagnostics: state.diagnostics,
          onSaveProvider: (profile) {
            bloc.add(SaveProviderProfile(profile));
          },
          onAddProvider: (profile) {
            bloc.add(AddProviderProfile(profile));
          },
          onDeleteProvider: (id) {
            bloc.add(DeleteProviderProfile(id));
          },
          onSetDefaultProvider: (id) {
            bloc.add(SetDefaultProviderProfile(id));
          },
          onTestProvider: (profile) {
            bloc.add(TestProviderConnection(profile));
          },
          onDiscoverModels: (profile) {
            bloc.add(DiscoverProviderModels(profile));
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
          onExportData: () => _exportDatabase(context),
          onImportData: () => _importDatabase(context),
        ),
      ],
    );
  }
}
