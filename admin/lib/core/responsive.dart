import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const mobile = 480;
  static const tablet = 768;
  static const desktop = 1024;
  static const largeDesktop = 1440;
}

class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.tablet;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tablet &&
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.largeDesktop;

  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < ResponsiveBreakpoints.tablet) return 16;
    if (width < ResponsiveBreakpoints.desktop) return 24;
    return 32;
  }

  static double getVerticalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < ResponsiveBreakpoints.tablet) return 12;
    if (width < ResponsiveBreakpoints.desktop) return 16;
    return 20;
  }

  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < ResponsiveBreakpoints.tablet) return 1;
    if (width < ResponsiveBreakpoints.desktop) return 2;
    if (width < ResponsiveBreakpoints.largeDesktop) return 3;
    return 4;
  }

  static double getCardElevation(BuildContext context) {
    if (isMobile(context)) return 2;
    return 0;
  }

  static TextStyle getHeadingStyle(BuildContext context) {
    final size = MediaQuery.of(context).size.width;
    if (size < ResponsiveBreakpoints.tablet) {
      return const TextStyle(fontSize: 18, fontWeight: FontWeight.w800);
    }
    return const TextStyle(fontSize: 24, fontWeight: FontWeight.w800);
  }

  static double getBottomSheetHeight(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return height * 0.85;
  }

  static double getDialogWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < ResponsiveBreakpoints.tablet) return width * 0.9;
    if (width < ResponsiveBreakpoints.desktop) return 500;
    return 600;
  }
}

/// Responsive Column - Automatically adjusts column count based on screen size
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.getGridColumns(context);

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children.asMap().entries.map((entry) {
        final width =
            (MediaQuery.of(context).size.width - (spacing * (columns - 1))) /
            columns;
        return SizedBox(width: width, child: entry.value);
      }).toList(),
    );
  }
}

/// Mobile-optimized card with better touch targets
class MobileOptimizedCard extends StatelessWidget {
  const MobileOptimizedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final effectivePadding = padding ?? EdgeInsets.all(isMobile ? 16 : 20);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(padding: effectivePadding, child: child),
      ),
    );
  }
}

/// Responsive container that changes layout based on screen size
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) return mobile;
    if (ResponsiveHelper.isTablet(context)) return tablet;
    return desktop;
  }
}

/// Adaptive spacing widget
class AdaptiveSpace extends StatelessWidget {
  const AdaptiveSpace({
    super.key,
    this.horizontal = true,
    this.mobile = 8,
    this.tablet = 12,
    this.desktop = 16,
  });

  final bool horizontal;
  final double mobile;
  final double tablet;
  final double desktop;

  @override
  Widget build(BuildContext context) {
    double size = mobile;
    if (ResponsiveHelper.isTablet(context)) size = tablet;
    if (ResponsiveHelper.isDesktop(context)) size = desktop;

    return horizontal ? SizedBox(width: size) : SizedBox(height: size);
  }
}
