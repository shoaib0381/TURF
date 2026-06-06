import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:turf/features/activity/presentation/providers/live_activity_provider.dart';

class ActivityTypePicker extends ConsumerWidget {
  const ActivityTypePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Choose Activity',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TypeCard(
                type: 'run',
                icon: Icons.directions_run,
                color: const Color(0xFF00E676),
                onTap: () => _startActivity(context, ref, 'run'),
              ),
              _TypeCard(
                type: 'walk',
                icon: Icons.directions_walk,
                color: const Color(0xFF0A84FF),
                onTap: () => _startActivity(context, ref, 'walk'),
              ),
              _TypeCard(
                type: 'cycle',
                icon: Icons.directions_bike,
                color: const Color(0xFFFF9F0A),
                onTap: () => _startActivity(context, ref, 'cycle'),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _startActivity(BuildContext context, WidgetRef ref, String type) {
    ref.read(liveActivityProvider.notifier).setActivityType(type);
    Navigator.pop(context); // Close sheet
    context.push('/activity/countdown');
  }
}

class _TypeCard extends StatelessWidget {
  final String type;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TypeCard({
    required this.type,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              type.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }
}
