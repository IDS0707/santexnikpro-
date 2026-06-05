import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/glass.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<OrderInfo>> _f;

  @override
  void initState() {
    super.initState();
    _f = Api.myOrders(context.read<AppState>().userId ?? 0);
  }

  String _stat(String s) => const {
        'new': 'Yangi', 'pending': 'Yangi', 'accepted': 'Qabul qilindi', 'processing': 'Yetkazilmoqda',
        'preparing': 'Tayyorlanmoqda', 'on_way': "Yo'lda", 'delivered': 'Yetkazildi',
        'completed': 'Yetkazildi', 'cancelled': 'Bekor qilindi'
      }[s] ?? s;
  Color _color(String s) => (s == 'completed' || s == 'delivered') ? AppColors.secondary
      : s == 'cancelled' ? AppColors.danger : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buyurtmalarim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      body: FutureBuilder<List<OrderInfo>>(
        future: _f,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final orders = snap.data!;
          if (orders.isEmpty) {
            return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.receipt_long_outlined, size: 54, color: AppColors.textDim),
              SizedBox(height: 12), Text('Hozircha buyurtma yo\'q', style: TextStyle(color: AppColors.textDim)),
            ]));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final o = orders[i];
              return GlassCard(child: Row(children: [
                const GlowIconBox(icon: Icons.shopping_bag_rounded, size: 44),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Buyurtma #${o.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _color(o.status).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(_stat(o.status), style: TextStyle(color: _color(o.status), fontSize: 11, fontWeight: FontWeight.w700))),
                ])),
                Text(money(o.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ]));
            },
          );
        },
      ),
    );
  }
}
