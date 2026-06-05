import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/glass.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notif = true;

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          GlassCard(child: Row(children: [
            GlowIconBox(icon: st.themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, size: 42),
            const SizedBox(width: 13),
            const Expanded(child: Text('Tungi rejim', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5))),
            Switch(value: st.themeMode == ThemeMode.dark, onChanged: (_) => st.toggleTheme()),
          ])),
          const SizedBox(height: 10),
          GlassCard(child: Row(children: [
            const GlowIconBox(icon: Icons.notifications_rounded, size: 42),
            const SizedBox(width: 13),
            const Expanded(child: Text('Bildirishnomalar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5))),
            Switch(value: _notif, onChanged: (v) => setState(() => _notif = v)),
          ])),
          const SizedBox(height: 10),
          GlassCard(child: Row(children: [
            const GlowIconBox(icon: Icons.info_outline_rounded, size: 42),
            const SizedBox(width: 13),
            const Expanded(child: Text('Ilova haqida', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5))),
            const Text('v1.0', style: TextStyle(color: AppColors.textDim, fontSize: 13)),
          ])),
          const SizedBox(height: 24),
          Center(child: Text('Santexnik PRO · v1.0', style: TextStyle(color: AppColors.textDim, fontSize: 12))),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('by ', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
            ClipRRect(borderRadius: BorderRadius.circular(5), child: Image.asset('assets/ids_logo.jpg', width: 20, height: 20, fit: BoxFit.cover)),
            const SizedBox(width: 6),
            const Text('IDS Group', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ],
      ),
    );
  }
}
