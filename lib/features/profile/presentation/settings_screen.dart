import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:turf/core/theme/theme_provider.dart';
import 'package:turf/features/profile/presentation/providers/profile_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifsEnabled = true;
  String _units = 'km';
  String _privacy = 'public';

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/auth');
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to permanently delete your account and all data? This cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true) {
      // Deletion logic (usually requires a secure edge function to delete auth user, but we can sign out for now)
      // Supabase.instance.client.auth.admin.deleteUser(...)
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile Section
          _SettingsSection(
            title: 'Profile',
            children: [
              ListTile(
                title: const Text('Edit Profile'),
                subtitle: const Text('Name, Bio, Avatar'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                title: const Text('Weight'),
                subtitle: const Text('Used for calorie calculation'),
                trailing: const Text('70 kg', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                onTap: () {},
              ),
            ],
          ),

          // Preferences Section
          _SettingsSection(
            title: 'Preferences',
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                activeColor: const Color(0xFF00E676),
                value: isDark,
                onChanged: (v) {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              ),
              SwitchListTile(
                title: const Text('Push Notifications'),
                activeColor: const Color(0xFF00E676),
                value: _notifsEnabled,
                onChanged: (v) => setState(() => _notifsEnabled = v),
              ),
              ListTile(
                title: const Text('Units'),
                trailing: DropdownButton<String>(
                  value: _units,
                  dropdownColor: Theme.of(context).cardColor,
                  style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'km', child: Text('Kilometers')),
                    DropdownMenuItem(value: 'mi', child: Text('Miles')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _units = v);
                  },
                ),
              ),
              ListTile(
                title: const Text('Privacy', style: TextStyle(color: Colors.white)),
                trailing: DropdownButton<String>(
                  value: _privacy,
                  dropdownColor: const Color(0xFF1C1C1E),
                  style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'public', child: Text('Public')),
                    DropdownMenuItem(value: 'friends', child: Text('Friends Only')),
                    DropdownMenuItem(value: 'private', child: Text('Private')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _privacy = v);
                  },
                ),
              ),
            ],
          ),

          // Integrations
          _SettingsSection(
            title: 'Integrations',
            children: [
              ListTile(
                title: const Text('Google Account', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Connected', style: TextStyle(color: Colors.white54)),
                trailing: const Icon(Icons.check_circle, color: Color(0xFF0A84FF)),
              ),
            ],
          ),

          // About
          _SettingsSection(
            title: 'About',
            children: [
              ListTile(
                title: const Text('Terms & Conditions', style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.open_in_new, color: Colors.white54, size: 16),
                onTap: () => launchUrl(Uri.parse('https://www.termsfeed.com/live/340e81fc-0ff8-43cf-ae39-4a335d13462a')),
              ),
              ListTile(
                title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.open_in_new, color: Colors.white54, size: 16),
                onTap: () => launchUrl(Uri.parse('https://www.termsfeed.com/live/340e81fc-0ff8-43cf-ae39-4a335d13462a')),
              ),
            ],
          ),

          // Account Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C1C1E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('SIGN OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _deleteAccount,
                  child: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, top: 24, bottom: 8),
          child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  const Divider(color: Colors.white10, height: 1, indent: 16, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
