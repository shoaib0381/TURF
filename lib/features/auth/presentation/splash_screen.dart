import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────
// MAIN SPLASH SCREEN WIDGET
// ─────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _masterCtrl;
  late AnimationController _floatCtrl; // Floating animation

  // City grid: grey → green radial reveal
  late Animation<double> _cityProgress;

  // Logo: scale in with elastic bounce
  late Animation<double> _logoScale;

  // Logo glow pulse after appearing
  late Animation<double> _logoGlow;

  // Tagline fade in
  late Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    _masterCtrl = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    );

    // Continuous smooth floating animation
    _floatCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    // City streets animate 0→1 over full duration
    _cityProgress = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.0, 0.85, curve: Curves.easeInOut),
    );

    // Logo scales in between 25%–65% of the animation
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.25, 0.65, curve: Curves.elasticOut),
      ),
    );

    // Glow pulses once the logo is fully in (65%–100%)
    _logoGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Tagline fades in at the end
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start animation then navigate after completion
    _masterCtrl.forward().then((_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
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
    _masterCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  // ── Saturation matrix helper ──────────────────
  // Returns a 4×5 color matrix for ColorFilter.matrix()
  // sat=0 → full greyscale, sat=1 → original color
  static List<double> _saturationMatrix(double sat) {
    const double rw = 0.2126, gw = 0.7152, bw = 0.0722;
    final double sr = (1 - sat) * rw;
    final double sg = (1 - sat) * gw;
    final double sb = (1 - sat) * bw;
    return [
      sr + sat, sg,       sb,       0, 0,
      sr,       sg + sat, sb,       0, 0,
      sr,       sg,       sb + sat, 0, 0,
      0,        0,        0,        1, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A05),
      body: AnimatedBuilder(
        animation: _masterCtrl,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [

              // ── Layer 1: Background image (greyscale → color) ──
              ColorFiltered(
                colorFilter: ColorFilter.matrix(
                  _saturationMatrix(_cityProgress.value),
                ),
                child: Image.asset(
                  'assets/turf_splash_bg.png', // your splash image
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Colors.black);
                  },
                ),
              ),

              // ── Layer 2: Animated city street grid overlay ──
              CustomPaint(
                painter: CityGridPainter(
                  progress: _cityProgress.value,
                ),
              ),

              // ── Layer 3: Radial green glow expanding from center ──
              CustomPaint(
                painter: RadialGlowPainter(
                  progress: _cityProgress.value,
                ),
              ),

              // ── Layer 4: Logo with scale + glow + floating ──
              Center(
                child: AnimatedBuilder(
                  animation: _floatCtrl,
                  builder: (context, child) {
                    // Smooth sine wave easing for water floating effect (-12 to +12 pixels)
                    final floatOffset = sin(_floatCtrl.value * pi) * 12.0;
                    
                    return Transform.translate(
                      offset: Offset(0, floatOffset),
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: _buildLogo(_logoGlow.value),
                      ),
                    );
                  },
                ),
              ),

              // ── Layer 5: Tagline at bottom ──
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _taglineOpacity.value,
                  child: const _Tagline(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogo(double glowIntensity) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.0,
          colors: [Color(0xFF2A2A2A), Color(0xFF0A0A0A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 255, 80, glowIntensity * 0.6),
            blurRadius: 40 * glowIntensity,
            spreadRadius: 4 * glowIntensity,
          ),
          BoxShadow(
            color: Color.fromRGBO(0, 255, 80, glowIntensity * 0.3),
            blurRadius: 80 * glowIntensity,
            spreadRadius: 10 * glowIntensity,
          ),
        ],
        border: Border.all(
          color: Color.fromRGBO(0, 220, 60, glowIntensity * 0.8),
          width: 1.5 * glowIntensity,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'TURF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                height: 1.0,
              ),
            ),
            // Green underline accent
            Container(
              width: 60,
              height: 3,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: const Color(0xFF00FF41),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CITY GRID PAINTER
// Draws a realistic street-style map grid that lights
// up brightly in green as the animation expands outward.
// ─────────────────────────────────────────────
class CityGridPainter extends CustomPainter {
  final double progress;
  CityGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxDist = sqrt(cx * cx + cy * cy);

    final path = Path();
    final majorPath = Path();

    // Use a fixed seed so the streets look identical every frame
    final rand = Random(84);

    // Calculate grid dimensions
    final int cols = 22;
    final int rows = (cols * (size.height / size.width)).round();

    final cellW = size.width / cols;
    final cellH = size.height / rows;

    // Build the grid blocks
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        // Add tiny random jitter to intersections to look like organic city blocks
        final jitterX = (rand.nextDouble() - 0.5) * (cellW * 0.3);
        final jitterY = (rand.nextDouble() - 0.5) * (cellH * 0.3);
        
        final x = (i * cellW) + jitterX;
        final y = (j * cellH) + jitterY;

        // Horizontal street segment
        if (i < cols - 1 && rand.nextDouble() > 0.25) {
          final isMajor = rand.nextDouble() > 0.85;
          final p = isMajor ? majorPath : path;
          final nextJitterY = (rand.nextDouble() - 0.5) * (cellH * 0.3);
          p.moveTo(x, y);
          p.lineTo((i + 1) * cellW, y - jitterY + nextJitterY);
        }

        // Vertical street segment
        if (j < rows - 1 && rand.nextDouble() > 0.25) {
          final isMajor = rand.nextDouble() > 0.85;
          final p = isMajor ? majorPath : path;
          final nextJitterX = (rand.nextDouble() - 0.5) * (cellW * 0.3);
          p.moveTo(x, y);
          p.lineTo(x - jitterX + nextJitterX, (j + 1) * cellH);
        }
      }
    }

    // Add a few large diagonal avenues spanning the city
    for (int i = 0; i < 5; i++) {
      final angle = rand.nextDouble() * pi;
      final offset = (rand.nextDouble() - 0.5) * size.width;

      final dx = cos(angle) * maxDist * 2;
      final dy = sin(angle) * maxDist * 2;

      final midX = cx + cos(angle + pi / 2) * offset;
      final midY = cy + sin(angle + pi / 2) * offset;

      majorPath.moveTo(midX - dx, midY - dy);
      majorPath.lineTo(midX + dx, midY + dy);
    }

    // 1. Draw base unlit streets (dark grey-green)
    final baseMinorPaint = Paint()
      ..color = const Color(0xFF142014).withOpacity(0.6)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final baseMajorPaint = Paint()
      ..color = const Color(0xFF1A2A1A).withOpacity(0.8)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, baseMinorPaint);
    canvas.drawPath(majorPath, baseMajorPaint);

    // 2. Draw glowing lit streets expanding radially
    if (progress > 0) {
      final currentRadius = maxDist * progress * 1.3; // 1.3 to reach screen corners

      if (currentRadius > 0) {
        // This gradient acts as an expanding flashlight revealing the bright green map
        final glowShader = RadialGradient(
          colors: [
            const Color(0xFF00FF41), // pure bright green core
            const Color(0xFF00FF41).withOpacity(0.7), // neon spread
            const Color(0xFF00FF41).withOpacity(0.0), // fade into darkness
          ],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: currentRadius));

        final glowMinorPaint = Paint()
          ..shader = glowShader
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

        final glowMajorPaint = Paint()
          ..shader = glowShader
          ..strokeWidth = 3.0 // Thicker glow for main avenues
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawPath(path, glowMinorPaint);
        canvas.drawPath(majorPath, glowMajorPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CityGridPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────
// RADIAL GLOW PAINTER
// Soft expanding green radial gradient
// ─────────────────────────────────────────────
class RadialGlowPainter extends CustomPainter {
  final double progress;
  RadialGlowPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final glowRadius = size.width * progress * 1.4;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromRGBO(0, 255, 65, 0.12 * progress),
          Color.fromRGBO(0, 200, 50, 0.05 * progress),
          const Color(0x00000000),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: glowRadius),
      );

    canvas.drawCircle(center, glowRadius, paint);
  }

  @override
  bool shouldRepaint(RadialGlowPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────
// TAGLINE WIDGET
// ─────────────────────────────────────────────
class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left line
            Container(width: 30, height: 1, color: Colors.white24),
            const SizedBox(width: 10),
            const Text(
              'POWERED BY ',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.5,
              ),
            ),
            const Text(
              'JTC SOLUTIONS.',
              style: TextStyle(
                color: Colors.white, // Changed from green to avoid blending into green background
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(width: 10),
            // Right line
            Container(width: 30, height: 1, color: Colors.white24),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'v1.0.0',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
