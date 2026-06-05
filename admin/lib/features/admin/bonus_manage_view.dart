import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/state/app_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

/// Bonus do'koni boshqaruvi: bonus mahsulotlari (katalog) + bonus so'rovlari.
/// Do'kon ilovasi `bonus_items`/`bonus_requests`/`user_points` jadvallaridan foydalanadi.
class BonusManageView extends StatefulWidget {
  const BonusManageView({super.key, required this.store});
  final AppStore store;

  @override
  State<BonusManageView> createState() => _BonusManageViewState();
}

class _BonusManageViewState extends State<BonusManageView> {
  int _tab = 0;
  late Future<List<Map<String, dynamic>>> _itemsF;
  late Future<List<Map<String, dynamic>>> _reqF;

  @override
  void initState() {
    super.initState();
    _itemsF = widget.store.bonusItems();
    _reqF = widget.store.bonusRequests();
  }

  void _reload() {
    setState(() {
      _itemsF = widget.store.bonusItems();
      _reqF = widget.store.bonusRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Bonus do\'koni',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded)),
              if (_tab == 0) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _editItem(null),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Bonus mahsulot'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _BonusSettingsCard(store: widget.store),
          const SizedBox(height: 16),
          Row(children: [
            _tabChip('Bonus mahsulotlari', 0),
            const SizedBox(width: 10),
            _tabChip('So\'rovlar', 1),
          ]),
          const SizedBox(height: 16),
          Expanded(child: _tab == 0 ? _itemsList() : _requestsList()),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int index) {
    final active = _tab == index;
    return InkWell(
      onTap: () => setState(() => _tab = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : AppColors.primaryDark,
                fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ---------------- BONUS ITEMS ----------------
  Widget _itemsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _itemsF,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Xatolik: ${snap.error}'));
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Center(
              child: Text(
                  'Bonus mahsulot yo\'q. Yuqoridagi "Bonus mahsulot" tugmasi bilan qo\'shing.'));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final b = items[i];
            final img = (b['image_url'] ?? '') as String;
            final active = (b['is_active'] ?? true) == true;
            return Card(
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: img.isNotEmpty
                        ? Image.network(img, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.card_giftcard))
                        : const ColoredBox(
                            color: AppColors.primarySoft,
                            child: Icon(Icons.card_giftcard,
                                color: AppColors.primary)),
                  ),
                ),
                title: Text((b['name'] ?? '') as String,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    '${b['points_cost'] ?? 0} ball  ·  ${active ? 'Faol' : 'Nofaol'}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      onPressed: () => _editItem(b),
                      icon: const Icon(Icons.edit_outlined)),
                  IconButton(
                      onPressed: () => _deleteItem(b),
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.danger)),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteItem(Map<String, dynamic> b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('O\'chirilsinmi?'),
        content: Text((b['name'] ?? '') as String),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Bekor')),
          ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('O\'chirish')),
        ],
      ),
    );
    if (ok == true) {
      await widget.store.removeBonusItem(b['id'] as String);
      _reload();
    }
  }

  Future<void> _editItem(Map<String, dynamic>? existing) async {
    final nameCtrl =
        TextEditingController(text: (existing?['name'] ?? '') as String);
    final costCtrl =
        TextEditingController(text: (existing?['points_cost'] ?? '').toString());
    String? imageUrl = existing?['image_url'] as String?;
    bool active = (existing?['is_active'] ?? true) as bool;
    bool busy = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(builder: (c, setLocal) {
        Future<void> pick() async {
          final x = await ImagePicker().pickImage(
              source: ImageSource.gallery, maxWidth: 1000, imageQuality: 80);
          if (x == null) return;
          setLocal(() => busy = true);
          try {
            final bytes = await x.readAsBytes();
            final url = await widget.store.uploadProductImage(bytes, x.name);
            setLocal(() {
              imageUrl = url;
              busy = false;
            });
          } catch (e) {
            setLocal(() => busy = false);
            if (c.mounted) AppToast.error(c, 'Rasm yuklab bo\'lmadi: $e');
          }
        }

        return AlertDialog(
          title: Text(existing == null ? 'Yangi bonus mahsulot' : 'Tahrirlash'),
          content: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: busy ? null : pick,
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: busy
                      ? const Center(child: CircularProgressIndicator())
                      : (imageUrl != null && imageUrl!.isNotEmpty
                          ? Image.network(imageUrl!,
                              fit: BoxFit.cover, width: double.infinity)
                          : const Center(
                              child: Icon(Icons.add_a_photo_outlined,
                                  size: 32, color: AppColors.primary))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nomi')),
              const SizedBox(height: 10),
              TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ball narxi')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Faol'),
                value: active,
                onChanged: (v) => setLocal(() => active = v),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Bekor')),
            ElevatedButton(
                onPressed: busy ? null : () => Navigator.pop(c, true),
                child: const Text('Saqlash')),
          ],
        );
      }),
    );

    if (saved == true) {
      final storeId = widget.store.currentStoreId;
      if (storeId == null) return;
      final data = <String, dynamic>{
        'store_id': storeId,
        'name': nameCtrl.text.trim(),
        'points_cost': int.tryParse(costCtrl.text.trim()) ?? 0,
        'image_url': imageUrl,
        'is_active': active,
      };
      if (existing != null) data['id'] = existing['id'];
      await widget.store.saveBonusItem(data);
      _reload();
    }
  }

  // ---------------- REQUESTS ----------------
  Widget _requestsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _reqF,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) return Center(child: Text('Xatolik: ${snap.error}'));
        final reqs = snap.data ?? [];
        if (reqs.isEmpty) return const Center(child: Text('So\'rov yo\'q'));
        return ListView.separated(
          itemCount: reqs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = reqs[i];
            final user = r['users'] as Map<String, dynamic>?;
            final item = r['bonus_items'] as Map<String, dynamic>?;
            final status = (r['status'] ?? 'pending') as String;
            final pending = status == 'pending';
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text((item?['name'] ?? 'Bonus') as String,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700))),
                      _statusBadge(status),
                    ]),
                    const SizedBox(height: 4),
                    Text('${user?['name'] ?? ''}   ${user?['phone'] ?? ''}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13)),
                    Text('${r['points_cost'] ?? 0} ball',
                        style: const TextStyle(fontSize: 12)),
                    if (pending) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success),
                            onPressed: () => _approve(r),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Tasdiqlash'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger),
                            onPressed: () => _reject(r),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Rad etish'),
                          ),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusBadge(String s) {
    Color c;
    String t;
    switch (s) {
      case 'approved':
        c = AppColors.success;
        t = 'Tasdiqlandi';
        break;
      case 'rejected':
        c = AppColors.danger;
        t = 'Rad etildi';
        break;
      default:
        c = AppColors.warning;
        t = 'Kutilmoqda';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Text(t,
          style:
              TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Future<void> _approve(Map<String, dynamic> r) async {
    await widget.store.updateBonusRequest(r['id'] as String, 'approved');
    final userId = r['user_id'] as String?;
    final cost = (r['points_cost'] as num?)?.toInt() ?? 0;
    if (userId != null && cost > 0) {
      await widget.store.adjustPoints(userId, -cost);
    }
    if (mounted) AppToast.success(context, 'Tasdiqlandi');
    _reload();
  }

  Future<void> _reject(Map<String, dynamic> r) async {
    await widget.store.updateBonusRequest(r['id'] as String, 'rejected');
    if (mounted) AppToast.success(context, 'Rad etildi');
    _reload();
  }
}

/// Bonus sozlamalari: faollashtirish + "necha so'mlik savdoga necha ball".
class _BonusSettingsCard extends StatefulWidget {
  const _BonusSettingsCard({required this.store});
  final AppStore store;

  @override
  State<_BonusSettingsCard> createState() => _BonusSettingsCardState();
}

class _BonusSettingsCardState extends State<_BonusSettingsCard> {
  bool _loading = true;
  bool _enabled = false;
  bool _saving = false;
  final _amountCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await widget.store.storeBonusSettings();
    if (!mounted) return;
    setState(() {
      _enabled = (s?['bonus_enabled'] ?? false) as bool;
      final amt = (s?['bonus_amount'] as num?)?.toInt() ?? 0;
      final pts = (s?['bonus_points'] as num?)?.toInt() ?? 0;
      _amountCtrl.text = amt > 0 ? amt.toString() : '';
      _pointsCtrl.text = pts > 0 ? pts.toString() : '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.store.saveStoreBonus(
        enabled: _enabled,
        amount: num.tryParse(_amountCtrl.text.trim()) ?? 0,
        points: int.tryParse(_pointsCtrl.text.trim()) ?? 0,
      );
      if (mounted) AppToast.success(context, 'Bonus sozlamasi saqlandi');
    } catch (e) {
      if (mounted) AppToast.error(context, 'Xatolik: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text('Bonus sozlamalari',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                Switch(
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
                Text(_enabled ? 'Faol' : 'Nofaol',
                    style: TextStyle(
                        color: _enabled ? AppColors.success : AppColors.textMuted,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Mijoz buyurtma berganda avtomatik ball oladi:',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Har'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        isDense: true, hintText: 'masalan 10000'),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('so\'mlik savdoga'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _pointsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        isDense: true, hintText: 'masalan 1'),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('ball beriladi'),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_rounded, size: 18),
                label: const Text('Saqlash'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
