import 'package:flutter/material.dart';
import '../api.dart';
import '../icons.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/glass.dart';
import '../widgets/banner_carousel.dart';

class HomeTab extends StatelessWidget {
  final List<Category> categories;
  final List<Product> products;
  final List<BannerInfo> banners;
  final void Function(String filter) onPickCategory;
  final void Function(String query) onSearch;
  final VoidCallback onProducts, onCalculator, onQuickOrder, onBonus;
  final void Function(Product) onOpenProduct;
  const HomeTab({
    super.key,
    required this.categories,
    required this.products,
    this.banners = const [],
    required this.onPickCategory,
    required this.onSearch,
    required this.onProducts,
    required this.onCalculator,
    required this.onQuickOrder,
    required this.onBonus,
    required this.onOpenProduct,
  });

  @override
  Widget build(BuildContext context) {
    final discounted = products.where((p) => p.oldPrice != null && p.oldPrice! > p.price).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
      children: [
        // qidiruv
        TextField(
          textInputAction: TextInputAction.search,
          onSubmitted: onSearch,
          decoration: glassInput(context, hint: 'Mahsulot qidirish...',
              prefix: const Icon(Icons.search, color: AppColors.textDim),
              suffix: IconButton(onPressed: onProducts, icon: const Icon(Icons.tune_rounded, color: AppColors.primary))),
        ),
        const SizedBox(height: 16),
        // reklama — admin bannerlari aylanib turadi (bo'lmasa, statik banner)
        BannerCarousel(banners: banners, fallback: _promoBanner(context)),
        const SizedBox(height: 20),
        // Tez amallar
        const Text('Tez amallar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _action(context, Icons.grid_view_rounded, 'Mahsulotlar', 'Barcha tovarlar', onProducts)),
          const SizedBox(width: 12),
          Expanded(child: _action(context, Icons.calculate_rounded, 'Hisoblagich', 'Material hisoblash', onCalculator)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _action(context, Icons.bolt_rounded, 'Tez buyurtma', "Ustaga jo'natish", onQuickOrder)),
          const SizedBox(width: 12),
          Expanded(child: _action(context, Icons.card_giftcard_rounded, 'Bonuslar', 'Chegirma va ballar', onBonus)),
        ]),
        const SizedBox(height: 22),
        // Kategoriyalar
        Row(children: [
          const Text('Kategoriyalar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const Spacer(),
          GestureDetector(onTap: onProducts, child: const Text('Barchasi', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final c = categories[i];
              return GestureDetector(
                onTap: () => onPickCategory('${c.id}'),
                child: Column(children: [
                  GlowIconBox(icon: iconFor(c.icon), size: 58),
                  const SizedBox(height: 7),
                  SizedBox(width: 64, child: Text(c.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                ]),
              );
            },
          ),
        ),
        if (discounted.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(children: [
            const Text('Chegirmadagi mahsulotlar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const Spacer(),
            GestureDetector(onTap: onProducts, child: const Text('Barchasi', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: discounted.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => SizedBox(width: 150, child: _miniCard(context, discounted[i])),
            ),
          ),
        ],
      ],
    );
  }

  // Banner bo'lmaganda ko'rsatiladigan statik reklama
  Widget _promoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: -6, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Bugungi chegirmalar!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('${products.length}+ mahsulot · 24/7 buyurtma\nTez yetkazib berish mavjud',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5, height: 1.5)),
          const SizedBox(height: 12),
          GestureDetector(onTap: onProducts, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Text('Xarid qilish', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12.5)))),
        ])),
        const Icon(Icons.water_drop_rounded, color: Colors.white24, size: 64),
      ]),
    );
  }

  Widget _action(BuildContext context, IconData ic, String title, String sub, VoidCallback onTap) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        GlowIconBox(icon: ic, size: 42),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: AppColors.textDim, fontSize: 10.5), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  Widget _miniCard(BuildContext context, Product p) {
    return GlassCard(
      onTap: () => onOpenProduct(p),
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: ProductThumb(imageUrl: p.imageUrl, icon: iconFor(p.icon), size: 84)),
        const SizedBox(height: 8),
        Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(money(p.price), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
        if (p.oldPrice != null)
          Text(money(p.oldPrice!), style: const TextStyle(color: AppColors.textDim, fontSize: 10.5, decoration: TextDecoration.lineThrough)),
      ]),
    );
  }
}
