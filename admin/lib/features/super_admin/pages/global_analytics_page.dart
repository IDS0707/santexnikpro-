import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../data/models.dart';
import '../../../data/remote_api_service.dart';
import '../../../ui/theme.dart';

enum AnalyticsPeriod { today, week, month, year, custom }

class _LineSeries {
  final String storeId;
  final String storeName;
  final List<DailyPoint> points;
  final Color color;
  const _LineSeries({
    required this.storeId,
    required this.storeName,
    required this.points,
    required this.color,
  });
}

class GlobalAnalyticsPage extends StatefulWidget {
  const GlobalAnalyticsPage({super.key});

  @override
  State<GlobalAnalyticsPage> createState() => _GlobalAnalyticsPageState();
}

class _GlobalAnalyticsPageState extends State<GlobalAnalyticsPage> {
  final _api = RemoteApiService();
  final _money = NumberFormat('#,###', 'uz');
  final _dateFmt = DateFormat('dd MMM');

  // Filters
  AnalyticsPeriod _period = AnalyticsPeriod.month;
  DateTime? _customFrom;
  DateTime? _customTo;
  String? _focusStoreId; // null = all stores (aggregate top-stats)
  final Set<String> _compareStoreIds = <String>{}; // up to 4 for chart

  // Data
  List<StoreSummary> _stores = const [];
  PeriodStats _stats = PeriodStats.empty;
  List<_LineSeries> _series = const [];
  List<TopProduct> _topByQty = const [];
  List<TopProduct> _topByRev = const [];
  bool _loading = true;

  static const List<Color> _palette = [
    Color(0xFF2563EB),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      _stores = await _api.fetchStoresSummary();
      // Default: pick top 2 stores for compare
      _compareStoreIds.clear();
      for (final s in _stores.take(2)) {
        _compareStoreIds.add(s.id);
      }
    } catch (_) {}
    await _load();
  }

  ({DateTime from, DateTime to}) _range() {
    final now = DateTime.now();
    switch (_period) {
      case AnalyticsPeriod.today:
        final start = DateTime(now.year, now.month, now.day);
        return (from: start, to: start.add(const Duration(days: 1)));
      case AnalyticsPeriod.week:
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        return (from: start, to: now.add(const Duration(seconds: 1)));
      case AnalyticsPeriod.month:
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 29));
        return (from: start, to: now.add(const Duration(seconds: 1)));
      case AnalyticsPeriod.year:
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 364));
        return (from: start, to: now.add(const Duration(seconds: 1)));
      case AnalyticsPeriod.custom:
        final start = _customFrom ?? DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 30));
        final end = _customTo ?? now;
        return (from: start, to: end.add(const Duration(days: 1)));
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = _range();

      // Top-line stats
      final stats = await _api.fetchPeriodStats(
        from: r.from,
        to: r.to,
        storeId: _focusStoreId,
      );

      // Multi-line series (up to 4 stores)
      final compareList = _compareStoreIds.toList();
      final futures = <Future<List<DailyPoint>>>[];
      for (final id in compareList) {
        futures.add(_api.fetchDailyRevenue(from: r.from, to: r.to, storeId: id));
      }
      final pointsList = futures.isEmpty ? <List<DailyPoint>>[] : await Future.wait(futures);

      final series = <_LineSeries>[];
      for (var i = 0; i < compareList.length; i++) {
        final id = compareList[i];
        final store = _stores.firstWhere((s) => s.id == id,
            orElse: () => _stores.first);
        series.add(_LineSeries(
          storeId: id,
          storeName: store.name,
          points: pointsList[i],
          color: _palette[i % _palette.length],
        ));
      }

      // Top products
      final byQty = await _api.fetchTopProductsByQuantity(
        from: r.from,
        to: r.to,
        storeId: _focusStoreId,
        limit: 10,
      );
      final byRev = await _api.fetchTopProductsByRevenue(
        from: r.from,
        to: r.to,
        storeId: _focusStoreId,
        limit: 10,
      );

      if (!mounted) return;
      setState(() {
        _stats = stats;
        _series = series;
        _topByQty = byQty;
        _topByRev = byRev;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtMoney(num v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return _money.format(v.toInt());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _stats == PeriodStats.empty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 16),
            _filters(),
            const SizedBox(height: 24),
            _metricCards(),
            const SizedBox(height: 24),
            _comparisonChartCard(),
            const SizedBox(height: 24),
            _topProductsCards(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Icon(Icons.insights_rounded, size: 28, color: AppColors.primary),
        const SizedBox(width: 10),
        const Expanded(
          child: Text('Analitika',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        ),
        if (_loading)
          const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _filters() {
    final r = _range();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Davr', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _periodChip(AnalyticsPeriod.today, 'Bugun'),
              _periodChip(AnalyticsPeriod.week, 'Hafta'),
              _periodChip(AnalyticsPeriod.month, 'Oy'),
              _periodChip(AnalyticsPeriod.year, 'Yil'),
              ActionChip(
                avatar: const Icon(Icons.date_range, size: 16),
                label: Text(_period == AnalyticsPeriod.custom &&
                        _customFrom != null && _customTo != null
                    ? '${_dateFmt.format(_customFrom!)} → ${_dateFmt.format(_customTo!)}'
                    : 'Tanlash'),
                backgroundColor: _period == AnalyticsPeriod.custom
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : null,
                onPressed: _pickCustomRange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14,
                  color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                '${_dateFmt.format(r.from)} → ${_dateFmt.format(r.to.subtract(const Duration(seconds: 1)))}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const Spacer(),
              _storeSelector(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodChip(AnalyticsPeriod p, String label) {
    final selected = _period == p;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _period = p);
        _load();
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? AppColors.primary : AppColors.textMuted,
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = DateTimeRange(
      start: _customFrom ?? now.subtract(const Duration(days: 30)),
      end: _customTo ?? now,
    );
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _period = AnalyticsPeriod.custom;
        _customFrom = picked.start;
        _customTo = picked.end;
      });
      _load();
    }
  }

  Widget _storeSelector() {
    return PopupMenuButton<String?>(
      tooltip: 'Top stats uchun do\'kon tanlash',
      itemBuilder: (ctx) => [
        const PopupMenuItem<String?>(value: null, child: Text('Hammasi (umumiy)')),
        ..._stores.map((s) => PopupMenuItem<String?>(value: s.id, child: Text(s.name))),
      ],
      onSelected: (v) {
        setState(() => _focusStoreId = v);
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              _focusStoreId == null
                  ? 'Hammasi'
                  : _stores.firstWhere((s) => s.id == _focusStoreId,
                      orElse: () => _stores.first).name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _metricCards() {
    final cs = MediaQuery.of(context).size.width >= 980 ? 4 : 2;
    final items = [
      _Metric(
        icon: Icons.payments_rounded,
        color: const Color(0xFF10B981),
        label: 'Umumiy aylanma',
        value: '${_money.format(_stats.totalRevenue.toInt())} UZS',
      ),
      _Metric(
        icon: Icons.shopping_bag_rounded,
        color: const Color(0xFF2563EB),
        label: 'Buyurtmalar',
        value: '${_stats.totalOrders}',
        sub: '${_stats.completedOrders} bajarildi · ${_stats.pendingOrders} kutmoqda',
      ),
      _Metric(
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF6366F1),
        label: 'O\'rtacha chek',
        value: '${_money.format(_stats.avgOrder.toInt())} UZS',
      ),
      _Metric(
        icon: Icons.percent_rounded,
        color: const Color(0xFFF59E0B),
        label: 'Platforma komissiyasi',
        value: '${_money.format(_stats.totalCommission.toInt())} UZS',
      ),
    ];
    return GridView.count(
      crossAxisCount: cs,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.6,
      children: items,
    );
  }

  Widget _comparisonChartCard() {
    return Container(
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
              const Expanded(
                child: Text('Do\'konlarni solishtirish',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Text(
                '${_compareStoreIds.length}/4 do\'kon tanlangan',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Diagrammada solishtirish uchun 4 tagacha do\'kon qo\'shing',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _stores.map((s) {
              final selected = _compareStoreIds.contains(s.id);
              final idx = _compareStoreIds.toList().indexOf(s.id);
              final color = selected && idx >= 0
                  ? _palette[idx % _palette.length]
                  : Colors.transparent;
              return FilterChip(
                label: Text(s.name),
                avatar: selected
                    ? CircleAvatar(backgroundColor: color, radius: 6)
                    : const Icon(Icons.add, size: 14),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      if (_compareStoreIds.length >= 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Maksimum 4 ta do\'kon tanlash mumkin')),
                        );
                        return;
                      }
                      _compareStoreIds.add(s.id);
                    } else {
                      _compareStoreIds.remove(s.id);
                    }
                  });
                  _load();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 280, child: _buildLineChart()),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _series.map((s) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 14, height: 4,
                    color: s.color),
                const SizedBox(width: 6),
                Text(s.storeName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    if (_series.isEmpty) {
      return const Center(
        child: Text('Solishtirish uchun do\'kon tanlang',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }

    // Build unified x-axis (dates from range)
    final r = _range();
    final days = <DateTime>[];
    var d = DateTime(r.from.year, r.from.month, r.from.day);
    final end = r.to;
    while (d.isBefore(end)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }

    // For each series → list of FlSpot
    final lineBars = <LineChartBarData>[];
    double maxY = 0;
    for (final s in _series) {
      final spots = <FlSpot>[];
      for (var i = 0; i < days.length; i++) {
        final day = days[i];
        final match = s.points.where((p) =>
            p.day.year == day.year && p.day.month == day.month && p.day.day == day.day);
        final value = match.isEmpty ? 0.0 : match.first.revenue;
        spots.add(FlSpot(i.toDouble(), value));
        if (value > maxY) maxY = value;
      }
      lineBars.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        color: s.color,
        barWidth: 2.5,
        dotData: FlDotData(
          show: days.length <= 14,
          getDotPainter: (spot, _, a, b) => FlDotCirclePainter(
            radius: 3, color: s.color, strokeWidth: 0,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: s.color.withValues(alpha: 0.07),
        ),
      ));
    }

    return LineChart(
      LineChartData(
        lineBarsData: lineBars,
        minY: 0,
        maxY: maxY == 0 ? 100 : maxY * 1.15,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (v, _) => Text(_fmtMoney(v),
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (days.length / 6).ceilToDouble().clamp(1, 30),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_dateFmt.format(days[i]),
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.black87,
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) => spots.map((spot) {
              final s = _series[spot.barIndex];
              final dayIdx = spot.x.toInt();
              final dayLabel = dayIdx >= 0 && dayIdx < days.length
                  ? _dateFmt.format(days[dayIdx]) : '';
              return LineTooltipItem(
                '${s.storeName}\n$dayLabel\n${_money.format(spot.y.toInt())} UZS',
                TextStyle(color: s.color, fontWeight: FontWeight.w700, fontSize: 11),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _topProductsCards() {
    final wide = MediaQuery.of(context).size.width >= 980;
    final cards = [
      _TopProductsCard(
        title: 'Eng ko\'p sotilgan (sondan)',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFEF4444),
        items: _topByQty,
        sortKey: 'qty',
        money: _money,
      ),
      _TopProductsCard(
        title: 'Eng foydali (daromad bo\'yicha)',
        icon: Icons.diamond_rounded,
        color: const Color(0xFF8B5CF6),
        items: _topByRev,
        sortKey: 'rev',
        money: _money,
      ),
    ];
    if (wide) {
      return Row(children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 16),
        Expanded(child: cards[1]),
      ]);
    }
    return Column(
      children: [
        cards[0],
        const SizedBox(height: 16),
        cards[1],
      ],
    );
  }
}

// ─── Widgets ────────────────────────────────────────────────────────────────

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.sub,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(sub!,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.sortKey,
    required this.money,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<TopProduct> items;
  final String sortKey; // 'qty' or 'rev'
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text('Ma\'lumot yo\'q',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ...items.asMap().entries.map((e) {
              final p = e.value;
              final rank = e.key + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 24, height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rank <= 3
                            ? color.withValues(alpha: 0.14)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$rank',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: rank <= 3 ? color : AppColors.textMuted,
                          )),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          if (p.storeName.isNotEmpty)
                            Text(p.storeName,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          sortKey == 'qty'
                              ? '${p.totalQuantity} dona'
                              : '${money.format(p.totalRevenue.toInt())} UZS',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        Text(
                          sortKey == 'qty'
                              ? '${money.format(p.totalRevenue.toInt())} UZS'
                              : '${p.totalQuantity} dona',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
