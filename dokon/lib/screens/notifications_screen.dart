import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/glass.dart';
import 'orders_screen.dart';

/// Foydalanuvchiga "bildirishnoma" — buyurtmalari holatidan hosil qilinadi.
/// (Backendda mijoz uchun alohida bildirishnoma endpointi yo'q, shuning uchun
///  buyurtma holati o'zgarishlari bildirishnoma sifatida ko'rsatiladi.)
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<OrderInfo> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await Api.myOrders(context.read<AppState>().userId ?? 0);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  // status -> (sarlavha, ikon, rang)
  ({String msg, IconData icon, Color color}) _meta(String s) {
    switch (s) {
      case 'accepted':
        return (msg: 'Buyurtmangiz qabul qilindi', icon: Icons.thumb_up_alt_rounded, color: AppColors.primary);
      case 'processing':
      case 'preparing':
        return (msg: 'Buyurtmangiz tayyorlanmoqda', icon: Icons.inventory_2_rounded, color: AppColors.accent);
      case 'on_way':
        return (msg: "Buyurtmangiz yo'lda", icon: Icons.local_shipping_rounded, color: AppColors.info);
      case 'delivered':
      case 'completed':
        return (msg: 'Buyurtmangiz yetkazildi 🎉', icon: Icons.check_circle_rounded, color: AppColors.secondary);
      case 'cancelled':
        return (msg: 'Buyurtmangiz bekor qilindi', icon: Icons.cancel_rounded, color: AppColors.danger);
      default: // new / pending
        return (msg: 'Buyurtmangiz qabul qilindi, tasdiqlanmoqda', icon: Icons.receipt_long_rounded, color: AppColors.primary);
    }
  }

  String _when(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}  ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirishnomalar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorView()
                : _orders.isEmpty
                    ? _emptyView()
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _tile(_orders[i]),
                      ),
      ),
    );
  }

  Widget _tile(OrderInfo o) {
    final m = _meta(o.status);
    return GlassCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: m.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(13)),
          child: Icon(m.icon, color: m.color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Buyurtma #${o.id}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
              Text(money(o.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.primary)),
            ]),
            const SizedBox(height: 3),
            Text(m.msg, style: TextStyle(color: m.color, fontSize: 12.5, fontWeight: FontWeight.w600)),
            if (o.createdAt.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(_when(o.createdAt), style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _emptyView() => ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.notifications_off_outlined, size: 56, color: AppColors.textDim),
          SizedBox(height: 12),
          Center(child: Text('Hozircha bildirishnoma yo\'q', style: TextStyle(color: AppColors.textDim))),
          SizedBox(height: 6),
          Center(child: Text('Buyurtma berganingizda holati shu yerda chiqadi',
              style: TextStyle(color: AppColors.textDim, fontSize: 12))),
        ],
      );

  Widget _errorView() => ListView(
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.cloud_off, size: 54, color: AppColors.textDim),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textDim)),
          ),
          const SizedBox(height: 16),
          Center(child: SizedBox(width: 160, child: GlowButton(label: 'Qayta urinish', icon: Icons.refresh, onTap: _load))),
        ],
      );
}
