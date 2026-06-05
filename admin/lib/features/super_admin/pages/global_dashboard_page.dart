import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../data/models.dart';
import '../../../data/remote_api_service.dart';
import '../../../ui/theme.dart';

class GlobalDashboardPage extends StatefulWidget {
  const GlobalDashboardPage({super.key, this.onOpenStore});

  final ValueChanged<String>? onOpenStore;

  @override
  State<GlobalDashboardPage> createState() => _GlobalDashboardPageState();
}

class _GlobalDashboardPageState extends State<GlobalDashboardPage> {
  GlobalStats? _stats;
  List<TopStore> _top = const [];
  List<StoreSummary> _stores = const [];
  bool _loading = true;
  String? _error;

  final _api = RemoteApiService();
  final _money = NumberFormat('#,###', 'uz');

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
      final results = await Future.wait([
        _api.fetchGlobalStats(),
        _api.fetchTopStores(limit: 5),
        _api.fetchStoresSummary(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as GlobalStats;
        _top = results[1] as List<TopStore>;
        _stores = results[2] as List<StoreSummary>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.danger),
            const SizedBox(height: 12),
            Text('Xato: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Qayta urinish'),
            ),
          ],
        ),
      );
    }

    final stats = _stats!;
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Top stat cards row ───
            LayoutBuilder(builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 720;
              final cards = [
                _StatCard(
                  label: 'Bugungi savdo',
                  value: '${_money.format(stats.totalRevenue.toInt())} so\'m',
                  delta: '+12.5%',
                  deltaPositive: true,
                  icon: Icons.trending_up_rounded,
                  gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                _StatCard(
                  label: 'Umumiy savdo (oy)',
                  value: '${_money.format(stats.totalRevenue.toInt())} so\'m',
                  delta: '+18.7%',
                  deltaPositive: true,
                  icon: Icons.account_balance_wallet_rounded,
                  gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                ),
                _StatCard(
                  label: 'Buyurtmalar',
                  value: _money.format(stats.totalOrders),
                  delta: 'Faol: ${stats.pendingOrders}',
                  deltaPositive: true,
                  icon: Icons.receipt_long_rounded,
                  gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                ),
                _StatCard(
                  label: 'Foyda (komissiya)',
                  value: '${_money.format(stats.totalCommission.toInt())} so\'m',
                  delta: 'Platforma daromadi',
                  deltaPositive: true,
                  icon: Icons.paid_rounded,
                  gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
              ];
              if (isMobile) {
                return Column(
                  children: cards.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: c,
                  )).toList(),
                );
              }
              return Row(
                children: cards.expand((c) sync* {
                  yield Expanded(child: c);
                  if (c != cards.last) yield const SizedBox(width: 16);
                }).toList(),
              );
            }),

            const SizedBox(height: 24),

            // ─── Charts row ───
            LayoutBuilder(builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 980;
              final chart = _SalesChart(_top, money: _money);
              final pie = _StoresActivityCard(stats: stats, money: _money);
              if (isMobile) {
                return Column(children: [chart, const SizedBox(height: 16), pie]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: chart),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: pie),
                ],
              );
            }),

            const SizedBox(height: 24),

            // ─── Eng ko'p sotgan do'konlar ──
            _SectionTitle(title: 'Eng ko\'p sotgan do\'konlar'),
            const SizedBox(height: 12),
            _TopStoresTable(stores: _top, money: _money),

            const SizedBox(height: 24),

            // ─── Do'konlar holati ──
            _SectionTitle(title: 'Do\'konlar holati', actionLabel: 'Hammasini ko\'rish'),
            const SizedBox(height: 12),
            _StoresGrid(stores: _stores, money: _money),
          ],
        ),
      ),
    );
  }
}

// ─── Stat card ───────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaPositive,
    required this.icon,
    required this.gradient,
  });

  final String label;
  final String value;
  final String delta;
  final bool deltaPositive;
  final IconData icon;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (deltaPositive ? const Color(0xFF10B981) : AppColors.danger)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  delta,
                  style: TextStyle(
                    color: deltaPositive ? const Color(0xFF059669) : AppColors.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.dark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sales bar chart ─────────────────────────────────────────────────────────
class _SalesChart extends StatelessWidget {
  const _SalesChart(this.stores, {required this.money});
  final List<TopStore> stores;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final values = stores.map((s) => s.totalRevenue).toList();
    final maxV = values.isEmpty ? 100.0 : (values.reduce((a, b) => a > b ? a : b));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Oylik daromad',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Bu oy', style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                )),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: stores.isEmpty
                ? const Center(child: Text('Ma\'lumot yo\'q'))
                : BarChart(
                    BarChartData(
                      maxY: maxV * 1.2,
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, _) {
                              final i = value.toInt();
                              if (i < 0 || i >= stores.length) return const SizedBox();
                              final name = stores[i].storeName;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  name.length > 10 ? '${name.substring(0, 10)}…' : name,
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(stores.length, (i) {
                        return BarChartGroupData(x: i, barRods: [
                          BarChartRodData(
                            toY: stores[i].totalRevenue,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 22,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ]);
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Store activity pie ──────────────────────────────────────────────────────
class _StoresActivityCard extends StatelessWidget {
  const _StoresActivityCard({required this.stats, required this.money});
  final GlobalStats stats;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final total = stats.totalStores == 0 ? 1 : stats.totalStores;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Do\'konlar holati',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 56,
                    sections: [
                      PieChartSectionData(
                        value: stats.activeStores.toDouble(),
                        color: const Color(0xFF10B981),
                        title: '',
                        radius: 28,
                      ),
                      PieChartSectionData(
                        value: stats.blockedStores.toDouble(),
                        color: const Color(0xFFEF4444),
                        title: '',
                        radius: 28,
                      ),
                      if (stats.totalStores - stats.activeStores - stats.blockedStores > 0)
                        PieChartSectionData(
                          value: (stats.totalStores - stats.activeStores - stats.blockedStores).toDouble(),
                          color: const Color(0xFFF59E0B),
                          title: '',
                          radius: 28,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${stats.totalStores}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                    const Text('do\'kon',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _LegendRow(label: 'Faol', value: '${stats.activeStores}', percent: stats.activeStores * 100 ~/ total, color: const Color(0xFF10B981)),
          const SizedBox(height: 8),
          _LegendRow(label: 'Bloklangan', value: '${stats.blockedStores}', percent: stats.blockedStores * 100 ~/ total, color: const Color(0xFFEF4444)),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.label, required this.value, required this.percent, required this.color});
  final String label;
  final String value;
  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(width: 8),
        Text('$percent%', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}

// ─── Section title ──────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel});
  final String title;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const Spacer(),
        if (actionLabel != null)
          Text(actionLabel!,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}

// ─── Top stores table ────────────────────────────────────────────────────────
class _TopStoresTable extends StatelessWidget {
  const _TopStoresTable({required this.stores, required this.money});
  final List<TopStore> stores;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: Text('Hozircha do\'kon yo\'q')),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('DO\'KON', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                Expanded(flex: 2, child: Text('BUYURTMA', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                Expanded(flex: 2, child: Text('DAROMAD', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                Expanded(flex: 2, child: Text('KOMISSIYA', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
              ],
            ),
          ),
          ...stores.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            final medalColor = i == 0
                ? const Color(0xFFFBBF24)
                : i == 1
                    ? const Color(0xFF94A3B8)
                    : i == 2
                        ? const Color(0xFFD97706)
                        : AppColors.textMuted;
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: i == stores.length - 1 ? Colors.transparent : AppColors.border,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: medalColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${i + 1}',
                                style: TextStyle(color: medalColor, fontWeight: FontWeight.w900)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(s.storeName, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(flex: 2, child: Text('${s.totalOrders}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  Expanded(flex: 2, child: Text('${money.format(s.totalRevenue.toInt())} so\'m', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                  Expanded(flex: 2, child: Text('${money.format(s.totalCommission.toInt())} so\'m', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w700, fontSize: 13))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Stores grid ─────────────────────────────────────────────────────────────
class _StoresGrid extends StatelessWidget {
  const _StoresGrid({required this.stores, required this.money});
  final List<StoreSummary> stores;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: Text('Hozircha do\'kon yo\'q')),
      );
    }
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth < 600 ? 1 : c.maxWidth < 1000 ? 2 : 3;
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.9,
        children: stores.map((s) {
          final statusColor = s.isActive ? const Color(0xFF10B981) : AppColors.danger;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text(s.slug, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        s.isActive ? 'Faol' : 'Bloklangan',
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    _MiniStat('Buyurtma', '${s.totalOrders}'),
                    const SizedBox(width: 12),
                    _MiniStat('Mahsulot', '${s.totalProducts}'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniStat('Daromad', '${money.format(s.totalRevenue.toInt())} so\'m'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      ],
    );
  }
}
