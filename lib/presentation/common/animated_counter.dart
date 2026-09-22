import 'package:flutter/material.dart';

/// Smooth Rolling Animated Counter for Monetary Amounts and Quantities
class AnimatedCounter extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.text,
    this.style,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (prefix != null) ...[
          Text(prefix!, style: style),
          const SizedBox(width: 4),
        ],
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.4),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: Text(
            text,
            key: ValueKey<String>(text),
            style: style,
          ),
        ),
        if (suffix != null) ...[
          const SizedBox(width: 4),
          Text(suffix!, style: style),
        ],
      ],
    );
  }
}
