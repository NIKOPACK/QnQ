import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qnq/gen/l10n/app_localizations.dart';
import 'package:qnq/data/models/provider_config_model.dart';
import 'package:qnq/providers/provider_config_providers.dart';
import 'package:qnq/providers/service_providers.dart';
import 'package:uuid/uuid.dart';

class ProviderFormScreen extends ConsumerStatefulWidget {
  final String? providerUid;

  const ProviderFormScreen({super.key, this.providerUid});

  @override
  ConsumerState<ProviderFormScreen> createState() => _ProviderFormScreenState();
}

class _ProviderFormScreenState extends ConsumerState<ProviderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _orgIdController = TextEditingController();
  final _deploymentIdController = TextEditingController();

  ProviderTypeEnum _providerType = ProviderTypeEnum.openai;
  bool _isEditing = false;
  bool _isTesting = false;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    if (widget.providerUid != null) {
      _isEditing = true;
      _loadProvider();
    } else {
      _baseUrlController.text = 'https://api.openai.com/v1';
    }
  }

  Future<void> _loadProvider() async {
    final provider = await ref
        .read(providerConfigRepositoryProvider)
        .getByUid(widget.providerUid!);
    if (provider != null && mounted) {
      setState(() {
        _nameController.text = provider.name;
        _baseUrlController.text = provider.baseUrl;
        _apiKeyController.text = provider.apiKey;
        _orgIdController.text = provider.organizationId ?? '';
        _deploymentIdController.text = provider.deploymentId ?? '';
        _providerType = provider.providerType;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _orgIdController.dispose();
    _deploymentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '${l10n.edit} Provider' : l10n.addProvider),
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
            // Provider Type
            DropdownButtonFormField<ProviderTypeEnum>(
              initialValue: _providerType,
              decoration: InputDecoration(
                labelText: l10n.providerType,
                prefixIcon: const Icon(Icons.category),
              ),
              items: ProviderTypeEnum.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_typeLabel(type, l10n)),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _providerType = v!;
                  _baseUrlController.text = _defaultBaseUrl(v);
                });
              },
            ),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.providerName,
                prefixIcon: const Icon(Icons.text_fields),
                hintText: 'My OpenAI',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Base URL
            TextFormField(
              controller: _baseUrlController,
              decoration: InputDecoration(
                labelText: l10n.baseUrl,
                prefixIcon: const Icon(Icons.link),
                hintText: 'https://api.openai.com/v1',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final uri = Uri.tryParse(v);
                if (uri == null || !uri.hasScheme) return 'Invalid URL';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // API Key
            TextFormField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: l10n.apiKey,
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                ),
              ),
              obscureText: _obscureApiKey,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Organization ID (OpenAI/Azure)
            if (_providerType == ProviderTypeEnum.openai ||
                _providerType == ProviderTypeEnum.azure)
              TextFormField(
                controller: _orgIdController,
                decoration: InputDecoration(
                  labelText: 'Organization ID (optional)',
                  prefixIcon: const Icon(Icons.business),
                ),
              ),
            if (_providerType == ProviderTypeEnum.azure) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _deploymentIdController,
                decoration: InputDecoration(
                  labelText: 'Deployment ID',
                  prefixIcon: const Icon(Icons.cloud_queue),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Test Connection
            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering),
              label: Text(l10n.testConnection),
            ),

            const SizedBox(height: 16),

            // Preset providers quick setup
            if (!_isEditing) ...[
              const Divider(height: 32),
              Text('Quick Setup', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickSetupChip(
                    label: 'DeepSeek',
                    onTap: () => _quickSetup('DeepSeek', 'https://api.deepseek.com/v1', ProviderTypeEnum.custom),
                  ),
                  _QuickSetupChip(
                    label: 'Qwen',
                    onTap: () => _quickSetup('Qwen', 'https://dashscope.aliyuncs.com/compatible-mode/v1', ProviderTypeEnum.custom),
                  ),
                  _QuickSetupChip(
                    label: 'GLM',
                    onTap: () => _quickSetup('GLM', 'https://open.bigmodel.cn/api/paas/v4', ProviderTypeEnum.custom),
                  ),
                  _QuickSetupChip(
                    label: 'MiniMax',
                    onTap: () => _quickSetup('MiniMax', 'https://api.minimax.chat/v1', ProviderTypeEnum.custom),
                  ),
                  _QuickSetupChip(
                    label: 'OpenAI',
                    onTap: () => _quickSetup('OpenAI', 'https://api.openai.com/v1', ProviderTypeEnum.openai),
                  ),
                  _QuickSetupChip(
                    label: 'Claude',
                    onTap: () => _quickSetup('Claude', 'https://api.anthropic.com', ProviderTypeEnum.anthropic),
                  ),
                  _QuickSetupChip(
                    label: 'Gemini',
                    onTap: () => _quickSetup('Gemini', 'https://generativelanguage.googleapis.com', ProviderTypeEnum.gemini),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _quickSetup(String name, String baseUrl, ProviderTypeEnum type) {
    setState(() {
      _nameController.text = name;
      _baseUrlController.text = baseUrl;
      _providerType = type;
    });
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    // Create temporary provider config to test
    final config = ProviderConfig()
      ..uid = 'test_temp'
      ..name = _nameController.text
      ..baseUrl = _baseUrlController.text
      ..apiKey = _apiKeyController.text
      ..providerType = _providerType;

    ref.read(llmServiceProvider).registerProvider(config);

    try {
      final success = await ref.read(llmServiceProvider).testProvider('test_temp');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? l10n.connectionSuccess : l10n.connectionFailed),
            backgroundColor: success ? Colors.green : Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      ref.read(llmServiceProvider).removeProvider('test_temp');
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final config = ProviderConfig()
      ..uid = widget.providerUid ?? const Uuid().v4()
      ..name = _nameController.text.trim()
      ..baseUrl = _baseUrlController.text.trim()
      ..apiKey = _apiKeyController.text.trim()
      ..providerType = _providerType
      ..organizationId = _orgIdController.text.trim().isEmpty ? null : _orgIdController.text.trim()
      ..deploymentId = _deploymentIdController.text.trim().isEmpty ? null : _deploymentIdController.text.trim()
      ..isEnabled = true;

    await ref.read(providerConfigsProvider.notifier).save(config);
    if (mounted) context.pop();
  }

  String _typeLabel(ProviderTypeEnum type, AppLocalizations l10n) {
    switch (type) {
      case ProviderTypeEnum.openai:
        return l10n.openai;
      case ProviderTypeEnum.anthropic:
        return l10n.anthropic;
      case ProviderTypeEnum.gemini:
        return l10n.gemini;
      case ProviderTypeEnum.azure:
        return l10n.azure;
      case ProviderTypeEnum.custom:
        return l10n.custom;
    }
  }

  String _defaultBaseUrl(ProviderTypeEnum type) {
    switch (type) {
      case ProviderTypeEnum.openai:
        return 'https://api.openai.com/v1';
      case ProviderTypeEnum.anthropic:
        return 'https://api.anthropic.com';
      case ProviderTypeEnum.gemini:
        return 'https://generativelanguage.googleapis.com';
      case ProviderTypeEnum.azure:
        return '';
      case ProviderTypeEnum.custom:
        return '';
    }
  }
}

class _QuickSetupChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickSetupChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}
