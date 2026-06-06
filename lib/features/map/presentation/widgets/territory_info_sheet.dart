import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:turf/features/map/domain/models/territory.dart';

class TerritoryInfoSheet extends StatelessWidget {
  final Territory territory;
  final bool canCapture;
  final bool isOwnedByMe;
  final VoidCallback onCapture;

  const TerritoryInfoSheet({
    super.key,
    required this.territory,
    required this.canCapture,
    required this.isOwnedByMe,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
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
          // Drag handle
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
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  territory.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '+${territory.xpValue} XP',
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Owner Info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF1C1C1E),
                child: territory.ownerId != null
                    ? const Icon(Icons.person, color: Colors.white54)
                    : const Icon(Icons.flag, color: Colors.white54),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    territory.ownerId != null ? 'Owner Name' : 'Unclaimed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Captured ${territory.captureCount} times',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          
          if (isOwnedByMe)
            Center(
              child: Text(
                'Your Territory',
                style: TextStyle(
                  color: const Color(0xFF00E676).withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: canCapture ? onCapture : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  disabledBackgroundColor: const Color(0xFF1C1C1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  canCapture ? 'CAPTURE' : 'TOO FAR (Get within 200m)',
                  style: TextStyle(
                    color: canCapture ? Colors.black : Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
