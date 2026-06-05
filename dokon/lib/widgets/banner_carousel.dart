import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';
import '../theme.dart';

/// Bosh sahifadagi reklama karuseli — admin qo'ygan bannerlar avtomatik aylanadi.
/// Banner bo'lmasa, [fallback] ko'rsatiladi.
class BannerCarousel extends StatefulWidget {
  final List<BannerInfo> banners;
  final Widget fallback;
  const BannerCarousel({super.key, required this.banners, required this.fallback});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _ctrl = PageController();
  Timer? _timer;
  int _page = 0;

  List<BannerInfo> get _items => widget.banners;

  @override
  void initState() {
    super.initState();
    if (_items.length > 1) _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_ctrl.hasClients || _items.length < 2) return;
      final next = (_page + 1) % _items.length;
      _ctrl.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _open(BannerInfo b) async {
    if (b.linkUrl == null) return;
    final uri = Uri.tryParse(b.linkUrl!);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _bg(BannerInfo b) {
    final hex = b.backgroundColor?.replaceAll('#', '');
    if (hex != null && (hex.length == 6 || hex.length == 8)) {
      final v = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
      if (v != null) return Color(v);
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return widget.fallback;
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: _items.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => _slide(_items[i]),
          ),
        ),
        if (_items.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_items.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.muted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _slide(BannerInfo b) {
    final base = _bg(b);
    final hasText = b.title != null || b.subtitle != null;
    return GestureDetector(
      onTap: () => _open(b),
      child: Container(
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: base.withValues(alpha: 0.35), blurRadius: 18, spreadRadius: -6, offset: const Offset(0, 8))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(fit: StackFit.expand, children: [
          if (b.imageUrl != null)
            Image.network(
              b.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _gradient(base),
              loadingBuilder: (ctx, child, prog) =>
                  prog == null ? child : Container(color: base.withValues(alpha: 0.2), child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
            )
          else
            _gradient(base),
          // matn bo'lsa, pastdan o'qilishi uchun qoraytirish
          if (hasText)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
                  ),
                ),
              ),
            ),
          if (hasText)
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                if (b.title != null)
                  Text(b.title!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                if (b.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(b.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 12.5, height: 1.35)),
                ],
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _gradient(Color base) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base, Color.lerp(base, Colors.black, 0.28) ?? base],
          ),
        ),
        child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.water_drop_rounded, color: Colors.white24, size: 64),
          ),
        ),
      );
}
