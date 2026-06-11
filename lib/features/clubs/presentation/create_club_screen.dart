import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';

import 'package:turf/features/clubs/presentation/providers/club_provider.dart';

class CreateClubScreen extends ConsumerStatefulWidget {
  const CreateClubScreen({super.key});

  @override
  ConsumerState<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends ConsumerState<CreateClubScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  
  bool _isPublic = true;
  File? _avatarFile;
  bool _isLoading = false;
  
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (pickedFile != null) {
      setState(() {
        _avatarFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadAvatar() async {
    if (_avatarFile == null) return null;
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${Supabase.instance.client.auth.currentUser!.id}.jpg';
      final path = 'clubs/$fileName';
      
      await Supabase.instance.client.storage
          .from('avatars')
          .upload(path, _avatarFile!);
          
      return Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }

  Future<void> _createClub() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final avatarUrl = await _uploadAvatar();
      
      final club = await ref.read(clubRepositoryProvider).createClub(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        isPublic: _isPublic,
        avatarUrl: avatarUrl,
      );
      
      _confettiController.play();
      ref.invalidate(myClubsProvider);
      
      if (mounted) {
        setState(() => _isLoading = false);
        // Navigate to new club detail screen and replace this one
        context.pushReplacement('/clubs/${club.id}', extra: club);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create club. Please try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Create Club', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Avatar Picker
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF1C1C1E),
                      backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                      child: _avatarFile == null
                          ? _nameController.text.isNotEmpty
                              ? Text(_nameController.text[0].toUpperCase(), style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold))
                              : const Icon(Icons.camera_alt, size: 32, color: Colors.white54)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(child: Text('Tap to upload logo', style: TextStyle(color: Colors.white54, fontSize: 12))),
                
                const SizedBox(height: 32),
                
                // Name Input
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  maxLength: 30,
                  validator: (val) => val == null || val.isEmpty ? 'Club name is required' : null,
                  decoration: InputDecoration(
                    labelText: 'Club Name',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1C1C1E),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    counterStyle: const TextStyle(color: Colors.white54),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Description Input
                TextFormField(
                  controller: _descController,
                  style: const TextStyle(color: Colors.white),
                  maxLength: 150,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1C1C1E),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    counterStyle: const TextStyle(color: Colors.white54),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Privacy Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Public Club', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Switch(
                            value: _isPublic,
                            onChanged: (val) => setState(() => _isPublic = val),
                            activeColor: const Color(0xFF00E676),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isPublic 
                            ? 'Anyone can find and join this club immediately.'
                            : 'Users must request to join or have an invite code.',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Create Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createClub,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      disabledBackgroundColor: const Color(0xFF00E676).withOpacity(0.5),
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text('Create Club', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [Color(0xFF00E676), Colors.white, Color(0xFF0A84FF)],
            ),
          ),
        ],
      ),
    );
  }
}
