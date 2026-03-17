import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qnq/data/models/provider_config_model.dart';
import 'package:qnq/providers/provider_config_providers.dart';

class ProviderListScreen extends ConsumerWidget {
  const ProviderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final providers = ref.watch(providerConfigsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.modelProviders),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/settings/providers/add'),
          ),
        ],
      ),
      body: providers.when(
        data: (providerList) {
          if (providerList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No providers configured', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => context.push('/settings/providers/add'),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addProvider),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providerList.length,
            itemBuilder: (context, index) {
              final provider = providerList[index];
              return _ProviderCard(provider: provider);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ProviderCard extends ConsumerWidget {
  final ProviderConfig provider;

  const _ProviderCard({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(
            _providerIcon(provider.providerType),
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(provider.name),
        subtitle: Text(
          provider.providerType.name.toUpperCase(),
          style: theme.textTheme.labelSmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: provider.isEnabled ? Colors.green : theme.colorScheme.outline,
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    context.push('/settings/providers/edit/${provider.uid}');
                  case 'test':
                    final success = await ref.read(providerConfigsProvider.notifier).testConnection(provider.uid);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? l10n.connectionSuccess : l10n.connectionFailed),
                          backgroundColor: success ? Colors.green : theme.colorScheme.error,
                        ),
                      );
                    }
                  case 'delete':
                    ref.read(providerConfigsProvider.notifier).delete(provider.uid);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                PopupMenuItem(value: 'test', child: Text(l10n.testConnection)),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(l10n.delete, style: TextStyle(color: theme.colorScheme.error)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _providerIcon(ProviderTypeEnum type) {
    switch (type) {
      case ProviderTypeEnum.openai:
        return Icons.auto_awesome;
      case ProviderTypeEnum.anthropic:
        return Icons.psychology;
      case ProviderTypeEnum.gemini:
        return Icons.diamond;
      case ProviderTypeEnum.azure:
        return Icons.cloud;
      case ProviderTypeEnum.custom:
        return Icons.settings_ethernet;
    }
  }
}
