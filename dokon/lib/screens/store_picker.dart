import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';

class StorePickerScreen extends StatefulWidget {
  const StorePickerScreen({super.key});
  @override
  State<StorePickerScreen> createState() => _StorePickerScreenState();
}

class _StorePickerScreenState extends State<StorePickerScreen> {
  late Future<List<StoreInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.stores();
  }

  void _reload() => setState(() => _future = Api.stores());

  Future<void> _openStore(StoreInfo s) async {
    final pwController = TextEditingController();
    bool loading = false;
    String? error;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(children: [
            const Icon(Icons.lock_outline, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(s.name, style: const TextStyle(fontSize: 16))),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Do\'kon parolini kiriting', style: TextStyle(color: AppColors.grayLight, fontSize: 13)),
              const SizedBox(height: 14),
              TextField(
                controller: pwController,
                obscureText: true,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Parol',
                  prefixIcon: const Icon(Icons.key_outlined),
                  errorText: error,
                ),
                onSubmitted: (_) {},
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor')),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      setSt(() {
                        loading = true;
                        error = null;
                      });
                      try {
                        final store = await Api.storeLogin(s.id, pwController.text.trim());
                        if (!ctx.mounted) return;
                        await context.read<AppState>().setStore(store.id, store.name);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setSt(() {
                          loading = false;
                          error = "Parol noto'g'ri";
                        });
                      }
                    },
              child: loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Kirish'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Do'konni tanlang", style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Chiqish',
            onPressed: () => st.logout(),
            icon: const Icon(Icons.logout, size: 20),
          ),
        ],
      ),
      body: FutureBuilder<List<StoreInfo>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _error('${snap.error}');
          }
          final stores = snap.data ?? [];
          if (stores.isEmpty) return _error('Hozircha do\'kon yo\'q');
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: stores.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final s = stores[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openStore(s),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.store, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              if (s.address != null && s.address!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(children: [
                                  Icon(Icons.location_on_outlined, size: 14, color: AppColors.grayLight),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(s.address!, style: TextStyle(color: AppColors.grayLight, fontSize: 12))),
                                ]),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.lock_outline, size: 18, color: AppColors.grayLight),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _error(String msg) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: AppColors.grayLight),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _reload, child: const Text('Qayta urinish')),
          ],
        ),
      );
}
