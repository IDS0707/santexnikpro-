import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern clean dizayn — KO'K (blue) aksent, tungi + kunduzgi
class AppColors {
  // dark fon
  static const bg0 = Color(0xFF0D1520); // asosiy
  static const bg1 = Color(0xFF111A28);
  static const surface = Color(0xFF1A2330); // karta (dark)
  static const elevated = Color(0xFF222D3D);

  // ko'k aksent
  static const primary = Color(0xFF2563EB);
  static const primaryGlow = Color(0xFF3B82F6);
  static const primaryDark = Color(0xFF1D4ED8);

  static const secondary = Color(0xFF22C55E);
  static const accent = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  static const text = Color(0xFFF1F5F9);
  static const textDim = Color(0xFF94A3B8);
  static const muted = Color(0xFF64748B);

  // eski kod aliaslari
  static const grayLight = Color(0xFF94A3B8);
  static const primaryLight = Color(0x332563EB);

  static Color glass = const Color(0xFF1A2330);
  static Color glassStrong = const Color(0xFF222D3D);
  static const glassBorder = Color(0xFF2A3645);

  // light mode
  static const lbg = Color(0xFFF4F7FB);
  static const lcard = Color(0xFFFFFFFF);
  static const lsurface2 = Color(0xFFEDF2F8);
  static const lborder = Color(0xFFE3E9F2);
  static const ltext = Color(0xFF0F172A);
  static const ltextDim = Color(0xFF64748B);
}

class AppTheme {
  static ThemeData dark() => _build(Brightness.dark);
  static ThemeData light() => _build(Brightness.light);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final text = dark ? AppColors.text : AppColors.ltext;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: b,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
    );
    final base = ThemeData(brightness: b, useMaterial3: true);
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? AppColors.bg0 : AppColors.lbg,
      cardColor: dark ? AppColors.surface : AppColors.lcard,
      dividerColor: dark ? AppColors.glassBorder : AppColors.lborder,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: text, displayColor: text),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? AppColors.bg0 : AppColors.lbg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: GoogleFonts.inter(color: text, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: dark ? AppColors.surface : AppColors.lcard,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary : null),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary.withValues(alpha: 0.35) : null),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
