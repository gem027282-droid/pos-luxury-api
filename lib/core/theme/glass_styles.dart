import 'package:flutter/material.dart';
import 'luxury_colors.dart';

class GlassStyles {
  static const double defaultBlurSigma = 16.0;
  static const double defaultBorderRadius = 18.0;

  static BoxDecoration luxuryGlassDecoration({
    double borderRadius = defaultBorderRadius,
    Color? customColor,
    Border? customBorder,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: customColor ?? LuxuryColors.acrylicGlass.withOpacity(0.55),
      borderRadius: BorderRadius.circular(borderRadius),
      border: customBorder ??
          Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1.0,
          ),
      boxShadow: shadows ??
          [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: LuxuryColors.radiantGold.withOpacity(0.04),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, -2),
            ),
          ],
    );
  }

  static BoxDecoration goldenAccentDecoration({
    double borderRadius = defaultBorderRadius,
  }) {
    return BoxDecoration(
      gradient: LuxuryColors.goldGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: LuxuryColors.radiantGold.withOpacity(0.35),
          blurRadius: 20,
          spreadRadius: 1,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
