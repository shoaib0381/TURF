import 'package:flutter/material.dart';

class PulsingMarker extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingMarker({
    super.key,
    this.color = const Color(0xFF00E676),
    this.size = 20.0,
  });

  @override
  State<PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<PulsingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.6),
                  blurRadius: 10 * _animation.value,
                  spreadRadius: 2 * _animation.value,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
