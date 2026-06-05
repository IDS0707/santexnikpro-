import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/state/app_scope.dart';
import '../../app/state/app_store.dart';
import '../../core/responsive.dart';
import '../../data/models.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

class DriverPage extends StatefulWidget {
  const DriverPage({super.key});

  @override
  State<DriverPage> createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  @override
  Widget build(BuildContext context) {
    final store = AppScope.watch(context);
    final driver = store.currentDriver;
    if (driver == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Haydovchi sessiyasi topilmadi'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => store.logout(),
                child: const Text('Qayta kirish'),
              ),
            ],
          ),
        ),
      );
    }

    final assignedOrder = store.orders
        .where(
          (o) =>
              o.driverId == driver.id &&
              (o.status == OrderStatus.pending ||
                  o.status == OrderStatus.processing),
        )
        .toList()
        .let((list) => list.isEmpty ? null : list.first);

    final formatter = NumberFormat('#,###', 'uz');
    final isMobile = ResponsiveHelper.isMobile(context);
    final horizontalPadding = ResponsiveHelper.getHorizontalPadding(context);
    final verticalPadding = ResponsiveHelper.getVerticalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Haydovchi paneli',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => store.logout(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Chiqish'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          children: [
            SurfaceCard(
              child: Row(
                children: [
                  Container(
                    width: isMobile ? 60 : 70,
                    height: isMobile ? 60 : 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primarySoft],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        driver.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: isMobile ? 24 : 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.name,
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              driver.vehicleNumber,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              driver.phone,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: driver.status.label,
                    foreground: driverStatusColor(driver.status),
                    background: driverStatusBackground(driver.status),
                  ),
                ],
              ),
            ),
            SizedBox(height: verticalPadding),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    title: 'Bajarilgan yetkazib berish',
                    value: '${driver.completedOrders}',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MetricTile(
                    title: 'Reyting',
                    value: driver.rating.toStringAsFixed(1),
                    icon: Icons.star_rounded,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            SizedBox(height: verticalPadding),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Holatni o\'zgartirish',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Joriy holat: ${driver.status.label}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: driver.status == DriverStatus.free
                              ? null
                              : () => _updateStatus(
                                  store,
                                  driver,
                                  DriverStatus.free,
                                ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Bo\'shman'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),
                            foregroundColor: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: driver.status == DriverStatus.busy
                              ? null
                              : () => _updateStatus(
                                  store,
                                  driver,
                                  DriverStatus.busy,
                                ),
                          icon: const Icon(Icons.schedule),
                          label: const Text('Bandman'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orange),
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: verticalPadding),
            if (assignedOrder == null)
              const SurfaceCard(
                child: EmptyPlaceholder(
                  icon: Icons.local_shipping_outlined,
                  title: 'Aktiv buyurtma yo\'q',
                  subtitle:
                      'Admin yangi buyurtma tayinlagandan keyin shu yerda ko\'rinadi.',
                ),
              )
            else
              _OrderCard(
                order: assignedOrder,
                driver: driver,
                formatter: formatter,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(
    AppStore store,
    DriverProfile driver,
    DriverStatus newStatus,
  ) async {
    await store.updateDriverStatus(driver.id, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Holat "${newStatus.label}"ga o\'zgartirildi')),
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.driver,
    required this.formatter,
  });

  final OrderRecord order;
  final DriverProfile driver;
  final NumberFormat formatter;

  bool get _awaitingAccept => order.status == OrderStatus.pending;

  Future<void> _openMap(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final Uri uri;
    if (order.latitude != null && order.longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${order.latitude},${order.longitude}&travelmode=driving',
      );
    } else {
      final address = Uri.encodeComponent(order.address);
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$address&travelmode=driving',
      );
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Xaritani ochib bo\'lmadi')),
      );
    }
  }

  Future<void> _accept(BuildContext context) async {
    final store = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    await store.driverAcceptOrder(orderId: order.id, driverId: driver.id);
    messenger.showSnackBar(
      SnackBar(content: Text('${order.id} qabul qilindi')),
    );
  }

  Future<void> _reject(BuildContext context) async {
    final store = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rad etilsinmi?'),
        content: const Text('Buyurtma boshqa haydovchiga yo\'naltiriladi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rad etish'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await store.driverRejectOrder(orderId: order.id, driverId: driver.id);
    messenger.showSnackBar(
      SnackBar(content: Text('${order.id} rad etildi')),
    );
  }

  Future<void> _complete(BuildContext context) async {
    final store = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    await store.completeDelivery(order.id, driver.id);
    messenger.showSnackBar(
      SnackBar(content: Text('${order.id} yetkazildi deb belgilandi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_awaitingAccept)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.warning,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Yangi buyurtma tayinlandi! Qabul qiling yoki rad eting.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.id,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt),
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: order.status.label,
                foreground: orderStatusColor(order.status),
                background: orderStatusBackground(order.status),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            order.customerName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                order.phone,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.address,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Mahsulotlar',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Nomi',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Soni',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Narx',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                ...order.items.map(
                  (item) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(item.name),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text('${item.quantity}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text('${formatter.format(item.price)} so\'m'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Jami summa:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${formatter.format(order.total)} so\'m',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_awaitingAccept)
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 480;
                final buttons = [
                  ElevatedButton.icon(
                    onPressed: () => _accept(context),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Qabul qilish'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _reject(context),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Rad etish'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ];
                if (stacked) {
                  return Column(
                    children: [
                      SizedBox(width: double.infinity, child: buttons[0]),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: buttons[1]),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: buttons[0]),
                    const SizedBox(width: 10),
                    Expanded(child: buttons[1]),
                  ],
                );
              },
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 480;
                final mapBtn = ElevatedButton.icon(
                  onPressed: () => _openMap(context),
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('Yo\'nalishni boshlash'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                );
                final completeBtn = OutlinedButton.icon(
                  onPressed: () => _complete(context),
                  icon: const Icon(Icons.task_alt_rounded),
                  label: const Text('Yetkazildi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                );
                if (stacked) {
                  return Column(
                    children: [
                      SizedBox(width: double.infinity, child: mapBtn),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: completeBtn),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: mapBtn),
                    const SizedBox(width: 10),
                    Expanded(child: completeBtn),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
