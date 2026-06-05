import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/glass.dart';

class QuickOrderScreen extends StatefulWidget {
  const QuickOrderScreen({super.key});
  @override
  State<QuickOrderScreen> createState() => _QuickOrderScreenState();
}

class _QuickOrderScreenState extends State<QuickOrderScreen> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  int _qty = 1;
  bool _loading = false;

  Future<void> _submit() async {
    final n = _name.text.trim();
    if (n.isEmpty) { notify(context, 'Mahsulot nomini kiriting', type: 'error'); return; }
    final st = context.read<AppState>();
    setState(() => _loading = true);
    try {
      await Api.createOrder(
        storeId: st.storeId ?? 0, userId: st.userId ?? 0,
        items: [{'product_id': null, 'name': '$n ×$_qty', 'price': 0, 'quantity': _qty}],
        customerName: st.userName, phone: st.userPhone,
        note: _note.text.trim().isEmpty ? 'Tez buyurtma (narx do\'kon tomonidan)' : _note.text.trim(),
      );
      if (!mounted) return;
      notify(context, 'Buyurtma do\'konga yuborildi! 🚀');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) notify(context, '$e', type: 'error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tez buyurtma', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.bolt_rounded, color: AppColors.primary, size: 18), SizedBox(width: 8),
                  Text('Buyurtmani do\'konga tezkor yuboring', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5))]),
              const SizedBox(height: 14),
              const Text('Mahsulot', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: _name, decoration: glassInput(context, hint: 'Mahsulot nomi')),
              const SizedBox(height: 14),
              const Text('Miqdor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Row(children: [
                _step(Icons.remove, () => setState(() { if (_qty > 1) _qty--; })),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: Text('$_qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                _step(Icons.add, () => setState(() => _qty++)),
              ]),
              const SizedBox(height: 14),
              const Text('Izoh (ixtiyoriy)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: _note, maxLines: 2, decoration: glassInput(context, hint: 'Qo\'shimcha izoh yozing...')),
            ]),
          ),
          const SizedBox(height: 16),
          GlowButton(label: _loading ? 'Yuborilmoqda...' : 'Do\'konga jo\'natish', icon: Icons.send_rounded, loading: _loading, onTap: _submit),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(child: Text('Narxi noma\'lum mahsulotlar do\'kon tomonidan hisoblanadi.', style: TextStyle(fontSize: 12, color: AppColors.primary))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _step(IconData ic, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(width: 42, height: 42,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(ic, color: AppColors.primary)),
      );
}
