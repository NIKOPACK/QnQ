import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qnq/app.dart';
import 'package:qnq/data/datasources/local/database_service.dart';

void main() {
  testWidgets('App launches and shows home screen', (WidgetTester tester) async {
    await DatabaseService.instance;
    await tester.pumpWidget(
      const ProviderScope(child: QnQApp()),
    );
    await tester.pumpAndSettle();
    // App should start at the home screen (no counter, no MyApp)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
