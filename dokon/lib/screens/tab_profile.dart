import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import 'orders_screen.dart';
import 'settings.dart';

class ProfileTab extends StatefulWidget {
  final VoidCallback onBonus;
  const ProfileTab({super.key, required this.onBonus});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final st = context.read<AppState>();
    try {
      final b = await Api.myBonus(st.storeId ?? 0, st.userId ?? 0);
      if (mounted) setState(() => _balance = (b['balance'] ?? 0).toDouble());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        GlassCard(
          child: Row(children: [
            Container(
              width: 58, height: 58,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.person, color: AppColors.primary, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(st.userName ?? 'Foydalanuvchi', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(st.userPhone ?? '', style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: const Text('Mijoz', style: TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        _tile(Icons.receipt_long_rounded, 'Buyurtmalarim', null,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))),
        _tile(Icons.card_giftcard_rounded, 'Bonuslar', '${_balance.toInt()} ball', widget.onBonus),
        _tile(Icons.settings_rounded, 'Sozlamalar', null,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        _tile(Icons.headset_mic_rounded, 'Yordam va qo\'llab-quvvatlash', null,
            () => launchUrl(Uri.parse('https://t.me/Isroiljon0077'), mode: LaunchMode.externalApplication)),
        _tile(Icons.logout_rounded, 'Chiqish', null, () => st.logout(), danger: true),
      ],
    );
  }

  Widget _tile(IconData ic, String title, String? trailing, VoidCallback onTap, {bool danger = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(13),
        child: Row(children: [
          GlowIconBox(icon: ic, size: 42, color: danger ? AppColors.danger : AppColors.primary),
          const SizedBox(width: 13),
          Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: danger ? AppColors.danger : null))),
          if (trailing != null)
            Padding(padding: const EdgeInsets.only(right: 6), child: Text(trailing, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13))),
          if (!danger) const Icon(Icons.chevron_right_rounded, color: AppColors.textDim),
        ]),
      ),
    );
  }
}
