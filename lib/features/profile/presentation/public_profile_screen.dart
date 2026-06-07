import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:turf/features/profile/domain/models/profile.dart';
import 'package:turf/features/friends/presentation/providers/friends_provider.dart';

class PublicProfileScreen extends ConsumerWidget {
  final Profile profile;

  const PublicProfileScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(profile.username, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF1C1C1E),
                backgroundImage: profile.avatarUrl != null ? CachedNetworkImageProvider(profile.avatarUrl!) : null,
                child: profile.avatarUrl == null ? const Icon(Icons.person, size: 60, color: Colors.white54) : null,
              ),
              const SizedBox(height: 16),
              
              // Name and Level
              Text(
                profile.fullName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Color(0xFF00E676), size: 16),
                    const SizedBox(width: 4),
                    Text('Level ${profile.level}', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              if (profile.lastActive != null)
                Text('Active ${timeago.format(profile.lastActive!)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              
              const SizedBox(height: 32),

              // Add Friend Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(socialRepositoryProvider).sendRequestSimple(profile.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend request sent!'), backgroundColor: Color(0xFF00E676)));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send request'), backgroundColor: Color(0xFFFF453A)));
                      }
                    }
                  },
                  icon: const Icon(Icons.person_add, color: Colors.black),
                  label: const Text('ADD FRIEND', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              
              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Distance',
                      value: '${profile.totalDistanceKm.toStringAsFixed(1)} km',
                      icon: Icons.route,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: _StatCard(
                      title: 'Territories',
                      value: '12', // Mocked for UI, ideally fetch from backend
                      icon: Icons.flag,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Badges Section (Placeholder)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Badges Earned', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 16),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Icon(Icons.emoji_events, color: Color(0xFFFF9100), size: 40),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white54, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
