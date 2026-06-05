import 'package:flutter/material.dart';

import '../data/models.dart';
import '../features/admin/admin_shell.dart';
import '../features/auth/login_page.dart';
import '../features/driver/driver_page.dart';
import '../features/super_admin/super_admin_shell.dart';
import '../ui/theme.dart';
import 'state/app_scope.dart';

class SantexnikaAdminApp extends StatelessWidget {
  const SantexnikaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.watch(context);
    return MaterialApp(
      title: 'Santexnika Admin',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          switch (store.session.role) {
            case UserRole.superAdmin:
              return const SuperAdminShell();
            case UserRole.admin:
              return const AdminShell();
            case UserRole.driver:
              return const DriverPage();
            case UserRole.none:
              return const LoginPage();
          }
        },
      ),
    );
  }
}
