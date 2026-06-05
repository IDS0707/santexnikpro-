import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/remote_api_service.dart';
import '../../../ui/theme.dart';

class PendingShopsPage extends StatefulWidget {
  const PendingShopsPage({super.key});

  @override
  State<PendingShopsPage> createState() => _PendingShopsPageState();
}

class _PendingShopsPageState extends State<PendingShopsPage> {
  final _api = RemoteApiService();
  final _dateFmt = DateFormat('dd MMM, HH:mm');
  List<Map<String, dynamic>> _shops = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _shops = await _api.fetchPendingShops();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _approve(Map<String, dynamic> shop) async {
    final commCtrl = TextEditingController(text: '5.0');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Do\'konni tasdiqlash'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shop['name'] as String,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('ID: ${shop['invite_code']}',
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              TextField(
                controller: commCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Platforma komissiyasi (%)',
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tasdiqlangach do\'kon ochiladi, admin panelga kirish mumkin bo\'ladi.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Tasdiqlash'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.approveShop(shop['id'] as String,
          commission: double.tryParse(commCtrl.text.trim()) ?? 5.0);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${shop['name']} tasdiqlandi'),
              backgroundColor: const Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e')));
      }
    }
  }

  Future<void> _reject(Map<String, dynamic> shop) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Do\'konni rad etish'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shop['name'] as String,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Rad etish sababi',
                  hintText: 'Foydalanuvchi shu xabarni ko\'radi',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
          ElevatedButton.icon(
            icon: const Icon(Icons.cancel_rounded),
            label: const Text('Rad etish'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final reason = reasonCtrl.text.trim();
    if (reason.isEmpty) return;
    try {
      await _api.rejectShop(shop['id'] as String, reason);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${shop['name']} rad etildi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pending_actions_rounded, size: 28, color: AppColors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Kutilayotgan arizalar',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_shops.length} ta',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Yangi do\'kon egalarining arizalari. Tasdiqlasangiz, ular tizimga kirish huquqini oladi.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            if (_shops.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('Kutilayotgan arizalar yo\'q',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text(
                      'Yangi do\'kon ro\'yxatdan o\'tganda shu yerda paydo bo\'ladi',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ..._shops.map((s) => _ShopCard(
                    shop: s,
                    dateFmt: _dateFmt,
                    onApprove: () => _approve(s),
                    onReject: () => _reject(s),
                  )),
          ],
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.shop,
    required this.dateFmt,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> shop;
  final DateFormat dateFmt;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final created = DateTime.tryParse(shop['created_at'] as String? ?? '');
    final firstname = (shop['owner_firstname'] as String?) ?? '';
    final lastname = (shop['owner_lastname'] as String?) ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shop['name'] as String,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('ID: ${shop['invite_code']}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (created != null)
                Text(dateFmt.format(created),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _row('Egasi', '$firstname $lastname'.trim(), Icons.person_rounded),
          const SizedBox(height: 8),
          _row('Telefon', (shop['owner_phone'] as String?) ?? '-', Icons.phone_rounded),
          if ((shop['category'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _row('Kategoriya', shop['category'] as String, Icons.category_rounded),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded, color: AppColors.danger, size: 18),
                  label: const Text('Rad etish', style: TextStyle(color: AppColors.danger)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Tasdiqlash'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ],
    );
  }
}
