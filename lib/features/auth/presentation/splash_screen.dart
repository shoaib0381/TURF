import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2)); // Minimum splash duration
    
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      context.go('/onboarding');
    } else {
      // Check if profile exists
      final userId = session.user.id;
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (profile == null && mounted) {
          context.go('/profile-setup');
        } else if (mounted) {
          context.go('/home/map');
        }
      } catch (e) {
        // Fallback to auth if something goes wrong
        if (mounted) context.go('/auth');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using a network lottie for demonstration purposes
            SizedBox(
              height: 200,
              child: Lottie.network(
                'https://assets9.lottiefiles.com/packages/lf20_q7pcdz.json',
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.directions_run, size: 100, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'TURF',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 64,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 100 * _animation.value,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
