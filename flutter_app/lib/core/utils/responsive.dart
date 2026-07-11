import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  // Breakpoints
  static const double mobileMax = 600.0;
  static const double tabletMax = 1100.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMax;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMax &&
      MediaQuery.of(context).size.width < tabletMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMax;

  /// Returns the current screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Returns the current screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Returns a responsive value based on screen size
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= tabletMax && desktop != null) {
      return desktop;
    } else if (width >= mobileMax && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Returns responsive padding based on screen size
  static EdgeInsets padding(BuildContext context) {
    return EdgeInsets.all(
      value<double>(context: context, mobile: 16, tablet: 28, desktop: 36),
    );
  }

  /// Returns responsive horizontal padding
  static EdgeInsets horizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: value<double>(
        context: context,
        mobile: 16,
        tablet: 28,
        desktop: 36,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= tabletMax && desktop != null) {
          return desktop!;
        } else if (constraints.maxWidth >= mobileMax && tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}
