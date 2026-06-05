import 'package:flutter/material.dart';
import '../theme.dart';

bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

/// Solid fon (tungi/kunduzgi)
class GradientBg extends StatelessWidget {
  final Widget child;
  const GradientBg({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _isDark(context) ? AppColors.bg0 : AppColors.lbg,
      child: child,
    );
  }
}

/// Toza karta (solid surface + subtle border + soft shadow)
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool strong;
  final Color? glow;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.onTap,
    this.strong = false,
    this.glow,
  });

  @override
  Widget build(BuildContext context) {
    final dark = _isDark(context);
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dark ? (strong ? AppColors.elevated : AppColors.surface) : AppColors.lcard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: dark ? AppColors.glassBorder : AppColors.lborder, width: 1),
        boxShadow: glow != null
            ? [BoxShadow(color: glow!.withValues(alpha: 0.30), blurRadius: 22, spreadRadius: -4)]
            : [BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.20 : 0.05), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(radius), onTap: onTap, child: card);
  }
}

/// Ko'k gradient tugma (glow bilan)
class GlowButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading;
  final Color? color;
  const GlowButton({super.key, required this.label, this.icon, this.onTap, this.loading = false, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    final fg = c.computeLuminance() > 0.55 ? Colors.black : Colors.white;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 16, spreadRadius: -4, offset: const Offset(0, 5))],
        ),
        child: Center(
          child: loading
              ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: fg, strokeWidth: 2.5))
              : Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[Icon(icon, color: fg, size: 19), const SizedBox(width: 9)],
                  Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15)),
                ]),
        ),
      ),
    );
  }
}

/// Ikon doirasi (ko'k tint)
class GlowIconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  const GlowIconBox({super.key, required this.icon, this.size = 46, this.color = AppColors.primary});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isDark(context) ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(size * 0.30),
      ),
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }
}

/// Input dekoratsiyasi
InputDecoration glassInput(BuildContext context, {String? hint, Widget? prefix, Widget? suffix}) {
  final dark = _isDark(context);
  final fill = dark ? AppColors.surface : AppColors.lcard;
  final border = dark ? AppColors.glassBorder : AppColors.lborder;
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: dark ? AppColors.textDim : AppColors.ltextDim, fontSize: 14),
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
  );
}

/// Mahsulot rasmi yoki ikon (image_url bo'lsa rasm, bo'lmasa ikon)
class ProductThumb extends StatelessWidget {
  final String? imageUrl;
  final IconData icon;
  final double size;
  final double radius;
  const ProductThumb({super.key, this.imageUrl, required this.icon, this.size = 80, this.radius = 14});
  @override
  Widget build(BuildContext context) {
    final dark = _isDark(context);
    final bg = dark ? AppColors.elevated : AppColors.lsurface2;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(imageUrl!, width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _iconBox(bg)),
      );
    }
    return _iconBox(bg);
  }
  Widget _iconBox(Color bg) => Container(
        width: size, height: size,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
        child: Icon(icon, color: AppColors.primary, size: size * 0.42),
      );
}
