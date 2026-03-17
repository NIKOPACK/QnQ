import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qnq/presentation/agent_builder/agent_builder_screen.dart';
import 'package:qnq/presentation/chat/chat_screen.dart';
import 'package:qnq/presentation/home/home_screen.dart';
import 'package:qnq/presentation/plugin_store/plugin_store_screen.dart';
import 'package:qnq/presentation/settings/provider_settings/provider_form_screen.dart';
import 'package:qnq/presentation/settings/provider_settings/provider_list_screen.dart';
import 'package:qnq/presentation/settings/settings_screen.dart';
import 'package:qnq/presentation/shared/shell_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/explore',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PluginStoreScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/chat/:agentUid',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final agentUid = state.pathParameters['agentUid']!;
        final conversationUid = state.uri.queryParameters['conversationUid'];
        return ChatScreen(
          agentUid: agentUid,
          conversationUid: conversationUid,
        );
      },
    ),
    GoRoute(
      path: '/agent/create',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AgentBuilderScreen(),
    ),
    GoRoute(
      path: '/agent/edit/:agentUid',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final agentUid = state.pathParameters['agentUid']!;
        return AgentBuilderScreen(agentUid: agentUid);
      },
    ),
    GoRoute(
      path: '/settings/providers',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ProviderListScreen(),
    ),
    GoRoute(
      path: '/settings/providers/add',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ProviderFormScreen(),
    ),
    GoRoute(
      path: '/settings/providers/edit/:providerUid',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final providerUid = state.pathParameters['providerUid']!;
        return ProviderFormScreen(providerUid: providerUid);
      },
    ),
  ],
);
