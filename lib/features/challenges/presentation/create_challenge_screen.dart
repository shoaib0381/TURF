import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/features/challenges/domain/models/challenge.dart';
import 'package:turf/features/challenges/presentation/providers/challenge_provider.dart';

class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _targetController = TextEditingController();
  
  String _challengeType = 'distance';
  String _activityType = 'any';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isPublic = true;
  int _xpReward = 100;
  bool _isLoading = false;

  final List<String> _challengeTypes = ['distance', 'territory', 'streak', 'speed', 'elevation'];
  final List<String> _activityTypes = ['run', 'walk', 'cycle', 'any'];
  final List<int> _xpOptions = [50, 100, 200, 500];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final challenge = Challenge(
        id: '', // Supabase will gen
        createdBy: Supabase.instance.client.auth.currentUser!.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        challengeType: _challengeType,
        targetValue: double.parse(_targetController.text.trim()),
        activityType: _activityType,
        startsAt: _startDate,
        endsAt: _endDate,
        isPublic: _isPublic,
        xpReward: _xpReward,
        createdAt: DateTime.now(),
      );

      await ref.read(challengeRepositoryProvider).createChallenge(challenge);
      ref.invalidate(activeChallengesProvider);
      ref.invalidate(myChallengesProvider);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge created successfully!'), backgroundColor: Color(0xFF00E676)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Create Challenge', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Title
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Challenge Title',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1C1C1E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  TextFormField(
                    controller: _descController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Description (Optional)',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1C1C1E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Challenge Type Segmented
                  const Text('Challenge Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _challengeTypes.map((t) => ChoiceChip(
                      label: Text(t.toUpperCase()),
                      selected: _challengeType == t,
                      selectedColor: const Color(0xFF00E676).withOpacity(0.2),
                      backgroundColor: const Color(0xFF141414),
                      labelStyle: TextStyle(color: _challengeType == t ? const Color(0xFF00E676) : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                      onSelected: (s) => setState(() => _challengeType = t),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Target Value
                  TextFormField(
                    controller: _targetController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Target Value (e.g. 50)',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1C1C1E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (v) => v!.isEmpty || double.tryParse(v) == null ? 'Valid number required' : null,
                  ),
                  const SizedBox(height: 24),

                  // Activity Type
                  const Text('Activity Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _activityTypes.map((t) => ChoiceChip(
                      label: Text(t.toUpperCase()),
                      selected: _activityType == t,
                      selectedColor: const Color(0xFF00E676).withOpacity(0.2),
                      backgroundColor: const Color(0xFF141414),
                      labelStyle: TextStyle(color: _activityType == t ? const Color(0xFF00E676) : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                      onSelected: (s) => setState(() => _activityType = t),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),

                  // XP Reward
                  const Text('XP Reward', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: _xpOptions.map((xp) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text('$xp XP'),
                          selected: _xpReward == xp,
                          selectedColor: const Color(0xFF00E676).withOpacity(0.2),
                          backgroundColor: const Color(0xFF141414),
                          labelStyle: TextStyle(color: _xpReward == xp ? const Color(0xFF00E676) : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                          onSelected: (s) => setState(() => _xpReward = xp),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 40),

                  // Submit
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('CREATE CHALLENGE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }
}
