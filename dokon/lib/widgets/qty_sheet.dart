import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../icons.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';
import 'glass.dart';

/// "Savatga qo'shish" bosilganda miqdorni so'rovchi pastdan chiqadigan oyna.
Future<void> showAddToCartSheet(BuildContext context, Product p) async {
  final st = context.read<AppState>();
  final dark = Theme.of(context).brightness == Brightness.dark;
  int qty = 1;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: dark ? AppColors.surface : AppColors.lcard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSt) {
        final maxStock = p.stock > 0 ? p.stock : 9999;
        return Padding(
          padding: EdgeInsets.fromLTRB(18, 14, 18, 18 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 44, height: 4, decoration: BoxDecoration(
                color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            Row(children: [
              ProductThumb(imageUrl: p.imageUrl, icon: iconFor(p.icon), size: 56, radius: 12),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text(money(p.price), style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14)),
              ])),
            ]),
            const SizedBox(height: 18),
            const Align(alignment: Alignment.centerLeft,
                child: Text('Miqdorini kiriting', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _stepBtn(ctx, Icons.remove, () { if (qty > 1) setSt(() => qty--); }),
              Container(
                width: 90, alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: dark ? AppColors.bg0 : AppColors.lsurface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(ctx).dividerColor),
                ),
                child: Text('$qty', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
              _stepBtn(ctx, Icons.add, () { if (qty < maxStock) setSt(() => qty++); }),
            ]),
            const SizedBox(height: 10),
            Text('Jami: ${money(p.price * qty)}',
                style: const TextStyle(color: AppColors.textDim, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            GlowButton(
              label: 'Savatga qo\'shish',
              icon: Icons.shopping_cart_rounded,
              onTap: () {
                st.addProductQty(p, qty);
                Navigator.pop(ctx);
                notify(context, '"${p.name}" × $qty savatga qo\'shildi');
              },
            ),
          ]),
        );
      });
    },
  );
}

Widget _stepBtn(BuildContext ctx, IconData ic, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(ic, color: AppColors.primary, size: 24),
      ),
    );
