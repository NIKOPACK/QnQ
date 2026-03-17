import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qnq/data/models/agent_model.dart';
import 'package:qnq/providers/service_providers.dart';

final agentsProvider =
    AsyncNotifierProvider<AgentsNotifier, List<Agent>>(AgentsNotifier.new);

class AgentsNotifier extends AsyncNotifier<List<Agent>> {
  @override
  Future<List<Agent>> build() async {
    return ref.read(agentRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(agentRepositoryProvider).getAll(),
    );
  }

  Future<void> save(Agent agent) async {
    await ref.read(agentRepositoryProvider).save(agent);
    await refresh();
  }

  Future<void> delete(String uid) async {
    // Also delete all conversations for this agent
    await ref.read(conversationRepositoryProvider).deleteAllByAgentUid(uid);
    await ref.read(agentRepositoryProvider).delete(uid);
    await refresh();
  }

  Future<List<Agent>> search(String query) {
    return ref.read(agentRepositoryProvider).search(query);
  }
}

// Filtered agent providers
final pinnedAgentsProvider = FutureProvider<List<Agent>>((ref) async {
  final agents = await ref.watch(agentsProvider.future);
  return agents.where((a) => a.isPinned).toList();
});

final agentsByCategoryProvider =
    FutureProvider.family<List<Agent>, String>((ref, category) async {
  final agents = await ref.watch(agentsProvider.future);
  if (category == 'all') return agents;
  return agents.where((a) => a.category == category).toList();
});
