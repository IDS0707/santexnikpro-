import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../icons.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import '../util.dart';

class BonuslarScreen extends StatefulWidget {
  const BonuslarScreen({super.key});
  @override
  State<BonuslarScreen> createState() => _BonuslarScreenState();
}

class _BonuslarScreenState extends State<BonuslarScreen> {
  double _balance = 0;
  List<BonusReward> _rewards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final st = context.read<AppState>();
    try {
      final b = await Api.myBonus(st.storeId ?? 0, st.userId ?? 0);
      final r = await Api.bonusRewards(st.storeId ?? 0);
      _balance = (b['balance'] ?? 0).toDouble();
      _rewards = r;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  ({String name, Color color, int max}) _rank(double b) {
    if (b >= 500) return (name: 'Oltin', color: const Color(0xFFD4A017), max: 1000);
    if (b >= 200) return (name: 'Kumush', color: const Color(0xFF94A3B8), max: 500);
    return (name: 'Bronza', color: const Color(0xFFB87333), max: 200);
  }

  Future<void> _redeem(BonusReward rw) async {
    final st = context.read<AppState>();
    if (_balance < rw.points) { notify(context, 'Ball yetarli emas', type: 'error'); return; }
    try {
      await Api.redeem(st.storeId ?? 0, st.userId ?? 0, rw.id, rw.points.toInt());
      if (mounted) notify(context, '"${rw.name}" uchun so\'rov yuborildi!');
      _load();
    } catch (e) {
      if (mounted) notify(context, '$e', type: 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _rank(_balance);
    final prevMax = r.name == 'Oltin' ? 500 : r.name == 'Kumush' ? 200 : 0;
    final progress = ((_balance - prevMax) / (r.max - prevMax)).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(title: const Text('Bonuslar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [r.color, r.color.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(18)),
                  child: Column(children: [
                    const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 38),
                    const SizedBox(height: 10),
                    Text(r.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    Text('${_balance.toInt()} ball', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
                    const SizedBox(height: 14),
                    ClipRRect(borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(value: progress, minHeight: 9, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white))),
                    const SizedBox(height: 8),
                    Text(_balance >= 500 ? 'Eng yuqori daraja!' : 'Keyingi darajagacha: ${(r.max - _balance).toInt()} ball',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                  ]),
                ),
                const SizedBox(height: 16),
                const Text('Ballarni almashtirish', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 12),
                if (_rewards.isEmpty)
                  const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Hozircha bonus mukofotlari yo\'q', style: TextStyle(color: AppColors.textDim))))
                else
                  ..._rewards.map((rw) {
                    final enough = _balance >= rw.points;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(child: Row(children: [
                        GlowIconBox(icon: iconFor(rw.icon), size: 44),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(rw.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                          const SizedBox(height: 2),
                          Text('${rw.points.toInt()} ball', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                        ])),
                        Opacity(opacity: enough ? 1 : 0.5, child: ElevatedButton(
                          onPressed: enough ? () => _redeem(rw) : null,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                          child: const Text('Olish', style: TextStyle(fontSize: 12)))),
                      ])),
                    );
                  }),
                const SizedBox(height: 16),
                _infoRow(Icons.monetization_on, 'Har 1000 so\'mga', '+1 ball'),
                _infoRow(Icons.inventory_2, 'Har bir mahsulot', '+5 ball'),
              ],
            ),
    );
  }

  Widget _infoRow(IconData ic, String a, String b) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GlassCard(padding: const EdgeInsets.all(13), child: Row(children: [
          Icon(ic, size: 16, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(a, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Text(b, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700)),
        ])),
      );
}
