import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/remote_api_service.dart';
import '../../../ui/theme.dart';

class ActivityLogsPage extends StatefulWidget {
  const ActivityLogsPage({super.key});

  @override
  State<ActivityLogsPage> createState() => _ActivityLogsPageState();
}

class _ActivityLogsPageState extends State<ActivityLogsPage> {
  final _api = RemoteApiService();
  final _dt = DateFormat('dd.MM.yyyy HH:mm');
  List<Map<String, dynamic>> _logs = const [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _logs = await _api.fetchActivityLogs(limit: 100); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  IconData _iconFor(String action) {
    switch (action) {
      case 'login': return Icons.login_rounded;
      case 'logout': return Icons.logout_rounded;
      case 'block_store': return Icons.block_rounded;
      case 'unblock_store': return Icons.check_circle_outline_rounded;
      case 'create_store': return Icons.add_business_rounded;
      case 'delete_store': return Icons.delete_outline_rounded;
      case 'create_product': return Icons.inventory_2_outlined;
      case 'update_product': return Icons.edit_note_rounded;
      case 'order_status_change': return Icons.swap_horiz_rounded;
      default: return Icons.history_rounded;
    }
  }

  Color _colorFor(String action) {
    if (action.contains('block') || action.contains('delete')) return AppColors.danger;
    if (action.contains('create') || action.contains('unblock')) return const Color(0xFF10B981);
    if (action == 'login' || action == 'logout') return AppColors.primary;
    return AppColors.textMuted;
  }

  String _labelFor(String action) {
    switch (action) {
      case 'login': return 'Tizimga kirdi';
      case 'logout': return 'Tizimdan chiqdi';
      case 'block_store': return 'Do\'konni bloklаdi';
      case 'unblock_store': return 'Do\'konni qaytardi';
      case 'create_store': return 'Do\'kon yaratdi';
      case 'delete_store': return 'Do\'kon o\'chirdi';
      case 'create_product': return 'Mahsulot qo\'shdi';
      case 'update_product': return 'Mahsulot tahrirladi';
      case 'order_status_change': return 'Buyurtma holatini o\'zgartirdi';
      default: return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_logs.isEmpty) return const Center(child: Text('Faollik tarixi bo\'sh'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _logs.length,
        separatorBuilder: (_, i) => const SizedBox(height: 4),
        itemBuilder: (_, i) {
          final log = _logs[i];
          final action = (log['action'] as String?) ?? '';
          final role = (log['actor_role'] as String?) ?? '';
          final time = DateTime.tryParse((log['created_at'] as String?) ?? '');
          final c = _colorFor(action);
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(_iconFor(action), color: c, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_labelFor(action), style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${role.toUpperCase()} · ${time != null ? _dt.format(time.toLocal()) : "—"}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}
