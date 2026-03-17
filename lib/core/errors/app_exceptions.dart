class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException($code): $message';
}

class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException(super.message, {this.statusCode, super.code, super.originalError});
}

class LLMException extends AppException {
  const LLMException(super.message, {super.code, super.originalError});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError});
}

class PluginException extends AppException {
  final String? pluginId;

  const PluginException(super.message, {this.pluginId, super.code, super.originalError});
}

class McpException extends AppException {
  const McpException(super.message, {super.code, super.originalError});
}

class WorkflowException extends AppException {
  final String? nodeId;

  const WorkflowException(super.message, {this.nodeId, super.code, super.originalError});
}
