import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qnq/gen/l10n/app_localizations.dart';
import 'package:qnq/data/models/agent_model.dart';
import 'package:qnq/providers/agent_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearching = false;

  static const _categories = ['all', 'general', 'coding', 'writing', 'analysis', 'workflow'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final agents = ref.watch(agentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchAgents,
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Text(l10n.appTitle, style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              )),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _categories.map((c) {
            return Tab(text: _categoryLabel(c, l10n));
          }).toList(),
        ),
      ),
      body: agents.when(
        data: (agentList) {
          if (agentList.isEmpty) {
            return _buildEmptyState(context, l10n);
          }
          return TabBarView(
            controller: _tabController,
            children: _categories.map((category) {
              final filtered = _filterAgents(agentList, category);
              return _buildAgentGrid(context, filtered);
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('${l10n.error}: $error')),
      ),
    );
  }

  List<Agent> _filterAgents(List<Agent> agents, String category) {
    var filtered = category == 'all'
        ? agents
        : agents.where((a) => a.category == category).toList();

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((a) =>
              a.name.toLowerCase().contains(query) ||
              a.description.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noAgents,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createFirstAgent,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/agent/create'),
            icon: const Icon(Icons.add),
            label: Text(l10n.newAgent),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentGrid(BuildContext context, List<Agent> agents) {
    if (agents.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noAgents,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: agents.length,
      itemBuilder: (context, index) => _AgentCard(agent: agents[index]),
    );
  }

  String _categoryLabel(String category, AppLocalizations l10n) {
    switch (category) {
      case 'all':
        return l10n.allAgents;
      case 'general':
        return l10n.general;
      case 'coding':
        return 'Coding';
      case 'writing':
        return 'Writing';
      case 'analysis':
        return 'Analysis';
      case 'workflow':
        return l10n.workflows;
      default:
        return category;
    }
  }
}

class _AgentCard extends StatelessWidget {
  final Agent agent;

  const _AgentCard({required this.agent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/chat/${agent.uid}'),
        onLongPress: () => _showAgentOptions(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  agent.avatarEmoji ?? agent.name.characters.first.toUpperCase(),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                agent.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Description
              Expanded(
                child: Text(
                  agent.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Footer
              Row(
                children: [
                  if (agent.agentType == AgentTypeEnum.workflow)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Workflow',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (agent.usageCount > 0)
                    Text(
                      '${agent.usageCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  if (agent.usageCount > 0)
                    Icon(Icons.chat_bubble_outline, size: 12, color: theme.colorScheme.outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAgentOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.edit),
              onTap: () {
                Navigator.pop(context);
                context.push('/agent/edit/${agent.uid}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: Text(l10n.newConversation),
              onTap: () {
                Navigator.pop(context);
                context.push('/chat/${agent.uid}');
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              title: Text(l10n.delete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                // TODO: show delete confirmation
              },
            ),
          ],
        ),
      ),
    );
  }
}
