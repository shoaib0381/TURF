import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:turf/features/challenges/domain/models/challenge.dart';
import 'package:turf/features/challenges/domain/models/challenge_participant.dart';
import 'package:turf/features/challenges/presentation/providers/challenge_provider.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Challenges', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E676),
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'My Challenges'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveChallengesTab(),
          _MyChallengesTab(),
          _CompletedChallengesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/challenge/create'),
        backgroundColor: const Color(0xFF00E676),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Create', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _ActiveChallengesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeChallengesProvider);

    return activeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
      error: (e, _) => Center(child: Text('Error loading challenges: $e', style: const TextStyle(color: Colors.red))),
      data: (challenges) {
        if (challenges.isEmpty) {
          return const Center(child: Text('No active challenges found.', style: TextStyle(color: Colors.white54)));
        }

        return RefreshIndicator(
          color: const Color(0xFF00E676),
          backgroundColor: const Color(0xFF1C1C1E),
          onRefresh: () => ref.refresh(activeChallengesProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: challenges.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return ChallengeCard(challenge: challenges[index]);
            },
          ),
        );
      },
    );
  }
}

class _MyChallengesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myAsync = ref.watch(myChallengesProvider);

    return myAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
      error: (e, _) => Center(child: Text('Error loading your challenges', style: const TextStyle(color: Colors.red))),
      data: (participants) {
        final activeMyChallenges = participants.where((p) => !p.completed && p.challenge != null && p.challenge!.isActive).toList();

        if (activeMyChallenges.isEmpty) {
          return const Center(child: Text("You haven't joined any active challenges.", style: TextStyle(color: Colors.white54)));
        }

        return RefreshIndicator(
          color: const Color(0xFF00E676),
          backgroundColor: const Color(0xFF1C1C1E),
          onRefresh: () => ref.refresh(myChallengesProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: activeMyChallenges.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return ChallengeCard(
                challenge: activeMyChallenges[index].challenge!,
                participant: activeMyChallenges[index],
              );
            },
          ),
        );
      },
    );
  }
}

class _CompletedChallengesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myAsync = ref.watch(myChallengesProvider);

    return myAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
      error: (e, _) => Center(child: Text('Error loading completed challenges', style: const TextStyle(color: Colors.red))),
      data: (participants) {
        final completedChallenges = participants.where((p) => p.completed || (p.challenge != null && p.challenge!.isCompleted)).toList();

        if (completedChallenges.isEmpty) {
          return const Center(child: Text("You haven't completed any challenges yet.", style: TextStyle(color: Colors.white54)));
        }

        return RefreshIndicator(
          color: const Color(0xFF00E676),
          backgroundColor: const Color(0xFF1C1C1E),
          onRefresh: () => ref.refresh(myChallengesProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: completedChallenges.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return ChallengeCard(
                challenge: completedChallenges[index].challenge!,
                participant: completedChallenges[index],
              );
            },
          ),
        );
      },
    );
  }
}

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final ChallengeParticipant? participant;

  const ChallengeCard({super.key, required this.challenge, this.participant});

  @override
  Widget build(BuildContext context) {
    final isJoined = participant != null;
    final progress = isJoined ? (participant!.currentValue / challenge.targetValue).clamp(0.0, 1.0) : 0.0;
    
    // Calculate time remaining string
    final now = DateTime.now();
    final timeRemaining = challenge.endsAt.difference(now);
    final isEndsToday = timeRemaining.inDays == 0 && timeRemaining.inHours > 0;
    final timeString = isEndsToday ? 'Ends today!' : '${timeRemaining.inDays} days left';

    return GestureDetector(
      onTap: () => context.push('/challenge/${challenge.id}', extra: challenge),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIconForType(challenge.challengeType), color: const Color(0xFF00E676)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(challenge.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer, size: 12, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text(timeString, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${challenge.xpReward} XP',
                    style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isJoined) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(
                    '${participant!.currentValue.toStringAsFixed(1)} / ${challenge.targetValue.toStringAsFixed(1)} ${_getUnit(challenge.challengeType)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFF1C1C1E),
                  valueColor: AlwaysStoppedAnimation<Color>(participant!.completed ? const Color(0xFF00E676) : const Color(0xFF0A84FF)),
                  minHeight: 8,
                ),
              ),
            ] else ...[
              Text(
                '${challenge.targetValue.toStringAsFixed(1)} ${_getUnit(challenge.challengeType)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk', fontSize: 20),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(8)),
                  child: Text(challenge.activityType.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                if (isJoined)
                  const Text('Joined', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold))
                else
                  const Text('Tap to join', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
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
