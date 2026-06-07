import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _userResults = [];
  List<dynamic> _territoryResults = [];
  bool _isLoading = false;

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _userResults = [];
        _territoryResults = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      // Search Users
      final users = await supabase
          .from('profiles')
          .select()
          .ilike('username', '%${query.trim()}%')
          .limit(5);

      // Search Territories
      final territories = await supabase
          .from('territories')
          .select()
          .ilike('name', '%${query.trim()}%')
          .limit(5);

      if (mounted) {
        setState(() {
          _userResults = users;
          _territoryResults = territories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search users or territories...',
            hintStyle: const TextStyle(color: Colors.white54),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: Colors.white54),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
          ),
          onChanged: _performSearch,
          autofocus: true,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_userResults.isNotEmpty) ...[
                  const Text('Users', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  ..._userResults.map((u) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1C1C1E),
                          backgroundImage: u['avatar_url'] != null ? CachedNetworkImageProvider(u['avatar_url']) : null,
                          child: u['avatar_url'] == null ? const Icon(Icons.person, color: Colors.white54) : null,
                        ),
                        title: Text(u['username'], style: const TextStyle(color: Colors.white)),
                        onTap: () => context.push('/profile/${u['id']}'),
                      )),
                  const SizedBox(height: 24),
                ],
                if (_territoryResults.isNotEmpty) ...[
                  const Text('Territories', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  ..._territoryResults.map((t) => ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF00E676).withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.flag, color: Color(0xFF00E676)),
                        ),
                        title: Text(t['name'], style: const TextStyle(color: Colors.white)),
                        subtitle: Text('Captured ${t['capture_count']} times', style: const TextStyle(color: Colors.white54)),
                        onTap: () => context.push('/home/map'), // Simple routing back to map
                      )),
                ],
                if (_userResults.isEmpty && _territoryResults.isEmpty && _searchController.text.isNotEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text('No results found.', style: TextStyle(color: Colors.white54)),
                    ),
                  ),
              ],
            ),
    );
  }
}
