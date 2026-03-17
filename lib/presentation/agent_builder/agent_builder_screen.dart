import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qnq/gen/l10n/app_localizations.dart';
import 'package:qnq/data/models/agent_model.dart';
import 'package:qnq/providers/agent_providers.dart';
import 'package:qnq/providers/provider_config_providers.dart';
import 'package:qnq/providers/service_providers.dart';
import 'package:uuid/uuid.dart';

class AgentBuilderScreen extends ConsumerStatefulWidget {
  final String? agentUid;

  const AgentBuilderScreen({super.key, this.agentUid});

  @override
  ConsumerState<AgentBuilderScreen> createState() => _AgentBuilderScreenState();
}

class _AgentBuilderScreenState extends ConsumerState<AgentBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _systemPromptController = TextEditingController();

  String? _selectedProviderUid;
  String? _selectedModel;
  double _temperature = 0.7;
  int _maxTokens = 4096;
  String _category = 'general';
  String? _avatarEmoji;
  List<String> _availableModels = [];
  bool _isEditing = false;

  static const _emojiOptions = ['🤖', '🧠', '💡', '🔮', '📝', '🎯', '🔧', '🌟', '🎨', '📊', '🔬', '🎭'];
  static const _categories = ['general', 'coding', 'writing', 'analysis'];

  @override
  void initState() {
    super.initState();
    if (widget.agentUid != null) {
      _isEditing = true;
      _loadAgent();
    }
    _avatarEmoji = _emojiOptions[0];
  }

  Future<void> _loadAgent() async {
    final agent = await ref.read(agentRepositoryProvider).getByUid(widget.agentUid!);
    if (agent != null && mounted) {
      setState(() {
        _nameController.text = agent.name;
        _descriptionController.text = agent.description;
        _systemPromptController.text = agent.systemPrompt;
        _selectedProviderUid = agent.providerUid;
        _selectedModel = agent.modelName;
        _temperature = agent.temperature;
        _maxTokens = agent.maxTokens;
        _category = agent.category;
        _avatarEmoji = agent.avatarEmoji ?? _emojiOptions[0];
      });
      if (agent.providerUid != null) {
        _loadModels(agent.providerUid!);
      }
    }
  }

  Future<void> _loadModels(String providerUid) async {
    final models = await ref.read(llmServiceProvider).listModels(providerUid);
    if (mounted) {
      setState(() => _availableModels = models);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final providers = ref.watch(providerConfigsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.edit : l10n.newAgent),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(l10n.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar emoji picker
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showEmojiPicker,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(_avatarEmoji ?? '🤖', style: const TextStyle(fontSize: 36)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Tap to change', style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.agentName,
                prefixIcon: const Icon(Icons.text_fields),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.agentDescription,
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(Icons.category),
              ),
              items: _categories.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 24),

            // Model Provider
            Text(l10n.selectModel, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),

            providers.when(
              data: (providerList) {
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProviderUid,
                      decoration: InputDecoration(
                        labelText: l10n.modelProviders,
                        prefixIcon: const Icon(Icons.cloud),
                      ),
                      items: providerList.map((p) {
                        return DropdownMenuItem(value: p.uid, child: Text(p.name));
                      }).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedProviderUid = v;
                          _selectedModel = null;
                          _availableModels = [];
                        });
                        if (v != null) _loadModels(v);
                      },
                      validator: (v) => (v == null) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    if (_availableModels.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedModel,
                        decoration: InputDecoration(
                          labelText: l10n.selectModel,
                          prefixIcon: const Icon(Icons.model_training),
                        ),
                        items: _availableModels.map((m) {
                          return DropdownMenuItem(value: m, child: Text(m));
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedModel = v),
                      ),
                    if (_selectedProviderUid != null && _availableModels.isEmpty)
                      TextFormField(
                        initialValue: _selectedModel,
                        decoration: InputDecoration(
                          labelText: 'Model Name (type manually)',
                          prefixIcon: const Icon(Icons.model_training),
                        ),
                        onChanged: (v) => _selectedModel = v,
                      ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),

            // System Prompt
            Text(l10n.systemPrompt, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _systemPromptController,
              decoration: InputDecoration(
                hintText: 'You are a helpful assistant...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 6,
              minLines: 3,
            ),
            const SizedBox(height: 24),

            // Parameters
            Text(l10n.advanced, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),

            // Temperature
            Row(
              children: [
                Text('${l10n.temperature}: ${_temperature.toStringAsFixed(2)}'),
                Expanded(
                  child: Slider(
                    value: _temperature,
                    min: 0,
                    max: 2,
                    divisions: 40,
                    onChanged: (v) => setState(() => _temperature = v),
                  ),
                ),
              ],
            ),

            // Max Tokens
            Row(
              children: [
                Text('${l10n.maxTokens}: $_maxTokens'),
                Expanded(
                  child: Slider(
                    value: _maxTokens.toDouble(),
                    min: 256,
                    max: 32768,
                    divisions: 64,
                    onChanged: (v) => setState(() => _maxTokens = v.toInt()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _emojiOptions.map((emoji) {
            return GestureDetector(
              onTap: () {
                setState(() => _avatarEmoji = emoji);
                Navigator.pop(context);
              },
              child: CircleAvatar(
                radius: 24,
                backgroundColor: _avatarEmoji == emoji
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final agent = Agent()
      ..uid = widget.agentUid ?? const Uuid().v4()
      ..name = _nameController.text.trim()
      ..description = _descriptionController.text.trim()
      ..avatarEmoji = _avatarEmoji
      ..agentType = AgentTypeEnum.chat
      ..providerUid = _selectedProviderUid
      ..modelName = _selectedModel
      ..systemPrompt = _systemPromptController.text.trim()
      ..temperature = _temperature
      ..maxTokens = _maxTokens
      ..category = _category;

    await ref.read(agentsProvider.notifier).save(agent);
    if (mounted) context.pop();
  }
}
