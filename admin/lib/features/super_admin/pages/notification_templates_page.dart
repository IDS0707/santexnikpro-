import 'package:flutter/material.dart';

import '../../../data/remote_api_service.dart';
import '../../../ui/theme.dart';

class NotificationTemplatesPage extends StatefulWidget {
  const NotificationTemplatesPage({super.key});

  @override
  State<NotificationTemplatesPage> createState() =>
      _NotificationTemplatesPageState();
}

class _NotificationTemplatesPageState
    extends State<NotificationTemplatesPage> {
  final _api = RemoteApiService();
  List<Map<String, dynamic>> _templates = const [];
  bool _loading = true;
  String _lang = 'uz';

  static const _langs = {
    'uz': 'O\'zbekcha (Lotin)',
    'uz_cyrl': 'Ўзбекча (Кирилл)',
    'ru': 'Русский',
  };

  static const _eventLabels = {
    'order_pending': 'Buyurtma qabul qilindi',
    'order_processing': 'Yetkazilmoqda',
    'order_completed': 'Yetkazildi (rahmat + ball)',
    'order_cancelled': 'Bekor qilindi',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Global templates (store_id = null)
      _templates = await _api.fetchNotificationTemplates();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered =>
      _templates.where((t) => t['language'] == _lang).toList();

  Future<void> _edit(Map<String, dynamic> tpl) async {
    final titleCtrl = TextEditingController(text: tpl['title'] as String? ?? '');
    final bodyCtrl = TextEditingController(text: tpl['body'] as String? ?? '');
    final event = tpl['event'] as String;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_eventLabels[event] ?? event),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Til: ${_langs[_lang]}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Sarlavha'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Matn',
                  helperText: '{points} = to\'plangan ball, {total} = summa, {order_id} = buyurtma raqami',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Saqlash')),
        ],
      ),
    );

    if (saved != true) return;
    final payload = {
      if (tpl['id'] != null) 'id': tpl['id'],
      'event': event,
      'language': _lang,
      'title': titleCtrl.text.trim(),
      'body': bodyCtrl.text.trim(),
      'store_id': null,
      'is_active': true,
    };
    try {
      await _api.upsertNotificationTemplate(payload);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saqlandi')));
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
            Row(children: const [
              Icon(Icons.notifications_active_outlined, size: 28, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(child: Text('Bildirishnoma matnlari',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
            ]),
            const SizedBox(height: 8),
            const Text(
              'Buyurtma holati o\'zgarganda mijozga keladigan bildirishnoma matnlari. Har bir til uchun alohida.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            // Language tabs
            Wrap(
              spacing: 8,
              children: _langs.entries.map((e) {
                final selected = _lang == e.key;
                return ChoiceChip(
                  label: Text(e.value),
                  selected: selected,
                  onSelected: (_) => setState(() => _lang = e.key),
                  selectedColor: AppColors.primary.withValues(alpha: 0.18),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.primary : AppColors.textMuted,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ..._eventLabels.entries.map((entry) {
              final event = entry.key;
              final tpl = _filtered.firstWhere(
                (t) => t['event'] == event,
                orElse: () => {'event': event, 'language': _lang, 'title': '', 'body': ''},
              );
              return _TemplateCard(
                eventLabel: entry.value,
                event: event,
                title: tpl['title'] as String? ?? '',
                body: tpl['body'] as String? ?? '',
                onEdit: () => _edit(tpl),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.eventLabel,
    required this.event,
    required this.title,
    required this.body,
    required this.onEdit,
  });

  final String eventLabel;
  final String event;
  final String title;
  final String body;
  final VoidCallback onEdit;

  IconData get _icon {
    switch (event) {
      case 'order_pending': return Icons.shopping_bag_outlined;
      case 'order_processing': return Icons.local_shipping_outlined;
      case 'order_completed': return Icons.check_circle_outline;
      case 'order_cancelled': return Icons.cancel_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color get _color {
    switch (event) {
      case 'order_pending': return const Color(0xFF2563EB);
      case 'order_processing': return const Color(0xFFF59E0B);
      case 'order_completed': return const Color(0xFF10B981);
      case 'order_cancelled': return const Color(0xFFEF4444);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final empty = title.isEmpty && body.isEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eventLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                if (empty)
                  const Text('(bo\'sh — standart matn ishlatiladi)',
                      style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textMuted, fontSize: 13))
                else ...[
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(body, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                ],
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
        ],
      ),
    );
  }
}
