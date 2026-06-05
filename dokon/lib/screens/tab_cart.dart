import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../icons.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/glass.dart';
import '../widgets/checkout.dart';

class CartTab extends StatelessWidget {
  final VoidCallback onShop;
  const CartTab({super.key, required this.onShop});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    if (st.cart.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.shopping_cart_outlined, size: 60, color: AppColors.textDim.withValues(alpha: 0.5)),
          const SizedBox(height: 14),
          const Text('Savat bo\'sh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Mahsulot qo\'shib boshlang', style: TextStyle(color: AppColors.textDim, fontSize: 13)),
          const SizedBox(height: 18),
          SizedBox(width: 180, child: GlowButton(label: 'Xarid qilish', icon: Icons.storefront, onTap: onShop)),
        ]),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Text('Savat', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Text('${st.cart.length} ta mahsulot', style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
            const Spacer(),
            GestureDetector(onTap: () => st.clearCart(), child: const Text('Tozalash', style: TextStyle(color: AppColors.danger, fontSize: 12.5, fontWeight: FontWeight.w600))),
          ]),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            itemCount: st.cart.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final it = st.cart[i];
              return GlassCard(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  ProductThumb(imageUrl: null, icon: iconFor(it.icon), size: 50, radius: 10),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(it.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text(it.isBonus ? 'Bonus (0 so\'m)' : money(it.price * it.qty),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13.5)),
                  ])),
                  Column(children: [
                    Row(children: [
                      _qtyBtn(context, Icons.remove, () => st.changeQty(it, -1)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${it.qty}', style: const TextStyle(fontWeight: FontWeight.w700))),
                      _qtyBtn(context, Icons.add, () => st.changeQty(it, 1)),
                    ]),
                  ]),
                ]),
              );
            },
          ),
        ),
        _footer(context, st),
      ],
    );
  }

  Widget _qtyBtn(BuildContext context, IconData ic, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(ic, size: 15, color: AppColors.primary),
        ),
      );

  Widget _footer(BuildContext context, AppState st) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: dark ? AppColors.surface : AppColors.lcard,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _row('Mahsulotlar (${st.cartCount})', money(st.cartTotal)),
        const SizedBox(height: 6),
        _row('Yetkazib berish', 'Bepul', valueColor: AppColors.secondary),
        const Divider(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Jami summa', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          Text(money(st.cartTotal), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
        ]),
        const SizedBox(height: 12),
        GlowButton(label: 'Buyurtma qilish', icon: Icons.check_circle_outline,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()))),
      ]),
    );
  }

  Widget _row(String a, String b, {Color? valueColor}) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(a, style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
        Text(b, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: valueColor)),
      ]);
}
