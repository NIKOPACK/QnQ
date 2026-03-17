/// Enum for LLM provider types
enum ProviderType {
  openai,
  anthropic,
  gemini,
  azure,
  custom;

  String get displayName {
    switch (this) {
      case ProviderType.openai:
        return 'OpenAI';
      case ProviderType.anthropic:
        return 'Anthropic';
      case ProviderType.gemini:
        return 'Google Gemini';
      case ProviderType.azure:
        return 'Azure OpenAI';
      case ProviderType.custom:
        return 'Custom (OpenAI Compatible)';
    }
  }

  String get defaultBaseUrl {
    switch (this) {
      case ProviderType.openai:
        return 'https://api.openai.com/v1';
      case ProviderType.anthropic:
        return 'https://api.anthropic.com';
      case ProviderType.gemini:
        return 'https://generativelanguage.googleapis.com';
      case ProviderType.azure:
        return '';
      case ProviderType.custom:
        return '';
    }
  }
}

/// Enum for message roles
enum MessageRole {
  system,
  user,
  assistant,
  tool,
}

/// Enum for agent types
enum AgentType {
  chat,
  workflow,
}

/// Enum for MCP transport types
enum McpTransportType {
  stdio,
  sse,
}

/// Enum for plugin status
enum PluginStatus {
  installed,
  enabled,
  disabled,
  error,
}

/// Enum for workflow node types
enum WorkflowNodeType {
  input,
  output,
  llm,
  condition,
  tool,
  code,
  rag,
  loop,
}
