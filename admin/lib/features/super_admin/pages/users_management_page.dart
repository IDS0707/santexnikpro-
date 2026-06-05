import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models.dart';
import '../../../data/remote_api_service.dart';
import '../../../ui/theme.dart';

class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key});

  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage> {
  final _api = RemoteApiService();
  final _searchCtrl = TextEditingController();
  final _date = DateFormat('dd.MM.yyyy');
  List<AppUserRecord> _users = const [];
  List<StoreSummary> _stores = const [];
  bool _loading = true;
  String _filter = 'all'; // all, customer, super_admin, blocked
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Future.wait([_api.fetchAllUsers(), _api.fetchStoresSummary()]);
      _users = r[0] as List<AppUserRecord>;
      _stores = r[1] as List<StoreSummary>;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<AppUserRecord> get _filtered {
    return _users.where((u) {
      if (_filter == 'customer' && u.role != 'customer') return false;
      if (_filter == 'super_admin' && u.role != 'super_admin') return false;
      if (_filter == 'blocked' && u.status != 'blocked') return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        return u.name.toLowerCase().contains(q) || u.phone.contains(q);
      }
      return true;
    }).toList();
  }

  Future<void> _toggleBlock(AppUserRecord u) async {
    final newStatus = u.status == 'active' ? 'blocked' : 'active';
    await _api.setUserStatus(u.id, newStatus);
    await _load();
  }

  Future<void> _transfer(AppUserRecord u) async {
    final storeId = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('${u.name}\'ni qaysi do\'konga ko\'chirish?'),
        children: _stores.map((s) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, s.id),
          child: Row(children: [
            const Icon(Icons.storefront, size: 18),
            const SizedBox(width: 8),
            Text(s.name),
            if (s.id == u.currentStoreId) ...const [SizedBox(width: 8), Icon(Icons.check, size: 16, color: AppColors.primary)],
          ]),
        )).toList(),
      ),
    );
    if (storeId == null || storeId == u.currentStoreId) return;
    await _api.transferUser(u.id, storeId);
    await _load();
  }

  String _storeName(String? id) {
    if (id == null) return '—';
    final s = _stores.where((s) => s.id == id);
    return s.isEmpty ? '—' : s.first.name;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Foydalanuvchilar',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('Jami: ${_users.length} · Aktiv: ${_users.where((u) => u.status == "active").length}',
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Ism yoki telefon orqali qidirish',
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _filter,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Hammasi')),
                    DropdownMenuItem(value: 'customer', child: Text('Mijozlar')),
                    DropdownMenuItem(value: 'super_admin', child: Text('Super adminlar')),
                    DropdownMenuItem(value: 'blocked', child: Text('Bloklangan')),
                  ],
                  onChanged: (v) => setState(() => _filter = v ?? 'all'),
                ),
              ]),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filtered.length,
              separatorBuilder: (_, i) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final u = _filtered[i];
                final blocked = u.status == 'blocked';
                final isSuper = u.role == 'super_admin';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSuper ? const Color(0xFF8B5CF6) : AppColors.primarySoft,
                      child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                          style: TextStyle(color: isSuper ? Colors.white : AppColors.primary, fontWeight: FontWeight.w800)),
                    ),
                    title: Row(children: [
                      Expanded(child: Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700))),
                      if (isSuper) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('SUPER', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                      if (blocked) const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.block, size: 14, color: AppColors.danger),
                      ),
                    ]),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📞 ${u.phone}'),
                        Text('🏪 ${_storeName(u.currentStoreId)} · 📅 ${_date.format(u.createdAt)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'block') await _toggleBlock(u);
                        if (v == 'transfer') await _transfer(u);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'block', child: Text(blocked ? 'Blokdan chiqarish' : 'Bloklash')),
                        if (!isSuper) const PopupMenuItem(value: 'transfer', child: Text('Boshqa do\'konga')),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
