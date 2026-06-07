import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:turf/features/challenges/domain/models/challenge.dart';
import 'package:turf/features/challenges/presentation/providers/challenge_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  final Challenge challenge;

  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(challengeLeaderboardProvider(challenge.id));
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Challenge', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
        error: (e, _) => Center(child: Text('Error loading challenge details', style: const TextStyle(color: Colors.red))),
        data: (participants) {
          final myParticipantIndex = participants.indexWhere((p) => p.userId == currentUserId);
          final myParticipant = myParticipantIndex != -1 ? participants[myParticipantIndex] : null;
          final isJoined = myParticipant != null;

          return CustomScrollView(
            slivers: [
              // Header Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getIconForType(challenge.challengeType), color: const Color(0xFF00E676), size: 40),
                      ),
                      const SizedBox(height: 24),
                      Text(challenge.title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      if (challenge.description != null) ...[
                        const SizedBox(height: 8),
                        Text(challenge.description!, style: const TextStyle(color: Colors.white54, fontSize: 16)),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _InfoPill(icon: Icons.flag, text: '${challenge.targetValue.toInt()} ${_getUnit(challenge.challengeType)}'),
                          _InfoPill(icon: Icons.group, text: '${participants.length} joined'),
                          _InfoPill(icon: Icons.star, text: '${challenge.xpReward} XP'),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      if (isJoined) ...[
                        // User Progress
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141414),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Your Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${myParticipant.currentValue.toStringAsFixed(1)} ${_getUnit(challenge.challengeType)}',
                                    style: const TextStyle(color: Color(0xFF00E676), fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                                  ),
                                  if (myParticipant.completed)
                                    const Text('COMPLETED', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: (myParticipant.currentValue / challenge.targetValue).clamp(0.0, 1.0),
                                backgroundColor: const Color(0xFF1C1C1E),
                                valueColor: AlwaysStoppedAnimation<Color>(myParticipant.completed ? const Color(0xFF00E676) : const Color(0xFF0A84FF)),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Join Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await ref.read(challengeRepositoryProvider).joinChallenge(challenge.id);
                              ref.invalidate(challengeLeaderboardProvider(challenge.id));
                              ref.invalidate(myChallengesProvider);
                              ref.invalidate(activeChallengesProvider);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E676),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: const Text('JOIN CHALLENGE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      const Text('Leaderboard', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Leaderboard List
              if (participants.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No participants yet.', style: TextStyle(color: Colors.white54)))),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final participant = participants[index];
                      final isMe = participant.userId == currentUserId;
                      final rank = index + 1;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF1C1C1E) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 30, child: Text('#$rank', style: TextStyle(color: isMe ? const Color(0xFF00E676) : Colors.white54, fontWeight: FontWeight.bold))),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF141414),
                              backgroundImage: participant.profile?.avatarUrl != null ? CachedNetworkImageProvider(participant.profile!.avatarUrl!) : null,
                              child: participant.profile?.avatarUrl == null ? const Icon(Icons.person, color: Colors.white54, size: 16) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                participant.profile?.fullName ?? 'Unknown',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${participant.currentValue.toStringAsFixed(1)}',
                              style: const TextStyle(color: Colors.white, fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold),
                            ),
                            if (participant.completed) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 16),
                            ],
                          ],
                        ),
                      );
                    },
                    childCount: participants.length,
                  ),
                ),
              
              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'distance': return Icons.route;
      case 'territory': return Icons.flag;
      case 'streak': return Icons.local_fire_department;
      case 'speed': return Icons.speed;
      case 'elevation': return Icons.terrain;
      default: return Icons.star;
    }
  }

  String _getUnit(String type) {
    switch (type) {
      case 'distance': return 'km';
      case 'territory': return 'territories';
      case 'streak': return 'days';
      case 'speed': return 'km/h';
      case 'elevation': return 'm';
      default: return '';
    }
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
