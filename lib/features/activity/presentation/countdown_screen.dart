import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turf/features/activity/presentation/providers/live_activity_provider.dart';

class CountdownScreen extends ConsumerStatefulWidget {
  const CountdownScreen({super.key});

  @override
  ConsumerState<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends ConsumerState<CountdownScreen> {
  int _count = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveActivityProvider.notifier).startCountdown();
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_count == 1) {
        timer.cancel();
        ref.read(liveActivityProvider.notifier).startActivity();
        context.pushReplacement('/activity/live');
      } else {
        setState(() {
          _count--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child));
          },
          child: Text(
            '$_count',
            key: ValueKey<int>(_count),
            style: const TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00E676),
              fontFamily: 'Space Grotesk',
            ),
          ),
        ),
      ),
    );
  }
}
