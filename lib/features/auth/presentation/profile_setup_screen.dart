import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf/core/theme/app_theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;
  int _selectedAvatarIndex = 0;
  File? _selectedImage;
  final _imagePicker = ImagePicker();

  final List<Color> _avatarColors = [
    Colors.red, Colors.blue, Colors.green, Colors.orange,
    Colors.purple, Colors.teal, Colors.pink, Colors.indigo,
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _selectedAvatarIndex = -1;
      });
    }
  }

  Future<void> _checkUsernameAndSave() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _errorText = 'Username cannot be empty');
      return;
    }
    if (username.length < 3) {
      setState(() => _errorText = 'Username must be at least 3 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw 'Not logged in';

      // Check if username exists
      final existing = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      if (existing != null) {
        setState(() => _errorText = 'Username is already taken');
        return;
      }

      String? avatarUrl;
      String? avatarColor;

      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final fileExt = _selectedImage!.path.split('.').last;
        final fileName = '${session.user.id}-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        
        await Supabase.instance.client.storage.from('avatars').uploadBinary(
          fileName,
          bytes,
        );
        avatarUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);
      } else if (_selectedAvatarIndex >= 0) {
        avatarColor = _avatarColors[_selectedAvatarIndex].value.toRadixString(16);
      } else {
        // Fallback
        avatarColor = _avatarColors[0].value.toRadixString(16);
      }

      // Insert profile
      await Supabase.instance.client.from('profiles').insert({
        'id': session.user.id,
        'username': username,
        if (avatarColor != null) 'avatar_color': avatarColor,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'created_at': DateTime.now().toIso8601String(),
        'xp': 0,
      });

      if (mounted) context.go('/home/map');
    } catch (e) {
      setState(() => _errorText = 'Failed to create profile. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Profile Image or Avatar',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF141414),
                  backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                  child: _selectedImage == null
                      ? const Icon(Icons.add_a_photo, size: 40, color: Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Or choose a color',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _avatarColors.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedAvatarIndex == index;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedAvatarIndex = index;
                    _selectedImage = null;
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _avatarColors[index],
                      border: isSelected
                          ? Border.all(color: AppTheme.primaryColor, width: 4)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: 'Username',
                errorText: _errorText,
              ),
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
            ),
            const SizedBox(height: 48),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : ElevatedButton(
                    onPressed: _checkUsernameAndSave,
                    child: const Text("Let's Go"),
                  ),
          ],
        ),
      ),
    );
  }
}
