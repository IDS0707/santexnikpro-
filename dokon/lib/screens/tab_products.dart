import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../icons.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/glass.dart';
import '../widgets/qty_sheet.dart';

class ProductsTab extends StatelessWidget {
  final List<Product> products;
  final List<Category> categories;
  final String filter;
  final String search;
  final void Function(String) onFilter;
  final void Function(String) onSearch;
  final void Function(Product) onOpenProduct;
  const ProductsTab({
    super.key,
    required this.products,
    required this.categories,
    required this.filter,
    required this.search,
    required this.onFilter,
    required this.onSearch,
    required this.onOpenProduct,
  });

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    var list = products;
    if (filter != 'all') {
      final fid = int.tryParse(filter);
      list = list.where((p) => p.categoryId == fid).toList();
    }
    if (search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
          child: TextField(
            onChanged: onSearch,
            decoration: glassInput(context, hint: 'Mahsulot qidirish...', prefix: const Icon(Icons.search, color: AppColors.textDim)),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              _chip('Barchasi', filter == 'all', () => onFilter('all')),
              ...categories.map((c) => _chip(c.name, filter == '${c.id}', () => onFilter('${c.id}'))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
          child: Align(alignment: Alignment.centerLeft,
              child: Text('${list.length} ta mahsulot', style: const TextStyle(color: AppColors.textDim, fontSize: 12.5))),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.search_off_rounded, size: 46, color: AppColors.textDim),
                  SizedBox(height: 10), Text('Mahsulot topilmadi', style: TextStyle(color: AppColors.textDim)),
                ]))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.62),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _card(context, list[i], st),
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Builder(builder: (context) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : (dark ? AppColors.surface : AppColors.lcard),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: active ? AppColors.primary : Theme.of(context).dividerColor),
            ),
            child: Text(label, style: TextStyle(
                color: active ? Colors.white : null, fontWeight: FontWeight.w600, fontSize: 12.5)),
          );
        }),
      ),
    );
  }

  Widget _card(BuildContext context, Product p, AppState st) {
    final inCart = st.cart.where((i) => i.id == p.id && !i.isBonus).toList();
    final qty = inCart.isEmpty ? 0 : inCart.first.qty;
    final out = p.stock <= 0;
    return GlassCard(
      onTap: () => onOpenProduct(p),
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          Center(child: ProductThumb(imageUrl: p.imageUrl, icon: iconFor(p.icon), size: 110, radius: 12)),
          if (p.badge != null) Positioned(top: 0, left: 0, child: _badge(p)),
        ]),
        const SizedBox(height: 8),
        Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, height: 1.2)),
        const Spacer(),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(money(p.price), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14)),
            if (p.oldPrice != null)
              Text(money(p.oldPrice!), style: const TextStyle(color: AppColors.textDim, fontSize: 10.5, decoration: TextDecoration.lineThrough)),
          ])),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity, height: 36,
          child: out
              ? Container(alignment: Alignment.center, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Tugagan', style: TextStyle(fontSize: 12, color: AppColors.textDim)))
              : GestureDetector(
                  onTap: () => showAddToCartSheet(context, p),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: qty > 0 ? AppColors.secondary : AppColors.primary,
                      borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(qty > 0 ? Icons.check : Icons.add, size: 15, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(qty > 0 ? 'Savatda ($qty)' : 'Savatga', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _badge(Product p) {
    Color c; String txt = p.badge!;
    switch (p.badge) {
      case 'Chegirma':
        c = AppColors.accent;
        if (p.oldPrice != null && p.oldPrice! > 0) txt = '-${(100 - (p.price / p.oldPrice! * 100)).round()}%';
        break;
      case 'Popular': c = AppColors.danger; txt = 'TOP'; break;
      default: c = AppColors.secondary; txt = 'YANGI';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)),
      child: Text(txt, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
    );
  }
}
