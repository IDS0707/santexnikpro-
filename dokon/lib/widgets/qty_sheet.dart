import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../icons.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';
import 'glass.dart';

/// "Savatga qo'shish" bosilganda miqdorni so'rovchi pastdan chiqadigan oyna.
/// Tezkor tugmalar (10/20/30/50) va qo'lda kiritish maydoni bilan.
Future<void> showAddToCartSheet(BuildContext context, Product p) async {
  final st = context.read<AppState>();
  final dark = Theme.of(context).brightness == Brightness.dark;
  final maxStock = p.stock > 0 ? p.stock : 9999;
  int qty = 1;
  final qtyCtrl = TextEditingController(text: '1');

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: dark ? AppColors.surface : AppColors.lcard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSt) {
        // qiymatni o'rnatish + maydon matnini yangilash (zaxiraga moslab)
        void setQty(int v) {
          v = v.clamp(1, maxStock);
          setSt(() {
            qty = v;
            qtyCtrl.text = '$v';
            qtyCtrl.selection = TextSelection.fromPosition(TextPosition(offset: qtyCtrl.text.length));
          });
        }

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
            Align(
              alignment: Alignment.centerLeft,
              child: Row(children: [
                const Text('Miqdorini kiriting', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
                if (p.stock > 0)
                  Text('Mavjud: ${p.stock} ${p.unit}', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 12),
            // - [ qo'lda kiritish maydoni ] +
            Row(children: [
              _stepBtn(ctx, Icons.remove, () => setQty(qty - 1)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: qtyCtrl,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    filled: true,
                    fillColor: dark ? AppColors.bg0 : AppColors.lsurface2,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(ctx).dividerColor)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                  onChanged: (s) {
                    final v = int.tryParse(s.trim());
                    setSt(() => qty = (v == null || v < 1) ? 1 : (v > maxStock ? maxStock : v));
                  },
                  onEditingComplete: () => setQty(qty),
                ),
              ),
              const SizedBox(width: 12),
              _stepBtn(ctx, Icons.add, () => setQty(qty + 1)),
            ]),
            const SizedBox(height: 14),
            // tezkor tanlash
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Tezkor tanlash', style: TextStyle(color: AppColors.textDim, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [10, 20, 30, 50].map((n) {
                final disabled = n > maxStock;
                final active = qty == n;
                return GestureDetector(
                  onTap: disabled ? null : () => setQty(n),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : (dark ? AppColors.bg0 : AppColors.lsurface2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? AppColors.primary : Theme.of(ctx).dividerColor),
                    ),
                    child: Text('$n',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : (disabled ? AppColors.muted : null),
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Text('Jami: ${money(p.price * qty)}',
                style: const TextStyle(color: AppColors.textDim, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            GlowButton(
              label: 'Savatga qo\'shish',
              icon: Icons.shopping_cart_rounded,
              onTap: () {
                final n = qty.clamp(1, maxStock);
                st.addProductQty(p, n);
                Navigator.pop(ctx);
                notify(context, '"${p.name}" × $n savatga qo\'shildi');
              },
            ),
          ]),
        );
      });
    },
  );
  qtyCtrl.dispose();
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
