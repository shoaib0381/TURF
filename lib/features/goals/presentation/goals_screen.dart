import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:turf/features/goals/presentation/providers/goal_provider.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(myGoalsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('My Goals', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
        error: (e, _) => Center(child: Text('Error loading goals: $e', style: const TextStyle(color: Colors.red))),
        data: (goals) {
          if (goals.isEmpty) {
            return const Center(child: Text('No active goals. Tap + to create one.', style: TextStyle(color: Colors.white54)));
          }

          return RefreshIndicator(
            color: const Color(0xFF00E676),
            backgroundColor: const Color(0xFF1C1C1E),
            onRefresh: () => ref.refresh(myGoalsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final goal = goals[index];
                final progress = (goal.currentValue / goal.targetValue).clamp(0.0, 1.0);
                final timeRemaining = goal.endsAt.difference(DateTime.now());
                final isExpired = timeRemaining.isNegative && !goal.completed;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: goal.completed ? const Color(0xFF00E676) : Colors.white10),
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
                            child: Icon(_getIconForType(goal.goalType), color: const Color(0xFF00E676)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_formatGoalType(goal.goalType), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.timer, size: 12, color: Colors.white54),
                                    const SizedBox(width: 4),
                                    Text(
                                      goal.completed ? 'Completed' : (isExpired ? 'Expired' : '${timeRemaining.inDays} days left'),
                                      style: TextStyle(color: goal.completed ? const Color(0xFF00E676) : (isExpired ? Colors.red : Colors.white54), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (goal.completed)
                            const Icon(Icons.check_circle, color: Color(0xFF00E676))
                          else
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white24),
                              onPressed: () async {
                                await ref.read(goalRepositoryProvider).deleteGoal(goal.id);
                                ref.invalidate(myGoalsProvider);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          Text(
                            '${goal.currentValue.toStringAsFixed(1)} / ${goal.targetValue.toStringAsFixed(1)} ${goal.unit ?? ""}',
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
                          valueColor: AlwaysStoppedAnimation<Color>(goal.completed ? const Color(0xFF00E676) : const Color(0xFF0A84FF)),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/goals/create'),
        backgroundColor: const Color(0xFF00E676),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'weekly_distance':
      case 'monthly_distance':
        return Icons.route;
      case 'weekly_sessions':
        return Icons.directions_run;
      case 'streak':
        return Icons.local_fire_department;
      case 'weight_loss':
        return Icons.monitor_weight;
      default:
        return Icons.track_changes;
    }
  }

  String _formatGoalType(String type) {
    return type.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}
