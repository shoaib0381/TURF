import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/features/goals/domain/models/fitness_goal.dart';
import 'package:turf/features/goals/presentation/providers/goal_provider.dart';

class CreateGoalScreen extends ConsumerStatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetController = TextEditingController();
  
  String _goalType = 'weekly_distance';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  final Map<String, String> _goalTypes = {
    'weekly_distance': 'Weekly Distance',
    'monthly_distance': 'Monthly Distance',
    'weekly_sessions': 'Weekly Sessions',
    'streak': 'Streak Days',
  };

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  String _getUnit() {
    if (_goalType.contains('distance')) return 'km';
    if (_goalType.contains('sessions')) return 'sessions';
    if (_goalType == 'streak') return 'days';
    return '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final goal = FitnessGoal(
        id: '', // Supabase gen
        userId: Supabase.instance.client.auth.currentUser!.id,
        goalType: _goalType,
        targetValue: double.parse(_targetController.text.trim()),
        currentValue: 0,
        unit: _getUnit(),
        startsAt: _startDate,
        endsAt: _endDate,
        completed: false,
        createdAt: DateTime.now(),
      );

      await ref.read(goalRepositoryProvider).createGoal(goal);
      ref.invalidate(myGoalsProvider);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal created!'), backgroundColor: Color(0xFF00E676)),
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
        title: const Text('Create Goal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text('Goal Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _goalType,
                    dropdownColor: const Color(0xFF1C1C1E),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1C1C1E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: _goalTypes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (v) {
                      setState(() {
                        _goalType = v!;
                        if (_goalType.contains('weekly')) _endDate = _startDate.add(const Duration(days: 7));
                        if (_goalType.contains('monthly')) _endDate = _startDate.add(const Duration(days: 30));
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  Text('Target Value (${_getUnit()})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _targetController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'e.g. 10',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1C1C1E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (v) => v!.isEmpty || double.tryParse(v) == null ? 'Valid number required' : null,
                  ),
                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('CREATE GOAL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }
}
