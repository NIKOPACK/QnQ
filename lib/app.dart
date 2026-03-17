import 'package:flutter/material.dart';
import 'package:qnq/gen/l10n/app_localizations.dart';
import 'package:qnq/core/router/app_router.dart';
import 'package:qnq/core/theme/app_theme.dart';

class QnQApp extends StatelessWidget {
  const QnQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'QnQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
    );
  }
}
