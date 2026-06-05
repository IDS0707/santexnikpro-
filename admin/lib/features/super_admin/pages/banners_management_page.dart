import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../data/remote_api_service.dart';
import '../../../ui/theme.dart';

class BannersManagementPage extends StatefulWidget {
  const BannersManagementPage({super.key});

  @override
  State<BannersManagementPage> createState() => _BannersManagementPageState();
}

class _BannersManagementPageState extends State<BannersManagementPage> {
  final _api = RemoteApiService();
  List<Map<String, dynamic>> _banners = const [];
  List<StoreSummary> _stores = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _stores = await _api.fetchStoresSummary();
      _banners = await _api.fetchAllBanners();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _storeName(String? id) {
    if (id == null) return 'Hammasiga (Global)';
    final s = _stores.where((s) => s.id == id).toList();
    return s.isEmpty ? '?' : s.first.name;
  }

  Color _parseColor(String? hex) {
    if (hex == null) return AppColors.primary;
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) { return AppColors.primary; }
  }

  Future<void> _edit({Map<String, dynamic>? banner}) async {
    final isNew = banner == null;
    final titleCtrl = TextEditingController(text: banner?['title'] as String? ?? '');
    final subtitleCtrl = TextEditingController(text: banner?['subtitle'] as String? ?? '');
    final imageCtrl = TextEditingController(text: banner?['image_url'] as String? ?? '');
    final linkCtrl = TextEditingController(text: banner?['link_url'] as String? ?? '');
    final colorCtrl = TextEditingController(text: banner?['background_color'] as String? ?? '#2563EB');
    final sortCtrl = TextEditingController(text: (banner?['sort_order'] ?? 0).toString());
    String? selectedStoreId = banner?['store_id'] as String?;
    bool isGlobal = banner?['is_global'] as bool? ?? false;
    bool isActive = banner?['is_active'] as bool? ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(isNew ? 'Yangi reklama' : 'Reklamani tahrirlash'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Sarlavha *')),
                  const SizedBox(height: 12),
                  TextField(controller: subtitleCtrl,
                      decoration: const InputDecoration(labelText: 'Qisqacha matn')),
                  const SizedBox(height: 12),
                  TextField(controller: imageCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Rasm URL', hintText: 'https://...')),
                  const SizedBox(height: 12),
                  TextField(controller: linkCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Link (ixtiyoriy)', hintText: 'https://...')),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: colorCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Fon rangi', hintText: '#2563EB'))),
                    const SizedBox(width: 12),
                    SizedBox(width: 80, child: TextField(controller: sortCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Tartib'))),
                  ]),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: isGlobal,
                    onChanged: (v) => setLocal(() {
                      isGlobal = v;
                      if (v) selectedStoreId = null;
                    }),
                    title: const Text('Hamma do\'konlar uchun'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  if (!isGlobal) ...[
                    const Text('Qaysi do\'kon uchun?'),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedStoreId,
                      decoration: const InputDecoration(),
                      isExpanded: true,
                      items: _stores.map((s) => DropdownMenuItem<String?>(
                          value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setLocal(() => selectedStoreId = v),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: isActive,
                    onChanged: (v) => setLocal(() => isActive = v),
                    title: const Text('Faol'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
                child: Text(isNew ? 'Yaratish' : 'Saqlash')),
          ],
        ),
      ),
    );

    if (saved != true) return;
    if (titleCtrl.text.trim().isEmpty) return;
    if (!isGlobal && selectedStoreId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Do\'kon tanlash kerak yoki Global yoqing')));
      }
      return;
    }

    final payload = <String, dynamic>{
      if (banner?['id'] != null) 'id': banner!['id'],
      'title': titleCtrl.text.trim(),
      'subtitle': subtitleCtrl.text.trim(),
      'image_url': imageCtrl.text.trim().isEmpty ? null : imageCtrl.text.trim(),
      'link_url': linkCtrl.text.trim().isEmpty ? null : linkCtrl.text.trim(),
      'background_color': colorCtrl.text.trim().isEmpty ? '#2563EB' : colorCtrl.text.trim(),
      'sort_order': int.tryParse(sortCtrl.text.trim()) ?? 0,
      'store_id': isGlobal ? null : selectedStoreId,
      'is_global': isGlobal,
      'is_active': isActive,
    };
    try {
      await _api.upsertBanner(payload);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e')));
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reklamani o\'chirish'),
        content: Text('${b['title']} ni o\'chirmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('O\'chirish')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.deleteBanner(b['id'] as String);
      await _load();
    } catch (_) {}
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
            Row(children: [
              const Icon(Icons.image_outlined, size: 28, color: AppColors.primary),
              const SizedBox(width: 10),
              const Expanded(child: Text('Reklama bannerlari',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Yangi'),
                onPressed: () => _edit(),
              ),
            ]),
            const SizedBox(height: 8),
            const Text(
              'Shop ilovaning bosh sahifasida ko\'rinadigan reklama bannerlari. Global (hamma do\'konlar) yoki do\'kon-uchun belgilash mumkin.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (_banners.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 48),
                alignment: Alignment.center,
                child: Column(children: [
                  Icon(Icons.image_not_supported_outlined, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Hozircha banner yo\'q'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _edit(),
                    icon: const Icon(Icons.add),
                    label: const Text('Birinchi bannerni yarating'),
                  ),
                ]),
              )
            else
              ..._banners.map((b) => _BannerRow(
                    banner: b,
                    storeName: _storeName(b['store_id'] as String?),
                    parseColor: _parseColor,
                    onEdit: () => _edit(banner: b),
                    onDelete: () => _delete(b),
                  )),
          ],
        ),
      ),
    );
  }
}

class _BannerRow extends StatelessWidget {
  const _BannerRow({
    required this.banner,
    required this.storeName,
    required this.parseColor,
    required this.onEdit,
    required this.onDelete,
  });
  final Map<String, dynamic> banner;
  final String storeName;
  final Color Function(String?) parseColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = parseColor(banner['background_color'] as String?);
    final imageUrl = banner['image_url'] as String?;
    final isActive = banner['is_active'] as bool? ?? true;
    final isGlobal = banner['is_global'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 80, height: 60,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.image, color: Colors.white))
              : const Icon(Icons.image, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(
                  (banner['title'] as String?) ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                )),
                if (!isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('NoFaol',
                        style: TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.w800)),
                  ),
              ]),
              const SizedBox(height: 2),
              Text(
                (banner['subtitle'] as String?) ?? '',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(children: [
                Icon(
                  isGlobal ? Icons.public : Icons.storefront,
                  size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(isGlobal ? 'Global' : storeName,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ]),
            ],
          ),
        ),
        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
        IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: onDelete),
      ]),
    );
  }
}
