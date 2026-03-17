import 'package:flutter/material.dart';
import 'package:qnq/gen/l10n/app_localizations.dart';

class PluginStoreScreen extends StatelessWidget {
  const PluginStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exploreTab),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.pluginStore,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Browse plugins, tools, and community agents',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            // Placeholder sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ExploreSection(
                    title: l10n.plugins,
                    icon: Icons.extension,
                    items: const ['Weather Tool', 'Web Search', 'File Manager', 'Calculator'],
                  ),
                  const SizedBox(height: 16),
                  _ExploreSection(
                    title: 'Tools',
                    icon: Icons.build,
                    items: const ['Image Generator', 'Code Interpreter', 'Data Analyzer'],
                  ),
                  const SizedBox(height: 16),
                  _ExploreSection(
                    title: l10n.agents,
                    icon: Icons.smart_toy,
                    items: const ['Writing Assistant', 'Code Review', 'Translator', 'Tutor'],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;

  const _ExploreSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 140,
                child: Card(
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 24, color: theme.colorScheme.primary),
                          const SizedBox(height: 8),
                          Text(
                            items[index],
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
