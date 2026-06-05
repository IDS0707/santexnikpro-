import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../icons.dart';
import '../state.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/glass.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final st = context.read<AppState>();
    final out = p.stock <= 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mahsulot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.surface : AppColors.lsurface2,
                borderRadius: BorderRadius.circular(20)),
              child: ProductThumb(imageUrl: p.imageUrl, icon: iconFor(p.icon), size: 200, radius: 16),
            ),
          ),
          const SizedBox(height: 18),
          Row(children: [
            if (p.categoryName != null)
              Text(p.categoryName!.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            const Spacer(),
            Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: out ? AppColors.muted : AppColors.secondary, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(out ? 'Tugagan' : '${p.stock} ${p.unit}', style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
            ]),
          ]),
          const SizedBox(height: 6),
          Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(money(p.price), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 24)),
            if (p.oldPrice != null) ...[
              const SizedBox(width: 8),
              Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(money(p.oldPrice!),
                  style: const TextStyle(color: AppColors.textDim, fontSize: 14, decoration: TextDecoration.lineThrough))),
            ],
          ]),
          if (p.description != null && p.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Tavsif', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 6),
            Text(p.description!, style: const TextStyle(color: AppColors.textDim, fontSize: 13.5, height: 1.6)),
          ],
          const SizedBox(height: 22),
          if (!out)
            Row(children: [
              const Text('Miqdor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              _step(Icons.remove, () => setState(() { if (_qty > 1) _qty--; })),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('$_qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              _step(Icons.add, () => setState(() { if (_qty < p.stock) _qty++; })),
            ]),
          const SizedBox(height: 22),
          if (!out)
            GlowButton(label: 'Savatga qo\'shish — ${money(p.price * _qty)}', icon: Icons.shopping_cart_outlined,
                onTap: () { st.addProductQty(p, _qty); notify(context, '$_qty ${p.unit} savatga qo\'shildi'); Navigator.pop(context); }),
        ],
      ),
    );
  }

  Widget _step(IconData ic, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(ic, color: AppColors.primary, size: 20),
        ),
      );
}
