import 'package:flutter/material.dart';

class AnimatedNumber extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final int fractionDigits;

  const AnimatedNumber({
    super.key,
    required this.value,
    this.style,
    this.prefix,
    this.suffix,
    this.fractionDigits = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        String formatted = fractionDigits > 0
            ? val.toStringAsFixed(fractionDigits)
            : val.toInt().toString();
        
        return Text(
          '${prefix ?? ''}$formatted${suffix ?? ''}',
          style: style,
        );
      },
    );
  }
}
