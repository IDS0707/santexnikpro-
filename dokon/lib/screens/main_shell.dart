import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import 'tab_home.dart';
import 'tab_products.dart';
import 'tab_calculator.dart';
import 'tab_cart.dart';
import 'tab_profile.dart';
import 'product_detail.dart';
import 'quick_order.dart';
import 'bonuslar.dart';
import 'notifications_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _loading = true;
  String? _error;
  List<Product> _products = [];
  List<Category> _categories = [];
  List<BannerInfo> _banners = [];
  List<OrderInfo> _orders = [];
  String _filter = 'all';
  String _search = '';

  // tugamagan (faol) buyurtmalar soni — qo'ng'iroq belgisiga chiqadi
  int get _notifCount =>
      _orders.where((o) => !{'completed', 'delivered', 'cancelled'}.contains(o.status)).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final st = context.read<AppState>();
    final sid = st.storeId ?? 0;
    try {
      final r = await Future.wait([Api.categories(sid), Api.products(sid)]);
      _categories = r[0] as List<Category>;
      _products = r[1] as List<Product>;
    } catch (e) {
      _error = '$e';
    }
    // ixtiyoriy — xato bo'lsa ham bosh sahifa ishlayveradi
    try {
      _banners = (await Api.banners(sid)).where((b) => b.isActive).toList();
    } catch (_) {}
    try {
      _orders = await Api.myOrders(st.userId ?? 0);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _goProducts(String filter) => setState(() { _filter = filter; _index = 1; });
  void _goTab(int i) => setState(() => _index = i);
  void _push(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final tabs = [
      HomeTab(
        categories: _categories,
        products: _products,
        banners: _banners,
        onPickCategory: _goProducts,
        onSearch: (q) => setState(() { _search = q; _filter = 'all'; _index = 1; }),
        onProducts: () => _goTab(1),
        onCalculator: () => _goTab(2),
        onQuickOrder: () => _push(const QuickOrderScreen()),
        onBonus: () => _push(const BonuslarScreen()),
        onOpenProduct: (p) => _push(ProductDetailScreen(product: p)),
      ),
      ProductsTab(
        products: _products, categories: _categories, filter: _filter, search: _search,
        onFilter: (f) => setState(() => _filter = f),
        onSearch: (s) => setState(() => _search = s),
        onOpenProduct: (p) => _push(ProductDetailScreen(product: p)),
      ),
      const CalculatorTab(),
      CartTab(onShop: () => _goTab(1)),
      ProfileTab(onBonus: () => _push(const BonuslarScreen())),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_index == 0 || _index == 1) _topBar(st),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _errorView()
                      : IndexedStack(index: _index, children: tabs),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(st),
    );
  }

  Widget _topBar(AppState st) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(11),
              child: Image.asset('assets/logo.png', width: 40, height: 40, fit: BoxFit.cover)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('SANTEXNIK PRO', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
              Text(st.storeName ?? "Do'kon",
                  style: const TextStyle(fontSize: 11, color: AppColors.textDim), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          _badgeBtn(st.themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              0, () => st.toggleTheme()),
          _badgeBtn(Icons.notifications_none_rounded, _notifCount, () => _push(const NotificationsScreen())),
          _badgeBtn(Icons.shopping_cart_outlined, st.cartCount, () => _goTab(3)),
        ],
      ),
    );
  }

  Widget _badgeBtn(IconData ic, int count, VoidCallback onTap) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Stack(alignment: Alignment.center, children: [
        Container(
          width: 42, height: 42, margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: dark ? AppColors.surface : AppColors.lcard, shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).dividerColor)),
          child: Icon(ic, size: 20),
        ),
        if (count > 0)
          Positioned(right: 2, top: 4, child: Container(
            padding: const EdgeInsets.all(4), constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Text('$count', textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)))),
      ]),
    );
  }

  Widget _bottomBar(AppState st) {
    const items = [
      (Icons.home_rounded, 'Bosh sahifa'),
      (Icons.grid_view_rounded, 'Mahsulotlar'),
      (Icons.calculate_rounded, 'Hisoblagich'),
      (Icons.shopping_cart_rounded, 'Savat'),
      (Icons.person_rounded, 'Profil'),
    ];
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.surface : AppColors.lcard,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == _index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _goTab(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(alignment: Alignment.center, children: [
                        Icon(items[i].$1, size: 23, color: active ? AppColors.primary : AppColors.muted),
                        if (i == 3 && st.cartCount > 0)
                          Positioned(right: -8, top: -4, child: Container(
                            padding: const EdgeInsets.all(3), constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: Text('${st.cartCount}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800)))),
                      ]),
                      const SizedBox(height: 3),
                      Text(items[i].$2, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? AppColors.primary : AppColors.muted)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _errorView() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off, size: 48, color: AppColors.textDim),
          const SizedBox(height: 12),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 30), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textDim))),
          const SizedBox(height: 16),
          SizedBox(width: 160, child: GlowButton(label: 'Qayta urinish', icon: Icons.refresh, onTap: _load)),
        ]),
      );
}
