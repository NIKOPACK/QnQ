import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qnq/data/models/provider_config_model.dart';
import 'package:qnq/providers/service_providers.dart';

final providerConfigsProvider =
    AsyncNotifierProvider<ProviderConfigsNotifier, List<ProviderConfig>>(
  ProviderConfigsNotifier.new,
);

class ProviderConfigsNotifier extends AsyncNotifier<List<ProviderConfig>> {
  @override
  Future<List<ProviderConfig>> build() async {
    return ref.read(providerConfigRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(providerConfigRepositoryProvider).getAll(),
    );
  }

  Future<void> save(ProviderConfig config) async {
    await ref.read(providerConfigRepositoryProvider).save(config);
    // Register with LLM service
    ref.read(llmServiceProvider).registerProvider(config);
    await refresh();
  }

  Future<void> delete(String uid) async {
    await ref.read(providerConfigRepositoryProvider).delete(uid);
    ref.read(llmServiceProvider).removeProvider(uid);
    await refresh();
  }

  Future<bool> testConnection(String uid) async {
    return ref.read(llmServiceProvider).testProvider(uid);
  }
}
