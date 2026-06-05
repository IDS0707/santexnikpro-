import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/state/app_scope.dart';
import '../../../data/models.dart';
import '../../../data/remote_api_service.dart';
import '../../../ui/theme.dart';

class StoresManagementPage extends StatefulWidget {
  const StoresManagementPage({super.key});

  @override
  State<StoresManagementPage> createState() => _StoresManagementPageState();
}

class _StoresManagementPageState extends State<StoresManagementPage> {
  final _api = RemoteApiService();
  final _money = NumberFormat('#,###', 'uz');
  List<StoreSummary> _stores = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _stores = await _api.fetchStoresSummary();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleStatus(StoreSummary s) async {
    final action = s.isActive ? 'bloklash' : 'qaytarish';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Do\'konni $action'),
        content: Text('${s.name} do\'konini ${s.isActive ? "BLOKLASH" : "QAYTARISH"}ga rozimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: s.isActive ? AppColors.danger : AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.isActive ? 'BLOKLASH' : 'QAYTARISH'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final newStatus = s.isActive ? 'blocked' : 'active';
      await _api.setStoreStatus(s.id, newStatus);
      if (!mounted) return;
      final store = AppScope.read(context);
      await _api.logActivity(
        actorRole: 'super_admin',
        actorId: store.session.superAdminId,
        storeId: s.id,
        action: newStatus == 'blocked' ? 'block_store' : 'unblock_store',
      );
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e')));
    }
  }

  Future<void> _editCommission(StoreSummary s) async {
    final ctrl = TextEditingController(text: s.commissionRate.toStringAsFixed(1));
    final newVal = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${s.name} — komissiya foizi'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: '%', labelText: 'Komissiya foizi (0-100)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              if (v != null && v >= 0 && v <= 100) Navigator.pop(ctx, v);
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
    if (newVal == null) return;
    await _api.updateStoreCommission(s.id, newVal);
    await _load();
  }

  Future<void> _enterStore(StoreSummary s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Do\'kon ichiga kirish'),
        content: Text('${s.name} admin panelini ochmoqchimisiz?\n\n'
            'Super admin sifatida vaqtinchalik shu do\'kon ichida ishlaysiz. '
            'Yuqorida qaytish tugmasi orqali super admin panelga qaytasiz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kirish')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final store = AppScope.read(context);
    await store.enterStoreAsSuperAdmin(s.id, s.name, s.slug);
  }

  Future<void> _deleteStore(StoreSummary s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Do\'konni o\'chirish?'),
        content: Text('${s.name} va uning BARCHA mahsulot, kategoriya, buyurtma ma\'lumotlari o\'chiriladi.\n\nBu amalni qaytarib bo\'lmaydi!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('O\'CHIRISH'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deleteStore(s.id);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e')));
    }
  }

  Future<void> _createStore() async {
    final slugCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final commCtrl = TextEditingController(text: '5.0');
    final adminLoginCtrl = TextEditingController();
    final adminPassCtrl = TextEditingController();
    final adminNameCtrl = TextEditingController();
    final accessPassCtrl = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yangi do\'kon va admin yaratish'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('1. DO\'KON MA\'LUMOTLARI',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                TextField(controller: nameCtrl, decoration: const InputDecoration(
                    labelText: 'Do\'kon nomi *', hintText: 'masalan: Build House')),
                const SizedBox(height: 12),
                TextField(controller: codeCtrl, textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                        labelText: 'Do\'kon ID raqami *',
                        hintText: 'masalan: BH0707 — mijozlar shu ID bilan qo\'shiladi',
                        helperText: 'Mijoz registratsiyada shu raqamni kiritadi')),
                const SizedBox(height: 12),
                TextField(controller: slugCtrl, decoration: const InputDecoration(
                    labelText: 'Slug (kichik harf, chiziqcha) *', hintText: 'masalan: build-house')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Tavsif')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: catCtrl, decoration: const InputDecoration(
                      labelText: 'Kategoriya', hintText: 'qurilish, oziq-ovqat...'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: commCtrl, keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Komissiya', suffixText: '%'))),
                ]),
                const SizedBox(height: 12),
                TextField(controller: accessPassCtrl, decoration: const InputDecoration(
                    labelText: 'Mijoz kirish paroli',
                    hintText: 'mijoz do\'konni tanlaganda shu parolni kiritadi',
                    helperText: 'Bo\'sh qoldirsangiz — parolsiz kiriladi')),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                const Text('2. ADMIN PANEL UCHUN LOGIN MA\'LUMOTLARI',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                const Text('Bu ma\'lumotlarni do\'kon egasiga berasiz — u shular bilan o\'z admin paneliga kiradi',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                TextField(controller: adminNameCtrl, decoration: const InputDecoration(
                    labelText: 'Admin ism familyasi', hintText: 'masalan: Ahmad Karimov')),
                const SizedBox(height: 12),
                TextField(controller: adminLoginCtrl, decoration: const InputDecoration(
                    labelText: 'Admin login *', hintText: 'masalan: bh_admin')),
                const SizedBox(height: 12),
                TextField(controller: adminPassCtrl, decoration: const InputDecoration(
                    labelText: 'Admin parol *', hintText: 'kuchli parol o\'ylab toping')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yaratish')),
        ],
      ),
    );
    if (created != true) return;

    final name = nameCtrl.text.trim();
    final slug = slugCtrl.text.trim();
    final code = codeCtrl.text.trim();
    final adminLogin = adminLoginCtrl.text.trim();
    final adminPass = adminPassCtrl.text.trim();

    if (name.isEmpty || slug.isEmpty || code.isEmpty || adminLogin.isEmpty || adminPass.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('* belgisi bor maydonlar to\'ldirilishi shart'), backgroundColor: AppColors.danger),
        );
      }
      return;
    }

    try {
      await _api.createStoreWithAdmin(
        slug: slug,
        name: name,
        description: descCtrl.text.trim(),
        inviteCode: code,
        adminLogin: adminLogin,
        adminPassword: adminPass,
        adminName: adminNameCtrl.text.trim().isEmpty ? null : adminNameCtrl.text.trim(),
        category: catCtrl.text.trim().isEmpty ? null : catCtrl.text.trim(),
        commissionRate: double.tryParse(commCtrl.text.trim()) ?? 5.0,
        accessPassword:
            accessPassCtrl.text.trim().isEmpty ? null : accessPassCtrl.text.trim(),
      );
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      _showCredentialsSuccess(name: name, code: code, slug: slug, login: adminLogin, password: adminPass);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e')));
    }
  }

  void _showCredentialsSuccess({required String name, required String code, required String slug,
      required String login, required String password}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: const [
          Icon(Icons.check_circle, color: Color(0xFF10B981)),
          SizedBox(width: 8),
          Text('Do\'kon yaratildi'),
        ]),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Quyidagi ma\'lumotlarni saqlab oling va do\'kon egasiga uzating:',
                  style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              _InfoRow('Mijozlar uchun ID raqam', code, Icons.key_rounded),
              _InfoRow('Slug', slug, Icons.tag_rounded),
              const Divider(height: 24),
              const Text('ADMIN PANEL KIRISH',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 8),
              _InfoRow('Do\'kon kodi (slug)', slug, Icons.storefront_rounded),
              _InfoRow('Login', login, Icons.person_rounded),
              _InfoRow('Parol', password, Icons.lock_rounded),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final text = 'Do\'kon: $name\nMijozlar ID: $code\nAdmin slug: $slug\nLogin: $login\nParol: $password';
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Ma\'lumotlar:\n$text')));
            },
            child: const Text('Ko\'rsatish'),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tushundim')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Do\'konlar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('Hamma do\'konlarni boshqarish', style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _createStore,
                  icon: const Icon(Icons.add),
                  label: const Text('Yangi do\'kon'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ..._stores.map((s) => _StoreCard(
              store: s,
              money: _money,
              onToggle: () => _toggleStatus(s),
              onEditCommission: () => _editCommission(s),
              onDelete: () => _deleteStore(s),
              onEnterStore: () => _enterStore(s),
            )),
            if (_stores.isEmpty) const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Hozircha do\'kon yo\'q. Yangisini yarating!')),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.store,
    required this.money,
    required this.onToggle,
    required this.onEditCommission,
    required this.onDelete,
    required this.onEnterStore,
  });

  final StoreSummary store;
  final NumberFormat money;
  final VoidCallback onToggle;
  final VoidCallback onEditCommission;
  final VoidCallback onDelete;
  final VoidCallback onEnterStore;

  @override
  Widget build(BuildContext context) {
    final statusColor = store.isActive ? const Color(0xFF10B981) : AppColors.danger;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(store.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              store.isActive ? 'AKTIV' : 'BLOKLANGAN',
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('slug: ${store.slug}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _MetricChip(label: 'Buyurtmalar', value: '${store.totalOrders}', icon: Icons.shopping_bag_rounded),
                _MetricChip(label: 'Aylanma', value: '${money.format(store.totalRevenue.toInt())} UZS', icon: Icons.attach_money),
                _MetricChip(label: 'Mahsulotlar', value: '${store.totalProducts}', icon: Icons.inventory_2_outlined),
                _MetricChip(label: 'Mijozlar', value: '${store.totalCustomers}', icon: Icons.people_outline),
                _MetricChip(label: 'Komissiya', value: '${store.commissionRate.toStringAsFixed(1)}%', icon: Icons.percent),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Ichiga kirish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onEnterStore,
                ),
                OutlinedButton.icon(
                  icon: Icon(store.isActive ? Icons.block : Icons.check_circle, color: statusColor),
                  label: Text(store.isActive ? 'Bloklash' : 'Qaytarish', style: TextStyle(color: statusColor)),
                  onPressed: onToggle,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.percent),
                  label: const Text('Komissiya'),
                  onPressed: onEditCommission,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_forever, color: AppColors.danger),
                  label: const Text('O\'chirish', style: TextStyle(color: AppColors.danger)),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          SizedBox(width: 160, child: Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
          Expanded(
            child: SelectableText(value, style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
