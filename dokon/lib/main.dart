import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'state.dart';
import 'screens/splash.dart';
import 'screens/register.dart';
import 'screens/store_picker.dart';
import 'screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SantexnikApp());
}

class SantexnikApp extends StatefulWidget {
  const SantexnikApp({super.key});
  @override
  State<SantexnikApp> createState() => _SantexnikAppState();
}

class _SantexnikAppState extends State<SantexnikApp> {
  final AppState _state = AppState();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _state.init().then((_) => setState(() => _ready = true));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _state,
      child: Consumer<AppState>(
        builder: (context, st, _) => MaterialApp(
          title: 'Santexnik PRO',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: st.themeMode,
          home: !_ready
              ? const SplashScreen()
              : !st.isRegistered
                  ? const RegisterScreen()
                  : !st.hasStore
                      ? const StorePickerScreen()
                      : const MainShell(),
        ),
      ),
    );
  }
}
