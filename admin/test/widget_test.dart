import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:santexnika_admin/app/app.dart';
import 'package:santexnika_admin/app/state/app_scope.dart';
import 'package:santexnika_admin/app/state/app_store.dart';
import 'package:santexnika_admin/data/local_repository.dart';

Future<AppStore> _createStore() async {
  SharedPreferences.setMockInitialValues({});
  final repository = LocalRepository();
  await repository.initialize();
  final store = AppStore(repository: repository);
  await store.initialize();
  return store;
}

void main() {
  testWidgets('login screen renders main sections', (
    WidgetTester tester,
  ) async {
    final store = await _createStore();

    await tester.pumpWidget(
      AppScope(
        notifier: store,
        child: const SantexnikaAdminApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tizimga kirish'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Haydovchi'), findsOneWidget);
    expect(find.text('Demo kirish'), findsOneWidget);
  });

  testWidgets('empty submit shows validation messages', (
    WidgetTester tester,
  ) async {
    final store = await _createStore();

    await tester.pumpWidget(
      AppScope(
        notifier: store,
        child: const SantexnikaAdminApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kirish'));
    await tester.pumpAndSettle();

    expect(find.text('Login kiriting'), findsOneWidget);
    expect(find.text('Parol kiriting'), findsOneWidget);
  });

  testWidgets('admin credentials navigate to dashboard', (
    WidgetTester tester,
  ) async {
    final store = await _createStore();

    await tester.pumpWidget(
      AppScope(
        notifier: store,
        child: const SantexnikaAdminApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), 'Admin123!');
    await tester.enterText(find.byType(TextFormField).at(0), AppStore.adminLogin);
    await tester.tap(find.text('Kirish'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
  });
}
