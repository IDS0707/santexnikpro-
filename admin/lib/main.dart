import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/state/app_scope.dart';
import 'app/state/app_store.dart';
import 'data/local_repository.dart';
import 'data/remote_api_service.dart';

Future<void> main() async {
  // Guard everything — internet/init xatolari ilovani ochmasdan crash qilmasin.
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Crashlarni ushlab qolish (so app still renders error widget instead of black screen)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };

    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (_) {}

    final repository = LocalRepository();
    try {
      await repository.initialize().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Repository init xato: $e');
    }

    final store = AppStore(repository: repository);
    try {
      await store.initialize().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Store init xato: $e');
    }

    runApp(AppScope(notifier: store, child: const SantexnikaAdminApp()));
  }, (error, stack) {
    debugPrint('Uncaught: $error\n$stack');
  });
}
