import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Model Providers
          _SectionHeader(title: l10n.general),
          _SettingsTile(
            icon: Icons.cloud_outlined,
            title: l10n.modelProviders,
            subtitle: 'OpenAI, Claude, Gemini, DeepSeek...',
            onTap: () => context.push('/settings/providers'),
          ),
          _SettingsTile(
            icon: Icons.hub_outlined,
            title: l10n.mcpServers,
            subtitle: 'Model Context Protocol',
            onTap: () {
              // TODO: MCP settings
            },
          ),
          _SettingsTile(
            icon: Icons.storage_outlined,
            title: l10n.difyIntegration,
            subtitle: 'RAG & Knowledge Base',
            onTap: () {
              // TODO: Dify settings
            },
          ),

          const Divider(height: 32),

          // Plugins
          _SectionHeader(title: l10n.plugins),
          _SettingsTile(
            icon: Icons.extension_outlined,
            title: l10n.pluginStore,
            subtitle: 'Browse and install plugins',
            onTap: () {
              // TODO: Plugin store
            },
          ),
          _SettingsTile(
            icon: Icons.widgets_outlined,
            title: l10n.installedPlugins,
            subtitle: 'Manage installed plugins',
            onTap: () {
              // TODO: Installed plugins management
            },
          ),

          const Divider(height: 32),

          // App Settings
          _SectionHeader(title: l10n.advanced),
          _SettingsTile(
            icon: Icons.security_outlined,
            title: l10n.permissions,
            subtitle: 'Camera, Microphone, Location...',
            onTap: () {
              // TODO: Permission settings
            },
          ),
          _SettingsTile(
            icon: Icons.language,
            title: l10n.language,
            subtitle: '中文 / English',
            onTap: () {
              // TODO: Language settings
            },
          ),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: l10n.theme,
            subtitle: l10n.systemMode,
            onTap: () {
              // TODO: Theme settings
            },
          ),

          const Divider(height: 32),

          _SettingsTile(
            icon: Icons.info_outlined,
            title: l10n.about,
            subtitle: '${l10n.version} 1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'QnQ',
                applicationVersion: '1.0.0',
                applicationIcon: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: const Text('Q', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                children: [
                  const Text('AI Agent App with multi-provider LLM, MCP, RAG, workflow & plugin system.'),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
