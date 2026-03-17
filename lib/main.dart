import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qnq/app.dart';
import 'package:qnq/data/datasources/local/database_service.dart';
import 'package:qnq/services/tools/tool_registry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Isar database
  await DatabaseService.instance;

  // Initialize built-in tools (DateTimeTool, WebSearchTool, etc.)
  ToolRegistry().initialize();

  runApp(
    const ProviderScope(
      child: QnQApp(),
    ),
  );
}
