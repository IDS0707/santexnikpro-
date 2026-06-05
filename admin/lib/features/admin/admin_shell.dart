import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel_package;
import 'package:universal_html/html.dart' as html;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../data/remote_api_service.dart' show OrderWatch;

import '../../app/state/app_scope.dart';
import '../../app/state/app_store.dart';
import 'bonus_manage_view.dart';
import '../../core/responsive.dart';
import '../../core/export_service.dart';
import '../../data/models.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

enum AdminSection {
  dashboard,
  products,
  categories,
  orders,
  inventory,
  drivers,
  applications,
  bonus,
  reports,
}

class _MenuItem {
  const _MenuItem({
    required this.section,
    required this.title,
    required this.icon,
  });
  final AdminSection section;
  final String title;
  final IconData icon;
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminSection _section = AdminSection.dashboard;
  final _money = NumberFormat('#,###', 'uz');
  OrderStatus? _orderFilter;
  bool _onlyActiveDeliveries = false;

  OrderWatch? _orderChannel;
  bool _orderWatchStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_orderWatchStarted) return;
    final store = AppScope.read(context);
    if (store.session.storeId == null) return;
    _orderWatchStarted = true;
    _orderChannel = store.watchNewOrders(() async {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔔 Yangi buyurtma keldi!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 4),
        ),
      );
      try {
        await store.refreshFromServer();
      } catch (_) {}
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _orderChannel?.unsubscribe();
    super.dispose();
  }

  static const _menu = <_MenuItem>[
    _MenuItem(
      section: AdminSection.dashboard,
      title: 'Dashboard',
      icon: Icons.dashboard_rounded,
    ),
    _MenuItem(
      section: AdminSection.products,
      title: 'Mahsulotlar',
      icon: Icons.inventory_2_rounded,
    ),
    _MenuItem(
      section: AdminSection.categories,
      title: 'Kategoriyalar',
      icon: Icons.category_rounded,
    ),
    _MenuItem(
      section: AdminSection.orders,
      title: 'Buyurtmalar',
      icon: Icons.receipt_long_rounded,
    ),
    _MenuItem(
      section: AdminSection.inventory,
      title: 'Zaxira',
      icon: Icons.warehouse_rounded,
    ),
    _MenuItem(
      section: AdminSection.drivers,
      title: 'Haydovchilar',
      icon: Icons.local_shipping_rounded,
    ),
    _MenuItem(
      section: AdminSection.applications,
      title: 'Bonus arizalari',
      icon: Icons.card_giftcard_rounded,
    ),
    _MenuItem(
      section: AdminSection.bonus,
      title: 'Bonus do\'koni',
      icon: Icons.redeem_rounded,
    ),
    _MenuItem(
      section: AdminSection.reports,
      title: 'Hisobotlar',
      icon: Icons.insights_rounded,
    ),
  ];

  String get _title =>
      _menu.firstWhere((item) => item.section == _section).title;

  void _openOrders({OrderStatus? filter, bool onlyActive = false}) {
    setState(() {
      _section = AdminSection.orders;
      _orderFilter = filter;
      _onlyActiveDeliveries = onlyActive;
    });
  }

  Widget _impersonationBanner(AppStore store) {
    if (!store.session.impersonating) return const SizedBox.shrink();
    return Material(
      color: const Color(0xFF8B5CF6),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.visibility_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Super Admin sifatida ${store.session.storeName ?? 'do\'kon'} ichida ko'rib turibsiz",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await store.exitImpersonation();
                },
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 16),
                label: const Text('Super Admin paneliga qaytish',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.watch(context);
    final width = MediaQuery.of(context).size.width;
    final mobile = width < 980;

    final body = SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? 16 : 28,
          vertical: mobile ? 12 : 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderBar(
              title: _title,
              backendConnected: store.backendConnected,
              onRefresh: () async {
                await store.refreshFromServer();
                if (!context.mounted) return;
                AppToast.success(context, 'Ma\'lumotlar yangilandi');
              },
              onReset: () async {
                await store.resetDemoData();
                if (!context.mounted) return;
                AppToast.info(context, 'Demo ma\'lumotlar qayta tiklandi');
              },
              onLogout: () => store.logout(),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.02),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_section),
                  child: _buildSection(context, store),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (mobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_title, style: const TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: AppColors.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shape: const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        drawer: Drawer(
          child: _SideMenu(
            selected: _section,
            onSelect: (section) {
              Navigator.pop(context);
              setState(() {
                _section = section;
                _orderFilter = null;
                _onlyActiveDeliveries = false;
              });
            },
          ),
        ),
        body: Column(
          children: [
            _impersonationBanner(store),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _impersonationBanner(store),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 260,
                  child: _SideMenu(
                    selected: _section,
                    onSelect: (section) {
                      setState(() {
                        _section = section;
                        _orderFilter = null;
                        _onlyActiveDeliveries = false;
                      });
                    },
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, AppStore store) {
    switch (_section) {
      case AdminSection.dashboard:
        return _DashboardView(
          store: store,
          money: _money,
          onOpenOrders: () => _openOrders(),
          onOpenActiveDeliveries: () => _openOrders(onlyActive: true),
          onOpenInventory: () =>
              setState(() => _section = AdminSection.inventory),
        );
      case AdminSection.products:
        return _ProductsView(
          store: store,
          money: _money,
          onAdd: () => _showProductDialog(context, store),
          onEdit: (product) =>
              _showProductDialog(context, store, existing: product),
          onDelete: (product) => _confirmDelete(
            context,
            title: 'Mahsulot o\'chirilsinmi?',
            message: product.name,
            onConfirm: () => store.deleteProduct(product.id),
          ),
          onExport: _showProductsExportSheet,
        );
      case AdminSection.categories:
        return _CategoriesView(
          store: store,
          onAdd: () => _showCategoryDialog(context, store),
          onEdit: (category) =>
              _showCategoryDialog(context, store, existing: category),
          onDelete: (category) => _confirmDelete(
            context,
            title: 'Kategoriya o\'chirilsinmi?',
            message: '${category.name} bilan birga mahsulotlari ham o\'chadi.',
            onConfirm: () => store.deleteCategory(category.id),
          ),
        );
      case AdminSection.orders:
        return _OrdersView(
          store: store,
          money: _money,
          initialFilter: _orderFilter,
          onlyActiveDeliveries: _onlyActiveDeliveries,
          onAssign: (order) => _showAssignDriverDialog(context, store, order),
          onView: (order) => _openOrderDetails(order),
          onExportAll: _showOrdersExportSheet,
          onExportOne: _showOrderExportSheet,
        );
      case AdminSection.inventory:
        return _InventoryView(
          store: store,
          money: _money,
          onAdjust: (product, action, amount) async {
            await store.adjustInventory(
              productId: product.id,
              action: action,
              amount: amount,
            );
            if (context.mounted) {
              AppToast.success(context, 'Zaxira yangilandi');
            }
          },
          onCustomAdjust: (product) =>
              _showInventoryDialog(context, store, product),
        );
      case AdminSection.drivers:
        return _DriversView(
          store: store,
          onAdd: () => _showDriverDialog(context, store),
          onEdit: (driver) =>
              _showDriverDialog(context, store, existing: driver),
          onDelete: (driver) => _confirmDelete(
            context,
            title: 'Haydovchi o\'chirilsinmi?',
            message: driver.name,
            onConfirm: () => store.deleteDriver(driver.id),
          ),
          onCall: (driver) => _callNumber(driver.phone),
        );
      case AdminSection.applications:
        return _ApplicationsView(store: store);
      case AdminSection.bonus:
        return BonusManageView(store: store);
      case AdminSection.reports:
        return _ReportsView(store: store, money: _money);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 17))),
          ],
        ),
        content: Text(message, style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onConfirm();
      if (!context.mounted) return;
      AppToast.success(context, 'Amal bajarildi');
    }
  }

  Future<void> _showCategoryDialog(
    BuildContext context,
    AppStore store, {
    Category? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final codeController = TextEditingController(text: existing?.code ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          existing == null ? 'Kategoriya qo\'shish' : 'Kategoriyani tahrirlash',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 460,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nomi'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Kod (SKU prefiksi)'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Izoh (ixtiyoriy)'),
                  minLines: 2,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final category = Category(
                id: existing?.id ?? _id('cat'),
                name: nameController.text.trim(),
                code: codeController.text.trim(),
                description: descriptionController.text.trim(),
                icon: existing?.icon ?? 'category',
                createdAt: existing?.createdAt ?? DateTime.now(),
              );
              await store.saveCategory(category);
              if (!context.mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      AppToast.success(context, 'Kategoriya saqlandi');
    }
  }

  Future<void> _showProductDialog(
    BuildContext context,
    AppStore store, {
    Product? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final priceController = TextEditingController(
      text: existing?.price.toStringAsFixed(0) ?? '',
    );
    final oldPriceController = TextEditingController(
      text: existing?.oldPrice?.toStringAsFixed(0) ?? '',
    );
    final stockController = TextEditingController(
      text: existing?.stock.toString() ?? '0',
    );
    final skuController = TextEditingController(text: existing?.sku ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final imageController = TextEditingController(text: existing?.imageUrl ?? '');
    var selectedCategory = existing?.categoryId ??
        (store.categories.isNotEmpty ? store.categories.first.id : null);
    var selectedBadge = existing?.badge ?? ProductBadge.none;
    final formKey = GlobalKey<FormState>();
    final picker = ImagePicker();
    XFile? selectedImage;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              existing == null
                                  ? 'Yangi mahsulot'
                                  : 'Mahsulotni tahrirlash',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context, false),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 560;
                            final imageBlock = _ImagePickerArea(
                              image: selectedImage,
                              imageUrl: imageController.text.isEmpty
                                  ? null
                                  : imageController.text,
                              onPick: () async {
                                final src = await showModalBottomSheet<ImageSource>(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (_) => SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.photo_library_rounded),
                                          title: const Text('Galereyadan tanlash'),
                                          onTap: () => Navigator.pop(
                                            context,
                                            ImageSource.gallery,
                                          ),
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.camera_alt_rounded),
                                          title: const Text('Kameradan suratga olish'),
                                          onTap: () => Navigator.pop(
                                            context,
                                            ImageSource.camera,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                                if (src == null) return;
                                final image = await picker.pickImage(source: src);
                                if (image != null) {
                                  setLocalState(() {
                                    selectedImage = image;
                                    imageController.text = image.path;
                                  });
                                }
                              },
                              onClear: () => setLocalState(() {
                                selectedImage = null;
                                imageController.clear();
                              }),
                            );

                            final fields = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Mahsulot nomi',
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Majburiy maydon';
                                    }
                                    if (v.trim().length < 3) {
                                      return 'Kamida 3 ta harf bo\'lsin';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedCategory,
                                  decoration: const InputDecoration(
                                    labelText: 'Kategoriya',
                                  ),
                                  items: store.categories
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c.id,
                                          child: Text(c.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setLocalState(
                                    () => selectedCategory = v,
                                  ),
                                  validator: (v) =>
                                      v == null ? 'Kategoriya tanlang' : null,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: priceController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Narx (so\'m)',
                                        ),
                                        validator: (v) {
                                          final parsed = double.tryParse(
                                            (v ?? '').trim(),
                                          );
                                          if (parsed == null || parsed <= 0) {
                                            return '> 0 bo\'lsin';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: oldPriceController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Eski narx (ixt.)',
                                        ),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return null;
                                          }
                                          final parsed = double.tryParse(
                                            v.trim(),
                                          );
                                          final newP = double.tryParse(
                                            priceController.text.trim(),
                                          );
                                          if (parsed == null || parsed <= 0) {
                                            return 'Noto\'g\'ri';
                                          }
                                          if (newP != null && parsed <= newP) {
                                            return '> narx bo\'lsin';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: stockController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Zaxira (dona)',
                                        ),
                                        validator: (v) {
                                          final parsed = int.tryParse(
                                            (v ?? '').trim(),
                                          );
                                          if (parsed == null || parsed < 0) {
                                            return '>= 0 butun son';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: skuController,
                                        decoration: const InputDecoration(
                                          labelText: 'SKU',
                                        ),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return null;
                                          }
                                          final dup = store.products.any(
                                            (p) =>
                                                p.id != existing?.id &&
                                                p.sku.trim().toLowerCase() ==
                                                    v.trim().toLowerCase(),
                                          );
                                          if (dup) return 'SKU band';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: ProductBadge.values.map((b) {
                                    final isSel = selectedBadge == b;
                                    return ChoiceChip(
                                      label: Text(b.label),
                                      selected: isSel,
                                      onSelected: (_) =>
                                          setLocalState(() => selectedBadge = b),
                                      selectedColor: AppColors.primary,
                                      labelStyle: TextStyle(
                                        color: isSel ? Colors.white : AppColors.ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      backgroundColor: AppColors.background,
                                      side: BorderSide(
                                        color: isSel
                                            ? AppColors.primary
                                            : AppColors.border,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: descriptionController,
                                  minLines: 3,
                                  maxLines: 5,
                                  decoration: const InputDecoration(
                                    labelText: 'Tavsif (ixtiyoriy)',
                                  ),
                                ),
                              ],
                            );

                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 200, child: imageBlock),
                                  const SizedBox(width: 18),
                                  Expanded(child: fields),
                                ],
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [imageBlock, const SizedBox(height: 14), fields],
                            );
                          },
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Bekor qilish'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (!formKey.currentState!.validate() ||
                                  selectedCategory == null) {
                                return;
                              }
                              final oldPriceRaw = oldPriceController.text.trim();
                              // Rasm tanlangan bo'lsa — Supabase Storage'ga yuklab,
                              // lokal manzil emas, doimiy OMMAVIY URL saqlanadi.
                              String? imageUrl =
                                  imageController.text.trim().isEmpty
                                      ? null
                                      : imageController.text.trim();
                              if (selectedImage != null) {
                                try {
                                  final bytes =
                                      await selectedImage!.readAsBytes();
                                  imageUrl = await store.uploadProductImage(
                                      bytes, selectedImage!.name);
                                } catch (e) {
                                  if (context.mounted) {
                                    AppToast.error(context,
                                        'Rasm yuklab bo\'lmadi: $e');
                                  }
                                  return;
                                }
                              }
                              final product = Product(
                                id: existing?.id ?? _id('prd'),
                                name: nameController.text.trim(),
                                categoryId: selectedCategory!,
                                price: double.tryParse(priceController.text.trim()) ?? 0,
                                oldPrice: oldPriceRaw.isEmpty
                                    ? null
                                    : double.tryParse(oldPriceRaw),
                                stock: int.tryParse(stockController.text.trim()) ?? 0,
                                sku: skuController.text.trim(),
                                description: descriptionController.text.trim(),
                                badge: selectedBadge,
                                createdAt: existing?.createdAt ?? DateTime.now(),
                                soldCount: existing?.soldCount ?? 0,
                                imageUrl: imageUrl,
                              );
                              await store.saveProduct(product);
                              if (!context.mounted) return;
                              Navigator.pop(context, true);
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Saqlash'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (saved == true && context.mounted) {
      AppToast.success(context, 'Mahsulot saqlandi');
    }
  }

  Future<void> _showDriverDialog(
    BuildContext context,
    AppStore store, {
    DriverProfile? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final loginController = TextEditingController(text: existing?.login ?? '');
    final passwordController = TextEditingController(
      text: existing?.password ?? 'Driver123!',
    );
    final vehicleController = TextEditingController(
      text: existing?.vehicleNumber ?? '',
    );
    var status = existing?.status ?? DriverStatus.free;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            existing == null ? 'Haydovchi qo\'shish' : 'Haydovchini tahrirlash',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'To\'liq ism'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        hintText: '+998 90 123 45 67',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: loginController,
                      decoration: const InputDecoration(labelText: 'Login'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Parol'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: vehicleController,
                      decoration: const InputDecoration(labelText: 'Avto raqami'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<DriverStatus>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Holati'),
                      items: DriverStatus.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setLocalState(
                        () => status = value ?? DriverStatus.free,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Bekor'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final driver = DriverProfile(
                  id: existing?.id ?? _id('drv'),
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  login: loginController.text.trim(),
                  password: passwordController.text.trim(),
                  vehicleNumber: vehicleController.text.trim(),
                  status: status,
                  completedOrders: existing?.completedOrders ?? 0,
                  rating: existing?.rating ?? 5,
                  currentOrderId: existing?.currentOrderId,
                );
                await store.saveDriver(driver);
                if (!context.mounted) return;
                Navigator.pop(context, true);
              },
              child: const Text('Saqlash'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && context.mounted) {
      AppToast.success(context, 'Haydovchi saqlandi');
    }
  }

  Future<void> _showInventoryDialog(
    BuildContext context,
    AppStore store,
    Product product,
  ) async {
    final amountController = TextEditingController(text: '0');
    var action = InventoryAction.set;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Zaxira: ${product.name}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Joriy zaxira: ${product.stock} dona',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<InventoryAction>(
                  initialValue: action,
                  decoration: const InputDecoration(labelText: 'Amal turi'),
                  items: const [
                    DropdownMenuItem(
                      value: InventoryAction.add,
                      child: Text('Qo\'shish (+)'),
                    ),
                    DropdownMenuItem(
                      value: InventoryAction.subtract,
                      child: Text('Ayirish (-)'),
                    ),
                    DropdownMenuItem(
                      value: InventoryAction.set,
                      child: Text('Aniq qiymat o\'rnatish'),
                    ),
                  ],
                  onChanged: (value) => setLocalState(
                    () => action = value ?? InventoryAction.add,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Miqdor'),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Bekor'),
            ),
            ElevatedButton(
              onPressed: () async {
                await store.adjustInventory(
                  productId: product.id,
                  action: action,
                  amount: int.tryParse(amountController.text.trim()) ?? 0,
                );
                if (!context.mounted) return;
                Navigator.pop(context, true);
              },
              child: const Text('Yangilash'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && context.mounted) {
      AppToast.success(context, 'Zaxira yangilandi');
    }
  }

  Future<void> _showAssignDriverDialog(
    BuildContext context,
    AppStore store,
    OrderRecord order,
  ) async {
    String? selectedDriver = order.driverId ??
        (store.freeDriversSorted.isNotEmpty
            ? store.freeDriversSorted.first.id
            : null);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Haydovchi tayinlash · ${order.id}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          content: SizedBox(
            width: 460,
            child: store.drivers.isEmpty
                ? const EmptyPlaceholder(
                    icon: Icons.local_shipping_outlined,
                    title: 'Haydovchi yo\'q',
                    subtitle: 'Avval haydovchi qo\'shing',
                  )
                : DropdownButtonFormField<String>(
                    initialValue: selectedDriver,
                    decoration: const InputDecoration(
                      labelText: 'Haydovchi tanlang',
                    ),
                    items: store.drivers
                        .map(
                          (driver) => DropdownMenuItem(
                            value: driver.id,
                            child: Text(
                              '${driver.name} · ${driver.status.label}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setLocalState(() => selectedDriver = value),
                  ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Bekor'),
            ),
            ElevatedButton(
              onPressed: selectedDriver == null
                  ? null
                  : () async {
                      await store.assignDriver(
                        orderId: order.id,
                        driverId: selectedDriver!,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context, true);
                    },
              child: const Text('Tayinlash'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && context.mounted) {
      AppToast.success(context, 'Haydovchi tayinlandi');
    }
  }

  Future<void> _openOrderDetails(OrderRecord order) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailsPage(
          orderId: order.id,
          money: _money,
          onAssign: (o) => _showAssignDriverDialog(context, AppScope.read(context), o),
          onExport: _showOrderExportSheet,
          onCall: _callNumber,
          onMap: _openLocationInMap,
        ),
      ),
    );
  }

  Future<void> _callNumber(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      await url_launcher.launchUrl(uri);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Qo\'ng\'iroq qilib bo\'lmadi');
    }
  }

  void _showSaveResult(SaveResult result) {
    if (!mounted) return;
    if (!result.success) {
      AppToast.error(context, 'Saqlashda xato: ${result.message ?? 'noma\'lum'}');
      return;
    }
    if (kIsWeb) {
      AppToast.success(context, result.message ?? 'Yuklab olindi');
      return;
    }
    final path = result.path ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 6),
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Fayl saqlandi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Ochish',
          textColor: AppColors.primarySoft,
          onPressed: () => ExportService.openFile(path),
        ),
      ),
    );
  }

  Future<void> _showOrderExportSheet(OrderRecord order) async {
    final store = AppScope.read(context);
    final driverName = store.driverById(order.driverId ?? '')?.name;
    if (!mounted) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.file_download_outlined, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text(
                    'Buyurtmani saqlash',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.danger,
                ),
              ),
              title: const Text(
                'PDF formatida',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Chiroyli jadval, chop etishga tayyor'),
              onTap: () => Navigator.pop(c, 'pdf'),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.table_chart_rounded,
                  color: AppColors.success,
                ),
              ),
              title: const Text(
                'Excel (XLSX)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Tahrirlash uchun jadval ko\'rinishida'),
              onTap: () => Navigator.pop(c, 'excel'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (choice == null) return;
    if (choice == 'pdf') {
      final result = await ExportService.exportOrder(
        order,
        driverName: driverName,
      );
      _showSaveResult(result);
    } else {
      await _exportOrderToExcel(order, _money);
    }
  }

  Future<void> _showProductsExportSheet() async {
    if (!mounted) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.file_download_outlined, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text(
                    'Mahsulotlarni saqlash',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.danger,
                ),
              ),
              title: const Text(
                'PDF (jadval)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Chiroyli ko\'rinishda, chop etishga tayyor'),
              onTap: () => Navigator.pop(c, 'pdf'),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.table_chart_rounded,
                  color: AppColors.success,
                ),
              ),
              title: const Text(
                'Excel (XLSX)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Tahrirlash uchun'),
              onTap: () => Navigator.pop(c, 'excel'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'pdf') {
      final store = AppScope.read(context);
      final catMap = <String, String>{
        for (final c in store.categories) c.id: c.name,
      };
      final result = await ExportService.exportProducts(store.products, catMap);
      _showSaveResult(result);
    } else {
      await _exportAllProductsToExcel();
    }
  }

  Future<void> _showOrdersExportSheet() async {
    if (!mounted) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.file_download_outlined, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text(
                    'Barcha buyurtmalarni saqlash',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.danger,
                ),
              ),
              title: const Text(
                'PDF (jadval)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Chiroyli ko\'rinishda'),
              onTap: () => Navigator.pop(c, 'pdf'),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.table_chart_rounded,
                  color: AppColors.success,
                ),
              ),
              title: const Text(
                'Excel (XLSX)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Tahrirlash uchun'),
              onTap: () => Navigator.pop(c, 'excel'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'pdf') {
      final store = AppScope.read(context);
      final drvMap = <String, String>{
        for (final d in store.drivers) d.id: d.name,
      };
      final result = await ExportService.exportAllOrders(store.orders, drvMap);
      _showSaveResult(result);
    } else {
      await _exportAllOrdersToExcel();
    }
  }

  Future<void> _exportOrderToExcel(
    OrderRecord order,
    NumberFormat money,
  ) async {
    final excel = excel_package.Excel.createExcel();
    final sheet = excel['Sheet1'];

    sheet.appendRow([
      excel_package.TextCellValue('Buyurtma ID'),
      excel_package.TextCellValue(order.id),
    ]);
    sheet.appendRow([
      excel_package.TextCellValue('Mijoz'),
      excel_package.TextCellValue(order.customerName),
    ]);
    sheet.appendRow([
      excel_package.TextCellValue('Telefon'),
      excel_package.TextCellValue(order.phone),
    ]);
    sheet.appendRow([
      excel_package.TextCellValue('Manzil'),
      excel_package.TextCellValue(order.address),
    ]);
    sheet.appendRow([excel_package.TextCellValue('')]);

    sheet.appendRow([
      excel_package.TextCellValue('Mahsulot nomi'),
      excel_package.TextCellValue('Soni'),
      excel_package.TextCellValue('Narx'),
      excel_package.TextCellValue('Jami'),
    ]);

    for (final item in order.items) {
      sheet.appendRow([
        excel_package.TextCellValue(item.name),
        excel_package.IntCellValue(item.quantity),
        excel_package.DoubleCellValue(item.price),
        excel_package.DoubleCellValue(item.price * item.quantity),
      ]);
    }

    sheet.appendRow([excel_package.TextCellValue('')]);
    sheet.appendRow([
      excel_package.TextCellValue('Umumiy jami'),
      excel_package.TextCellValue(''),
      excel_package.TextCellValue(''),
      excel_package.DoubleCellValue(order.total),
    ]);

    final bytes = excel.encode();
    if (bytes == null) {
      if (mounted) {
        AppToast.error(context, 'Faylni yaratib bo\'lmadi');
      }
      return;
    }
    final fileName = 'buyurtma_${order.id}.xlsx';
    await _saveBytesToFile(bytes, fileName);
  }

  Future<void> _exportAllOrdersToExcel() async {
    final store = AppScope.read(context);
    final excel = excel_package.Excel.createExcel();
    final sheet = excel['Buyurtmalar'];

    sheet.appendRow([
      excel_package.TextCellValue('ID'),
      excel_package.TextCellValue('Mijoz'),
      excel_package.TextCellValue('Telefon'),
      excel_package.TextCellValue('Manzil'),
      excel_package.TextCellValue('Status'),
      excel_package.TextCellValue('Sana'),
      excel_package.TextCellValue('Mahsulotlar soni'),
      excel_package.TextCellValue('Jami summa'),
    ]);

    double grandTotal = 0;
    for (final order in store.orders) {
      grandTotal += order.total;
      final itemCount = order.items.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      );
      sheet.appendRow([
        excel_package.TextCellValue(order.id),
        excel_package.TextCellValue(order.customerName),
        excel_package.TextCellValue(order.phone),
        excel_package.TextCellValue(order.address),
        excel_package.TextCellValue(order.status.label),
        excel_package.TextCellValue(
          DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt),
        ),
        excel_package.IntCellValue(itemCount),
        excel_package.DoubleCellValue(order.total),
      ]);
    }
    sheet.appendRow([excel_package.TextCellValue('')]);
    sheet.appendRow([
      excel_package.TextCellValue('UMUMIY JAMI'),
      excel_package.TextCellValue(''),
      excel_package.TextCellValue(''),
      excel_package.TextCellValue(''),
      excel_package.TextCellValue(''),
      excel_package.TextCellValue(''),
      excel_package.TextCellValue(''),
      excel_package.DoubleCellValue(grandTotal),
    ]);

    final bytes = excel.encode();
    if (bytes == null) {
      if (mounted) {
        AppToast.error(context, 'Faylni yaratib bo\'lmadi');
      }
      return;
    }
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    await _saveBytesToFile(bytes, 'buyurtmalar_$stamp.xlsx');
  }

  Future<void> _exportAllProductsToExcel() async {
    final store = AppScope.read(context);
    final excel = excel_package.Excel.createExcel();
    final sheet = excel['Mahsulotlar'];

    sheet.appendRow([
      excel_package.TextCellValue('ID'),
      excel_package.TextCellValue('Nomi'),
      excel_package.TextCellValue('Kategoriya'),
      excel_package.TextCellValue('SKU'),
      excel_package.TextCellValue('Narx'),
      excel_package.TextCellValue('Zaxira'),
      excel_package.TextCellValue('Sotilgan'),
    ]);

    for (final product in store.products) {
      final category = store.categoryById(product.categoryId)?.name ?? '-';
      sheet.appendRow([
        excel_package.TextCellValue(product.id),
        excel_package.TextCellValue(product.name),
        excel_package.TextCellValue(category),
        excel_package.TextCellValue(product.sku),
        excel_package.DoubleCellValue(product.price),
        excel_package.IntCellValue(product.stock),
        excel_package.IntCellValue(product.soldCount),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      if (mounted) {
        AppToast.error(context, 'Faylni yaratib bo\'lmadi');
      }
      return;
    }
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    await _saveBytesToFile(bytes, 'mahsulotlar_$stamp.xlsx');
  }

  Future<void> _saveBytesToFile(List<int> bytes, String fileName) async {
    try {
      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        if (mounted) {
          AppToast.success(context, '$fileName yuklab olindi');
        }
        return;
      }
      // Try Android Downloads first.
      Directory? dir;
      if (Platform.isAndroid) {
        final downloads = Directory('/storage/emulated/0/Download');
        if (await downloads.exists()) {
          dir = downloads;
        }
      }
      if (dir == null) {
        try {
          dir = await getDownloadsDirectory();
        } catch (_) {
          dir = null;
        }
      }
      dir ??= await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}${Platform.pathSeparator}$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      _showSaveResult(SaveResult(success: true, path: filePath));
    } catch (e) {
      if (!mounted) return;
      _showSaveResult(SaveResult(success: false, message: e.toString()));
    }
  }

  Future<void> _openLocationInMap(OrderRecord order) async {
    final url = (order.latitude != null && order.longitude != null)
        ? 'https://www.google.com/maps/dir/?api=1&destination=${order.latitude},${order.longitude}'
        : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(order.address)}';
    await url_launcher.launchUrl(
      Uri.parse(url),
      mode: url_launcher.LaunchMode.externalApplication,
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Majburiy maydon';
    }
    return null;
  }

  String _id(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}';
}

class _SideMenu extends StatelessWidget {
  const _SideMenu({required this.selected, required this.onSelect});

  final AdminSection selected;
  final ValueChanged<AdminSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF60A5FA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.water_drop_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Santexnika',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Admin paneli',
                          style: TextStyle(
                            color: AppColors.panelMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF1E293B), thickness: 1, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                children: [
                  for (final item in _AdminShellState._menu)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _SideMenuItem(
                        item: item,
                        selected: selected == item.section,
                        onTap: () => onSelect(item.section),
                      ),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: Text(
                'v1.0.0 · Flutter admin',
                style: TextStyle(
                  color: AppColors.panelMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideMenuItem extends StatelessWidget {
  const _SideMenuItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _MenuItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        hoverColor: selected ? null : const Color(0xFF1E293B),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: selected ? Colors.white : AppColors.panelMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.panelMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.title,
    required this.backendConnected,
    required this.onRefresh,
    required this.onReset,
    required this.onLogout,
  });

  final String title;
  final bool backendConnected;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onReset;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 980;
    String today;
    try {
      today = DateFormat('dd MMMM, y', 'uz').format(DateTime.now());
    } catch (_) {
      today = DateFormat('dd MMMM, y').format(DateTime.now());
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCompact ? title : 'Salom, Admin',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                if (!isCompact)
                  const Text('👋', style: TextStyle(fontSize: 22)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isCompact ? today : 'Bugun: $today',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ConnectionIndicator(connected: backendConnected),
            const SizedBox(width: 10),
            _IconBtn(
              icon: Icons.refresh_rounded,
              tooltip: 'Yangilash',
              onTap: () => onRefresh(),
            ),
            const SizedBox(width: 8),
            _IconBtn(
              icon: Icons.restart_alt_rounded,
              tooltip: 'Demo qayta tiklash',
              onTap: () => onReset(),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onLogout,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Chiqish',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.success : AppColors.textMuted;
    return Tooltip(
      message: connected ? 'Backend ulangan' : 'Offline rejim',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              connected ? 'Online' : 'Offline',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
//  DASHBOARD
// ===========================================================================

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.store,
    required this.money,
    required this.onOpenOrders,
    required this.onOpenActiveDeliveries,
    required this.onOpenInventory,
  });

  final AppStore store;
  final NumberFormat money;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenActiveDeliveries;
  final VoidCallback onOpenInventory;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final ordersToday = store.orders
        .where((o) => o.createdAt.isAfter(todayStart))
        .length;
    final ordersYesterday = store.orders
        .where((o) =>
            o.createdAt.isAfter(yesterdayStart) &&
            o.createdAt.isBefore(todayStart))
        .length;

    final revenueAll = store.orders
        .where((o) => o.status == OrderStatus.completed)
        .fold<double>(0, (s, o) => s + o.total);

    final active = store.activeDeliveries.length;
    final lowStock = store.products.where((p) => p.stock < 5).length;

    final width = MediaQuery.of(context).size.width;
    final cols = width > 1280 ? 4 : (width > 800 ? 2 : 2);

    String trendStr() {
      if (ordersYesterday == 0) {
        return ordersToday > 0 ? '+100%' : '0%';
      }
      final diff =
          ((ordersToday - ordersYesterday) / ordersYesterday * 100).round();
      return '${diff >= 0 ? '+' : ''}$diff%';
    }

    final isMobile = ResponsiveHelper.isMobile(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isMobile ? 1.3 : 1.7,
            children: [
              MetricTile(
                title: 'Bugungi buyurtmalar',
                value: '$ordersToday',
                icon: Icons.receipt_long_rounded,
                color: AppColors.primary,
                subtitle: '$ordersYesterday kechagi',
                trend: trendStr(),
                trendUp: ordersToday >= ordersYesterday,
              ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1),
              MetricTile(
                title: 'Daromad (jami)',
                value: '${money.format(revenueAll)} so\'m',
                icon: Icons.payments_rounded,
                color: AppColors.success,
                subtitle: '${store.orders.length} ta buyurtma',
              ).animate(delay: 80.ms).fadeIn(duration: 250.ms).slideY(begin: 0.1),
              MetricTile(
                title: 'Faol yetkazib berish',
                value: '$active',
                icon: Icons.local_shipping_rounded,
                color: AppColors.warning,
                subtitle:
                    '${store.drivers.where((d) => d.status == DriverStatus.busy).length} haydovchi',
              ).animate(delay: 160.ms).fadeIn(duration: 250.ms).slideY(begin: 0.1),
              MetricTile(
                title: 'Kam zaxira',
                value: '$lowStock',
                icon: Icons.warning_amber_rounded,
                color: AppColors.danger,
                subtitle: '< 5 dona qolgan',
              ).animate(delay: 240.ms).fadeIn(duration: 250.ms).slideY(begin: 0.1),
            ],
          ),
          const SizedBox(height: 18),
          SurfaceCard(
            child: _WeeklyOrdersChart(store: store, money: money),
          ).animate(delay: 320.ms).fadeIn(duration: 300.ms),
          const SizedBox(height: 18),
          _DashboardPanels(
            store: store,
            money: money,
            onOpenOrders: onOpenOrders,
            onOpenInventory: onOpenInventory,
            onOpenActive: onOpenActiveDeliveries,
          ),
        ],
      ),
    );
  }
}

class _WeeklyOrdersChart extends StatelessWidget {
  const _WeeklyOrdersChart({required this.store, required this.money});

  final AppStore store;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final count = store.orders.where((o) {
        final d = DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day);
        return d == day;
      }).length;
      return MapEntry(day, count);
    });

    final maxVal = days.map((e) => e.value).fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = (maxVal < 4 ? 4 : maxVal + 2).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Oxirgi 7 kunlik buyurtmalar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Kunlik dinamikasi',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Jami: ${days.fold<int>(0, (a, b) => a + b.value)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.border,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxY / 4,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= days.length) return const SizedBox.shrink();
                      String dayStr;
                      try {
                        dayStr = DateFormat('E', 'uz').format(days[i].key);
                      } catch (_) {
                        dayStr = DateFormat('E').format(days[i].key);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          dayStr,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.ink,
                  tooltipRoundedRadius: 10,
                  tooltipPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  getTooltipItems: (spots) => spots.map((s) {
                    final day = days[s.x.toInt()].key;
                    String label;
                    try {
                      label = DateFormat('dd MMM', 'uz').format(day);
                    } catch (_) {
                      label = DateFormat('dd MMM').format(day);
                    }
                    return LineTooltipItem(
                      '$label\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: '${s.y.toInt()} ta buyurtma',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < days.length; i++)
                      FlSpot(i.toDouble(), days[i].value.toDouble()),
                  ],
                  isCurved: true,
                  curveSmoothness: 0.32,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2.5,
                      strokeColor: AppColors.primary,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.25),
                        AppColors.primary.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardPanels extends StatelessWidget {
  const _DashboardPanels({
    required this.store,
    required this.money,
    required this.onOpenOrders,
    required this.onOpenInventory,
    required this.onOpenActive,
  });

  final AppStore store;
  final NumberFormat money;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenInventory;
  final VoidCallback onOpenActive;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    final recent = SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Eng yangi buyurtmalar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: onOpenOrders,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Hammasi'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (store.recentOrders.isEmpty)
            const EmptyPlaceholder(
              icon: Icons.receipt_long_outlined,
              title: 'Buyurtma yo\'q',
              subtitle: 'Yangi buyurtma kelganda shu yerda ko\'rinadi',
            )
          else
            ...store.recentOrders.map(
              (o) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    AvatarCircle(name: o.customerName, size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.customerName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${o.id} · ${DateFormat('dd.MM HH:mm').format(o.createdAt)}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${money.format(o.total)} so\'m',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        StatusPill(
                          label: o.status.label,
                          foreground: orderStatusColor(o.status),
                          background: orderStatusBackground(o.status),
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    final low = SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kam qolgan mahsulotlar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: onOpenInventory,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Zaxira'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (store.lowStockProducts.isEmpty)
            const EmptyPlaceholder(
              icon: Icons.check_circle_outline_rounded,
              title: 'Hammasi joyida',
              subtitle: 'Zaxira muammosi yo\'q',
            )
          else
            ...store.lowStockProducts.take(5).map((p) {
              Color color;
              if (p.stock == 0) {
                color = AppColors.danger;
              } else if (p.stock <= 3) {
                color = AppColors.warning;
              } else {
                color = AppColors.info;
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            store.categoryById(p.categoryId)?.name ?? '-',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${p.stock} dona',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );

    if (isMobile) {
      return Column(children: [recent, const SizedBox(height: 14), low]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: recent),
        const SizedBox(width: 14),
        Expanded(child: low),
      ],
    );
  }
}

// ===========================================================================
//  PRODUCTS
// ===========================================================================

class _ProductsView extends StatefulWidget {
  const _ProductsView({
    required this.store,
    required this.money,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onExport,
  });

  final AppStore store;
  final NumberFormat money;
  final VoidCallback onAdd;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onDelete;
  final VoidCallback onExport;

  @override
  State<_ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<_ProductsView> {
  final _searchCtrl = TextEditingController();
  String _q = '';
  String? _categoryId;
  ProductBadge? _badge;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    final q = _q.trim().toLowerCase();
    return widget.store.products.where((p) {
      if (_categoryId != null && p.categoryId != _categoryId) return false;
      if (_badge != null && p.badge != _badge) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Mahsulotlar',
          subtitle: '${widget.store.products.length} ta mahsulot',
          action: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed:
                    widget.store.products.isEmpty ? null : widget.onExport,
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Excel'),
              ),
              ElevatedButton.icon(
                onPressed: widget.onAdd,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Yangi mahsulot'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppSearchField(
                      controller: _searchCtrl,
                      hint: 'Mahsulot nomi yoki SKU...',
                      onChanged: (v) => setState(() => _q = v),
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Kategoriya',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Barchasi'),
                          ),
                          ...widget.store.categories.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _badgeFilterChip(null, 'Barchasi'),
                    for (final b in ProductBadge.values)
                      _badgeFilterChip(b, b.label),
                  ],
                ),
              ),
              if (isMobile) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Kategoriya',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Barchasi'),
                    ),
                    ...widget.store.categories.map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _filtered.isEmpty
              ? SurfaceCard(
                  child: EmptyPlaceholder(
                    icon: Icons.inventory_2_outlined,
                    title: widget.store.products.isEmpty
                        ? 'Hali mahsulot yo\'q'
                        : 'Hech narsa topilmadi',
                    subtitle: widget.store.products.isEmpty
                        ? 'Birinchi mahsulot qo\'shib boshlang!'
                        : 'Filtr yoki qidiruvni o\'zgartirib ko\'ring',
                    actionLabel: widget.store.products.isEmpty
                        ? 'Mahsulot qo\'shish'
                        : null,
                    onAction:
                        widget.store.products.isEmpty ? widget.onAdd : null,
                  ),
                )
              : LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    final cols = w > 1400
                        ? 4
                        : w > 1000
                            ? 3
                            : w > 600
                                ? 2
                                : 2;
                    return GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final product = _filtered[i];
                        return _ProductCard(
                          product: product,
                          category: widget.store
                              .categoryById(product.categoryId)
                              ?.name,
                          money: widget.money,
                          onEdit: () => widget.onEdit(product),
                          onDelete: () => widget.onDelete(product),
                        ).animate(delay: (i * 30).ms).fadeIn(duration: 200.ms);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _badgeFilterChip(ProductBadge? badge, String label) {
    final isSel = _badge == badge;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSel ? AppColors.primary : AppColors.background,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() => _badge = badge),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSel ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSel ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.category,
    required this.money,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final String? category;
  final NumberFormat money;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get _stockColor {
    if (product.stock == 0) return AppColors.danger;
    if (product.stock <= 5) return AppColors.warning;
    if (product.stock <= 20) return AppColors.info;
    return AppColors.success;
  }

  Color get _badgeColor {
    switch (product.badge) {
      case ProductBadge.yangi:
        return AppColors.info;
      case ProductBadge.chegirma:
        return AppColors.danger;
      case ProductBadge.tavsiya:
        return AppColors.success;
      case ProductBadge.ommabop:
        return AppColors.warning;
      case ProductBadge.none:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? _ProductImage(url: product.imageUrl!)
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primarySoft,
                                AppColors.background,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.primary,
                              size: 36,
                            ),
                          ),
                        ),
                ),
                if (product.badge != ProductBadge.none)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _badgeColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        product.badge.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.3,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                if (category != null)
                  Text(
                    category!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        money.format(product.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'so\'m',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (product.oldPrice != null)
                  Text(
                    '${money.format(product.oldPrice)} so\'m',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _stockColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        size: 12,
                        color: _stockColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.stock} dona',
                        style: TextStyle(
                          color: _stockColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded, size: 14),
                        label: const Text('Tahrir'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Material(
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: onDelete,
                        child: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: AppColors.primarySoft,
          child: const Center(
            child: Icon(Icons.broken_image_outlined, color: AppColors.primary),
          ),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppColors.background,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }
    if (kIsWeb) {
      return Container(
        color: AppColors.primarySoft,
        child: const Center(
          child: Icon(Icons.image_outlined, color: AppColors.primary),
        ),
      );
    }
    final file = File(url);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Container(
      color: AppColors.primarySoft,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: AppColors.primary),
      ),
    );
  }
}

class _ImagePickerArea extends StatelessWidget {
  const _ImagePickerArea({
    required this.image,
    required this.imageUrl,
    required this.onPick,
    required this.onClear,
  });

  final XFile? image;
  final String? imageUrl;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null || (imageUrl != null && imageUrl!.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mahsulot rasmi',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(
                color: AppColors.border,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: image != null && !kIsWeb
                            ? Image.file(File(image!.path), fit: BoxFit.cover)
                            : (imageUrl != null
                                ? _ProductImage(url: imageUrl!)
                                : const SizedBox.shrink()),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: AppColors.surface,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onClear,
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : InkWell(
                    onTap: onPick,
                    borderRadius: BorderRadius.circular(13),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 36,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Rasm tanlang',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        if (hasImage) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Almashtirish'),
            ),
          ),
        ],
      ],
    );
  }
}

// ===========================================================================
//  CATEGORIES
// ===========================================================================

class _CategoriesView extends StatelessWidget {
  const _CategoriesView({
    required this.store,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final AppStore store;
  final VoidCallback onAdd;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Kategoriyalar',
          subtitle: '${store.categories.length} ta kategoriya',
          action: ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Yangi kategoriya'),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: store.categories.isEmpty
              ? SurfaceCard(
                  child: EmptyPlaceholder(
                    icon: Icons.category_outlined,
                    title: 'Kategoriya yo\'q',
                    subtitle:
                        'Mahsulotlarni guruhlash uchun kategoriya qo\'shing',
                    actionLabel: 'Kategoriya qo\'shish',
                    onAction: onAdd,
                  ),
                )
              : LayoutBuilder(
                  builder: (context, c) {
                    final cols =
                        c.maxWidth > 1100 ? 3 : (c.maxWidth > 700 ? 2 : 1);
                    return GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 170,
                      ),
                      itemCount: store.categories.length,
                      itemBuilder: (context, i) {
                        final category = store.categories[i];
                        final productsCount = store.products
                            .where((p) => p.categoryId == category.id)
                            .length;
                        return SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          Color(0xFF60A5FA),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.category_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Kod: ${category.code}',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: Text(
                                  category.description.isEmpty
                                      ? 'Izoh yo\'q'
                                      : category.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '$productsCount ta mahsulot',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => onEdit(category),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.background,
                                      minimumSize: const Size(34, 34),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    onPressed: () => onDelete(category),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: AppColors.danger,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.dangerSoft,
                                      minimumSize: const Size(34, 34),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ===========================================================================
//  ORDERS
// ===========================================================================

class _OrdersView extends StatefulWidget {
  const _OrdersView({
    required this.store,
    required this.money,
    required this.initialFilter,
    required this.onlyActiveDeliveries,
    required this.onAssign,
    required this.onView,
    required this.onExportAll,
    required this.onExportOne,
  });

  final AppStore store;
  final NumberFormat money;
  final OrderStatus? initialFilter;
  final bool onlyActiveDeliveries;
  final ValueChanged<OrderRecord> onAssign;
  final ValueChanged<OrderRecord> onView;
  final VoidCallback onExportAll;
  final ValueChanged<OrderRecord> onExportOne;

  @override
  State<_OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<_OrdersView> {
  final _searchCtrl = TextEditingController();
  String _q = '';
  OrderStatus? _filter;
  bool _activeDelivery = false;
  bool _sortByAmount = false;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _activeDelivery = widget.onlyActiveDeliveries;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<OrderRecord> get _filtered {
    final q = _q.trim().toLowerCase();
    final list = widget.store.orders.where((o) {
      if (_activeDelivery && o.status != OrderStatus.processing) return false;
      if (_filter != null && o.status != _filter) return false;
      if (q.isEmpty) return true;
      return o.id.toLowerCase().contains(q) ||
          o.customerName.toLowerCase().contains(q);
    }).toList();
    list.sort((a, b) => _sortByAmount
        ? b.total.compareTo(a.total)
        : b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final orders = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Buyurtmalar',
          subtitle:
              '${orders.length}/${widget.store.orders.length} ta ko\'rsatildi',
          action: OutlinedButton.icon(
            onPressed: widget.store.orders.isEmpty ? null : widget.onExportAll,
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Excelga'),
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppSearchField(
                      controller: _searchCtrl,
                      hint: 'ID yoki mijoz nomi...',
                      onChanged: (v) => setState(() => _q = v),
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 12),
                    Material(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () =>
                            setState(() => _sortByAmount = !_sortByAmount),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _sortByAmount
                                    ? Icons.attach_money_rounded
                                    : Icons.access_time_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _sortByAmount ? 'Summa' : 'Sana',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _statusFilterChip(null, false, 'Hammasi', Icons.list_rounded),
                    _statusFilterChip(
                      null,
                      true,
                      'Faol yetkazib berish',
                      Icons.local_shipping_rounded,
                    ),
                    for (final s in OrderStatus.values)
                      _statusFilterChip(s, false, s.label, orderStatusIcon(s)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: orders.isEmpty
              ? SurfaceCard(
                  child: EmptyPlaceholder(
                    icon: Icons.receipt_long_outlined,
                    title: widget.store.orders.isEmpty
                        ? 'Buyurtmalar yo\'q'
                        : 'Hech narsa topilmadi',
                    subtitle: widget.store.orders.isEmpty
                        ? 'Yangi buyurtma kelganda shu yerda ko\'rinadi'
                        : 'Filtrlarni o\'zgartirib ko\'ring',
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final order = orders[i];
                    return _OrderCard(
                      order: order,
                      money: widget.money,
                      driverName: widget.store
                          .driverById(order.driverId ?? '')
                          ?.name,
                      onTap: () => widget.onView(order),
                      onAssign: () => widget.onAssign(order),
                    ).animate(delay: (i * 25).ms).fadeIn(duration: 180.ms);
                  },
                ),
        ),
      ],
    );
  }

  Widget _statusFilterChip(
    OrderStatus? status,
    bool activeDelivery,
    String label,
    IconData icon,
  ) {
    final selected = activeDelivery
        ? _activeDelivery
        : (!_activeDelivery && _filter == status);
    final color = activeDelivery
        ? AppColors.warning
        : (status != null ? orderStatusColor(status) : AppColors.primary);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? color : AppColors.background,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() {
            if (activeDelivery) {
              _activeDelivery = !_activeDelivery;
              if (_activeDelivery) _filter = null;
            } else {
              _filter = status;
              _activeDelivery = false;
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selected ? color : AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: selected ? Colors.white : color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.money,
    required this.driverName,
    required this.onTap,
    required this.onAssign,
  });

  final OrderRecord order;
  final NumberFormat money;
  final String? driverName;
  final VoidCallback onTap;
  final VoidCallback onAssign;

  String get _ago {
    final diff = DateTime.now().difference(order.createdAt);
    if (diff.inMinutes < 1) return 'hozir';
    if (diff.inHours < 1) return '${diff.inMinutes} daq oldin';
    if (diff.inDays < 1) return '${diff.inHours} soat oldin';
    if (diff.inDays < 7) return '${diff.inDays} kun oldin';
    return DateFormat('dd.MM.yyyy').format(order.createdAt);
  }

  @override
  Widget build(BuildContext context) {
    final itemsCount = order.items.fold<int>(0, (s, i) => s + i.quantity);
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarCircle(name: order.customerName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order.phone} · ${order.id}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: order.status.label,
                foreground: orderStatusColor(order.status),
                background: orderStatusBackground(order.status),
                icon: orderStatusIcon(order.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                'Haydovchi: ${driverName ?? 'Tayinlanmagan'}',
                style: TextStyle(
                  color: driverName == null
                      ? AppColors.warning
                      : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: driverName == null
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final compact = c.maxWidth < 520;
              return Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$itemsCount ta mahsulot',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${money.format(order.total)} so\'m',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '· $_ago',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onAssign,
                        icon: const Icon(Icons.person_search_rounded, size: 16),
                        label: Text(compact ? 'Haydovchi' : 'Haydovchi tayinlash'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                        ),
                        label: const Text('Batafsil'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
//  ORDER DETAILS PAGE
// ===========================================================================

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.money,
    required this.onAssign,
    required this.onExport,
    required this.onCall,
    required this.onMap,
  });

  final String orderId;
  final NumberFormat money;
  final ValueChanged<OrderRecord> onAssign;
  final ValueChanged<OrderRecord> onExport;
  final ValueChanged<String> onCall;
  final ValueChanged<OrderRecord> onMap;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.watch(context);
    final order = store.orderById(orderId);
    if (order == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Buyurtma topilmadi')),
      );
    }
    final driver = store.driverById(order.driverId ?? '');

    String dateStr;
    try {
      dateStr = DateFormat('dd MMMM, y · HH:mm', 'uz').format(order.createdAt);
    } catch (_) {
      dateStr = DateFormat('dd MMMM, y · HH:mm').format(order.createdAt);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(order.id, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'export') {
                onExport(order);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Excelga eksport'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusPill(
                    label: order.status.label,
                    foreground: orderStatusColor(order.status),
                    background: orderStatusBackground(order.status),
                    icon: orderStatusIcon(order.status),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AvatarCircle(name: order.customerName, size: 50),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.phone,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => onCall(order.phone),
                          tooltip: 'Qo\'ng\'iroq qilish',
                          icon: const Icon(Icons.phone_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.successSoft,
                            foregroundColor: AppColors.success,
                            minimumSize: const Size(44, 44),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.address,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => onMap(order),
                          icon: const Icon(Icons.map_rounded, size: 16),
                          label: const Text('Xaritada'),
                        ),
                      ],
                    ),
                    if (order.latitude != null && order.longitude != null) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: Text(
                          'GPS: ${order.latitude!.toStringAsFixed(5)}, ${order.longitude!.toStringAsFixed(5)}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mahsulotlar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.items.length} ta pozitsiya',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...order.items.map((item) {
                      final product = store.productById(item.productId);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: product?.imageUrl != null &&
                                      product!.imageUrl!.isNotEmpty
                                  ? _ProductImage(url: product.imageUrl!)
                                  : const Icon(
                                      Icons.inventory_2_rounded,
                                      color: AppColors.primary,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.quantity} × ${money.format(item.price)} so\'m',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${money.format(item.price * item.quantity)} so\'m',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Jami:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${money.format(order.total)} so\'m',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Boshqarish',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, c) {
                        final compact = c.maxWidth < 540;
                        final statusField = DropdownButtonFormField<OrderStatus>(
                          initialValue: order.status,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: OrderStatus.values
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Row(
                                    children: [
                                      Icon(
                                        orderStatusIcon(s),
                                        color: orderStatusColor(s),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(s.label),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) async {
                            if (v != null) {
                              await store.updateOrderStatus(order.id, v);
                              if (context.mounted) {
                                AppToast.success(context, 'Status yangilandi');
                              }
                            }
                          },
                        );
                        final assignBtn = OutlinedButton.icon(
                          onPressed: () => onAssign(order),
                          icon: const Icon(Icons.person_search_rounded, size: 18),
                          label: Text(
                            driver == null
                                ? 'Haydovchi tayinlash'
                                : 'Haydovchi: ${driver.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                        if (compact) {
                          return Column(
                            children: [
                              statusField,
                              const SizedBox(height: 10),
                              SizedBox(width: double.infinity, child: assignBtn),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: statusField),
                            const SizedBox(width: 12),
                            Expanded(child: assignBtn),
                          ],
                        );
                      },
                    ),
                    if (order.status != OrderStatus.cancelled) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text('Bekor qilinsinmi?'),
                                content: Text(
                                  '${order.id} buyurtmasini bekor qilmoqchimisiz?',
                                ),
                                actions: [
                                  OutlinedButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Yo\'q'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.danger,
                                    ),
                                    child: const Text('Ha, bekor qilish'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await store.updateOrderStatus(
                                order.id,
                                OrderStatus.cancelled,
                              );
                              if (context.mounted) {
                                AppToast.info(context, 'Buyurtma bekor qilindi');
                              }
                            }
                          },
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Buyurtmani bekor qilish'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
//  INVENTORY
// ===========================================================================

class _InventoryView extends StatefulWidget {
  const _InventoryView({
    required this.store,
    required this.money,
    required this.onAdjust,
    required this.onCustomAdjust,
  });

  final AppStore store;
  final NumberFormat money;
  final Future<void> Function(Product, InventoryAction, int) onAdjust;
  final ValueChanged<Product> onCustomAdjust;

  @override
  State<_InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<_InventoryView> {
  final _searchCtrl = TextEditingController();
  String _q = '';
  bool _sortByStock = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    final q = _q.trim().toLowerCase();
    final list = widget.store.products.where((p) {
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q);
    }).toList();
    if (_sortByStock) {
      list.sort((a, b) => a.stock.compareTo(b.stock));
    } else {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Zaxira',
          subtitle: '${widget.store.products.length} ta mahsulot',
          action: OutlinedButton.icon(
            onPressed: () => setState(() => _sortByStock = !_sortByStock),
            icon: Icon(
              _sortByStock ? Icons.swap_vert_rounded : Icons.sort_by_alpha_rounded,
              size: 16,
            ),
            label: Text(_sortByStock ? 'Zaxira bo\'yicha' : 'Alifbo bo\'yicha'),
          ),
        ),
        const SizedBox(height: 14),
        SurfaceCard(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: AppSearchField(
            controller: _searchCtrl,
            hint: 'Mahsulot qidirish...',
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: list.isEmpty
              ? SurfaceCard(
                  child: EmptyPlaceholder(
                    icon: Icons.warehouse_outlined,
                    title: widget.store.products.isEmpty
                        ? 'Mahsulot yo\'q'
                        : 'Topilmadi',
                    subtitle: widget.store.products.isEmpty
                        ? 'Avval mahsulot qo\'shing'
                        : 'Qidiruvni o\'zgartirib ko\'ring',
                  ),
                )
              : SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: list.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.borderSoft),
                    itemBuilder: (context, i) {
                      final p = list[i];
                      final color = p.stock == 0
                          ? AppColors.danger
                          : p.stock <= 5
                              ? AppColors.warning
                              : p.stock <= 20
                                  ? AppColors.info
                                  : AppColors.success;
                      final statusLabel = p.stock == 0
                          ? 'Tugagan'
                          : p.stock <= 5
                              ? 'Kam'
                              : p.stock <= 20
                                  ? 'Normal'
                                  : 'Yaxshi';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        color: i.isEven
                            ? Colors.transparent
                            : AppColors.background.withValues(alpha: 0.4),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                                  ? _ProductImage(url: p.imageUrl!)
                                  : const Icon(
                                      Icons.inventory_2_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'SKU: ${p.sku.isEmpty ? '-' : p.sku} · ${widget.money.format(p.price)} so\'m',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _StockStepper(
                              stock: p.stock,
                              onMinus: () =>
                                  widget.onAdjust(p, InventoryAction.subtract, 1),
                              onPlus: () =>
                                  widget.onAdjust(p, InventoryAction.add, 1),
                              onEdit: () => widget.onCustomAdjust(p),
                            ),
                          ],
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

class _StockStepper extends StatelessWidget {
  const _StockStepper({
    required this.stock,
    required this.onMinus,
    required this.onPlus,
    required this.onEdit,
  });

  final int stock;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(Icons.remove_rounded, onMinus, stock > 0),
          InkWell(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              alignment: Alignment.center,
              constraints: const BoxConstraints(minWidth: 48),
              child: Text(
                '$stock',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          _stepBtn(Icons.add_rounded, onPlus, true),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap, bool enabled) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 16,
            color: enabled ? AppColors.ink : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
//  DRIVERS
// ===========================================================================

class _DriversView extends StatelessWidget {
  const _DriversView({
    required this.store,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onCall,
  });

  final AppStore store;
  final VoidCallback onAdd;
  final ValueChanged<DriverProfile> onEdit;
  final ValueChanged<DriverProfile> onDelete;
  final ValueChanged<DriverProfile> onCall;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Haydovchilar',
          subtitle:
              '${store.drivers.where((d) => d.status == DriverStatus.free).length} bo\'sh · ${store.drivers.where((d) => d.status == DriverStatus.busy).length} band',
          action: ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Yangi haydovchi'),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: store.drivers.isEmpty
              ? SurfaceCard(
                  child: EmptyPlaceholder(
                    icon: Icons.local_shipping_outlined,
                    title: 'Haydovchi yo\'q',
                    subtitle: 'Yetkazib berish uchun haydovchi qo\'shing',
                    actionLabel: 'Haydovchi qo\'shish',
                    onAction: onAdd,
                  ),
                )
              : LayoutBuilder(
                  builder: (context, c) {
                    final cols = c.maxWidth > 1300
                        ? 4
                        : c.maxWidth > 900
                            ? 3
                            : c.maxWidth > 600
                                ? 2
                                : 1;
                    return GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 290,
                      ),
                      itemCount: store.drivers.length,
                      itemBuilder: (context, i) {
                        final driver = store.drivers[i];
                        final currentOrder = driver.currentOrderId == null
                            ? null
                            : store.orderById(driver.currentOrderId!);
                        return _DriverCard(
                          driver: driver,
                          currentOrder: currentOrder,
                          onCall: () => onCall(driver),
                          onEdit: () => onEdit(driver),
                          onDelete: () => onDelete(driver),
                        ).animate(delay: (i * 30).ms).fadeIn(duration: 200.ms);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.driver,
    required this.currentOrder,
    required this.onCall,
    required this.onEdit,
    required this.onDelete,
  });

  final DriverProfile driver;
  final OrderRecord? currentOrder;
  final VoidCallback onCall;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarCircle(name: driver.name, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFBBF24),
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          driver.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '· ${driver.completedOrders} ta',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
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
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Material(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onCall,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_rounded,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        driver.phone,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.directions_car_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  driver.vehicleNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (currentOrder != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping_rounded,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Joriy: ${currentOrder!.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Tahrir'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onDelete,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
//  APPLICATIONS
// ===========================================================================

class _ApplicationsView extends StatefulWidget {
  const _ApplicationsView({required this.store});

  final AppStore store;

  @override
  State<_ApplicationsView> createState() => _ApplicationsViewState();
}

class _ApplicationsViewState extends State<_ApplicationsView> {
  ApplicationStatus? _filter = ApplicationStatus.newRequest;

  List<ApplicationRecord> get _filtered {
    final list = widget.store.applications.toList();
    if (_filter != null) {
      return list.where((a) => a.status == _filter).toList();
    }
    return list;
  }

  Future<void> _confirmAction(
    ApplicationRecord app,
    ApplicationStatus newStatus,
  ) async {
    final isApprove = newStatus == ApplicationStatus.approved;
    final noteCtrl = TextEditingController(
      text: isApprove ? 'Tasdiqlandi' : '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isApprove ? 'Tasdiqlash' : 'Rad etish',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${app.customerName} · ${app.bonusType} · ${app.points} ball',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: isApprove ? 'Izoh (ixtiyoriy)' : 'Rad etish sababi',
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Bekor'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? AppColors.success : AppColors.danger,
            ),
            child: Text(isApprove ? 'Tasdiqlash' : 'Rad etish'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.store.updateApplication(
        app.id,
        newStatus,
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );
      if (mounted) {
        AppToast.success(
          context,
          isApprove ? 'Ariza tasdiqlandi' : 'Ariza rad etildi',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Bonus arizalari',
          subtitle: '${widget.store.applications.length} ta ariza',
        ),
        const SizedBox(height: 14),
        SurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statusTab(null, 'Hammasi'),
                for (final s in ApplicationStatus.values)
                  _statusTab(s, s.label),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _filtered.isEmpty
              ? SurfaceCard(
                  child: EmptyPlaceholder(
                    icon: Icons.assignment_outlined,
                    title: 'Ariza yo\'q',
                    subtitle: _filter == null
                        ? 'Yangi arizalar shu yerda ko\'rinadi'
                        : 'Bu kategoriyada arizalar yo\'q',
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final app = _filtered[i];
                    return _ApplicationCard(
                      application: app,
                      onApprove: () =>
                          _confirmAction(app, ApplicationStatus.approved),
                      onReject: () =>
                          _confirmAction(app, ApplicationStatus.rejected),
                      onReview: () => widget.store.updateApplication(
                        app.id,
                        ApplicationStatus.reviewing,
                        note: 'Ko\'rib chiqilmoqda',
                      ),
                    ).animate(delay: (i * 30).ms).fadeIn(duration: 180.ms);
                  },
                ),
        ),
      ],
    );
  }

  Widget _statusTab(ApplicationStatus? s, String label) {
    final isSel = _filter == s;
    final color = s != null ? applicationStatusColor(s) : AppColors.primary;
    final count = s == null
        ? widget.store.applications.length
        : widget.store.applications.where((a) => a.status == s).length;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSel ? color : AppColors.background,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() => _filter = s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: isSel ? color : AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSel ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSel
                        ? Colors.white.withValues(alpha: 0.25)
                        : color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSel ? Colors.white : color,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onApprove,
    required this.onReject,
    required this.onReview,
  });

  final ApplicationRecord application;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final isActionable = application.status == ApplicationStatus.newRequest ||
        application.status == ApplicationStatus.reviewing;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarCircle(name: application.customerName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${application.phone} · ${application.id}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: application.status.label,
                foreground: applicationStatusColor(application.status),
                background: applicationStatusBackground(application.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _infoChip(
                Icons.card_giftcard_rounded,
                application.bonusType,
                AppColors.warning,
              ),
              _infoChip(
                Icons.toll_rounded,
                '${application.points} ball',
                AppColors.primary,
              ),
              _infoChip(
                Icons.account_balance_wallet_rounded,
                'Balans: ${application.currentBalance}',
                AppColors.success,
              ),
              _infoChip(
                Icons.schedule_rounded,
                DateFormat('dd.MM HH:mm').format(application.createdAt),
                AppColors.textMuted,
              ),
            ],
          ),
          if (application.adminNote != null &&
              application.adminNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                ),
              ),
              child: Text(
                application.adminNote!,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
          if (isActionable) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (application.status == ApplicationStatus.newRequest)
                  OutlinedButton.icon(
                    onPressed: onReview,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Ko\'rib chiqish'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Tasdiqlash'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size(0, 38),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Rad etish'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    minimumSize: const Size(0, 38),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
//  REPORTS
// ===========================================================================

class _ReportsView extends StatelessWidget {
  const _ReportsView({required this.store, required this.money});

  final AppStore store;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Hisobotlar',
            subtitle: 'Sotuvlar va statistik tahlil',
          ),
          const SizedBox(height: 16),
          if (isMobile) ...[
            SurfaceCard(child: _MonthlyRevenueChart(store: store, money: money))
                .animate()
                .fadeIn(duration: 250.ms),
            const SizedBox(height: 14),
            SurfaceCard(child: _CategoryPieChart(store: store))
                .animate(delay: 100.ms)
                .fadeIn(duration: 250.ms),
            const SizedBox(height: 14),
            SurfaceCard(child: _DriverRatingChart(store: store))
                .animate(delay: 200.ms)
                .fadeIn(duration: 250.ms),
            const SizedBox(height: 14),
            SurfaceCard(child: _TopProductsList(store: store, money: money))
                .animate(delay: 300.ms)
                .fadeIn(duration: 250.ms),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: SurfaceCard(
                    child: _MonthlyRevenueChart(store: store, money: money),
                  ).animate().fadeIn(duration: 250.ms),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SurfaceCard(
                    child: _CategoryPieChart(store: store),
                  ).animate(delay: 100.ms).fadeIn(duration: 250.ms),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SurfaceCard(
                    child: _DriverRatingChart(store: store),
                  ).animate(delay: 200.ms).fadeIn(duration: 250.ms),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SurfaceCard(
                    child: _TopProductsList(store: store, money: money),
                  ).animate(delay: 300.ms).fadeIn(duration: 250.ms),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthlyRevenueChart extends StatelessWidget {
  const _MonthlyRevenueChart({required this.store, required this.money});

  final AppStore store;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - 5 + i);
      final total = store.orders
          .where((o) =>
              o.status == OrderStatus.completed &&
              o.createdAt.year == m.year &&
              o.createdAt.month == m.month)
          .fold<double>(0, (s, o) => s + o.total);
      return MapEntry(m, total);
    });
    final maxY = months.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b);
    final scaled = maxY <= 0 ? 1.0 : (maxY * 1.2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daromad (6 oy)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Jami: ${money.format(months.fold<double>(0, (a, b) => a + b.value))} so\'m',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: scaled,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: scaled / 4,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.border,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= months.length) {
                        return const SizedBox.shrink();
                      }
                      String monthStr;
                      try {
                        monthStr = DateFormat('MMM', 'uz').format(months[i].key);
                      } catch (_) {
                        monthStr = DateFormat('MMM').format(months[i].key);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          monthStr,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.ink,
                  tooltipRoundedRadius: 10,
                  getTooltipItems: (spots) => spots.map((s) {
                    return LineTooltipItem(
                      '${money.format(s.y)} so\'m',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < months.length; i++)
                      FlSpot(i.toDouble(), months[i].value),
                  ],
                  isCurved: true,
                  color: AppColors.success,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2.5,
                      strokeColor: AppColors.success,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.withValues(alpha: 0.25),
                        AppColors.success.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  const _CategoryPieChart({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.danger,
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      AppColors.info,
    ];
    final categorySales = <String, double>{};
    for (final order in store.orders) {
      for (final item in order.items) {
        final product = store.productById(item.productId);
        if (product == null) continue;
        final category = store.categoryById(product.categoryId);
        if (category == null) continue;
        categorySales.update(
          category.name,
          (v) => v + item.price * item.quantity,
          ifAbsent: () => item.price * item.quantity,
        );
      }
    }
    final entries = categorySales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (a, b) => a + b.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategoriyalar bo\'yicha',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sotuv ulushi',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: EmptyPlaceholder(
              icon: Icons.pie_chart_outline_rounded,
              title: 'Ma\'lumot yo\'q',
              subtitle: 'Hali sotuv bo\'lmagan',
            ),
          )
        else
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sectionsSpace: 3,
                sections: [
                  for (var i = 0; i < entries.length; i++)
                    PieChartSectionData(
                      value: entries[i].value,
                      color: colors[i % colors.length],
                      title: total > 0
                          ? '${(entries[i].value / total * 100).toStringAsFixed(0)}%'
                          : '',
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        ...entries.take(5).toList().asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[e.key % colors.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.value.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _DriverRatingChart extends StatelessWidget {
  const _DriverRatingChart({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final drivers = store.drivers.toList()
      ..sort((a, b) => b.completedOrders.compareTo(a.completedOrders));
    final top = drivers.take(5).toList();
    final maxVal =
        top.map((d) => d.completedOrders).fold<int>(0, (a, b) => a > b ? a : b);
    final scaled = maxVal == 0 ? 5.0 : (maxVal * 1.2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Haydovchilar reytingi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Bajarilgan buyurtmalar bo\'yicha',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 18),
        if (top.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: EmptyPlaceholder(
              icon: Icons.bar_chart_rounded,
              title: 'Haydovchi yo\'q',
              subtitle: 'Avval haydovchi qo\'shing',
            ),
          )
        else
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: scaled,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (scaled / 4).clamp(1, double.infinity),
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= top.length) {
                          return const SizedBox.shrink();
                        }
                        final parts = top[i].name.split(' ');
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            parts.first,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < top.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: top[i].completedOrders.toDouble(),
                          width: 24,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF60A5FA)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TopProductsList extends StatelessWidget {
  const _TopProductsList({required this.store, required this.money});

  final AppStore store;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final products = store.products.toList()
      ..sort((a, b) => b.soldCount.compareTo(a.soldCount));
    final top = products.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top mahsulotlar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Eng ko\'p sotilganlar',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        if (top.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: EmptyPlaceholder(
              icon: Icons.inventory_2_outlined,
              title: 'Mahsulot yo\'q',
              subtitle: '',
            ),
          )
        else
          ...top.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i < 3 ? AppColors.warningSoft : AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i < 3 ? AppColors.warning : AppColors.textMuted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${p.soldCount} ta sotilgan',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${money.format(p.price)} so\'m',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
