import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserLocationMarker extends StatelessWidget {
  final String? avatarUrl;
  final String? username;

  const UserLocationMarker({
    super.key,
    this.avatarUrl,
    this.username,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: 44,
        height: 52, // Extra height for the triangle pin
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Triangle pin at the bottom
            Positioned(
              bottom: 0,
              child: CustomPaint(
                size: const Size(12, 10),
                painter: _TrianglePainter(color: const Color(0xFF00E676)),
              ),
            ),
            
            // The main circular avatar with glow
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E676),
                border: Border.all(color: const Color(0xFF00E676), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E676).withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 80,
                        memCacheHeight: 80,
                        placeholder: (context, url) => _buildFallback(),
                        errorWidget: (context, url, error) => _buildFallback(),
                      )
                    : _buildFallback(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallback() {
    final initial = (username != null && username!.isNotEmpty)
        ? username![0].toUpperCase()
        : '?';

    return Container(
      color: const Color(0xFF00E676),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Space Grotesk',
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
