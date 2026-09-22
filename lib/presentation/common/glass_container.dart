import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/luxury_colors.dart';

/// 2027 Neo-Glassmorphism Container
/// Uses BackdropFilter with sigma 16 blur, 0.55 opacity acrylic tint, and specular gradient border.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double blurSigma;
  final Color? customFillColor;
  final Gradient? customBorderGradient;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 18.0,
    this.blurSigma = 16.0,
    this.customFillColor,
    this.customBorderGradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: LuxuryColors.radiantGold.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: CustomPaint(
            painter: _SpecularBorderPainter(
              borderRadius: borderRadius,
              gradient: customBorderGradient ?? LuxuryColors.specularBorder,
              borderWidth: 1.0,
            ),
            child: Container(
              padding: padding,
              color: customFillColor ?? LuxuryColors.acrylicGlass.withOpacity(0.55),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

class _SpecularBorderPainter extends CustomPainter {
  final double borderRadius;
  final Gradient gradient;
  final double borderWidth;

  _SpecularBorderPainter({
    required this.borderRadius,
    required this.gradient,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SpecularBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth;
  }
}
