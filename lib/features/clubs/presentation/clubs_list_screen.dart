import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:turf/core/widgets/empty_state.dart';
import 'package:turf/features/clubs/domain/models/club.dart';
import 'package:turf/features/clubs/presentation/providers/club_provider.dart';

class ClubsListScreen extends ConsumerStatefulWidget {
  const ClubsListScreen({super.key});

  @override
  ConsumerState<ClubsListScreen> createState() => _ClubsListScreenState();
}

class _ClubsListScreenState extends ConsumerState<ClubsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Club>? _searchResults;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      try {
        final results = await ref.read(clubRepositoryProvider).searchClubs(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _joinClub(Club club) async {
    try {
      await ref.read(clubRepositoryProvider).joinClub(club.id, club.isPublic);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(club.isPublic ? 'Joined ${club.name}!' : 'Request sent to ${club.name}'),
          backgroundColor: const Color(0xFF00E676),
        ),
      );
      if (club.isPublic) {
        ref.invalidate(myClubsProvider);
        ref.invalidate(discoverClubsProvider);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to join club.')));
    }
  }

  Widget _buildClubCard(Club club, {bool isDiscover = false}) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final isOwner = club.createdBy == currentUserId;

    return GestureDetector(
      onTap: () => context.push('/clubs/${club.id}', extra: club),
      child: Container(
        width: isDiscover ? double.infinity : 280,
        margin: EdgeInsets.only(right: isDiscover ? 0 : 16, bottom: isDiscover ? 16 : 0),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: isOwner && !isDiscover ? const Border(left: BorderSide(color: Color(0xFF00E676), width: 4)) : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF2C2C2E),
              backgroundImage: club.avatarUrl != null ? CachedNetworkImageProvider(club.avatarUrl!) : null,
              child: club.avatarUrl == null
                  ? Text(club.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      if (!club.isPublic) const Icon(Icons.lock, color: Colors.white54, size: 14),
                      if (!club.isPublic) const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          club.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${club.memberCount} members • ${club.totalDistanceKm.toStringAsFixed(0)} km',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isDiscover)
              ElevatedButton(
                onPressed: () => _joinClub(club),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text('Join', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myClubsAsync = ref.watch(myClubsProvider);
    final discoverClubsAsync = ref.watch(discoverClubsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Clubs', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/clubs/create'),
        backgroundColor: const Color(0xFF00E676),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Search or enter invite code...',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_isSearching)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E676))),
                  ],
                ),
              ),
            ),
          ),
          if (_searchResults != null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (_searchResults!.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Text('No clubs found.', style: TextStyle(color: Colors.white54)),
                        ),
                      );
                    }
                    return _buildClubCard(_searchResults![index], isDiscover: true);
                  },
                  childCount: _searchResults!.isEmpty ? 1 : _searchResults!.length,
                ),
              ),
            )
          else ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('My Clubs', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: myClubsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
                  error: (e, _) => const Center(child: Text('Error loading clubs', style: TextStyle(color: Colors.red))),
                  data: (clubs) {
                    if (clubs.isEmpty) {
                      return const Center(
                        child: Text('Create your first club or join one', style: TextStyle(color: Colors.white54)),
                      );
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: clubs.length,
                      itemBuilder: (context, index) => _buildClubCard(clubs[index], isDiscover: false),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 8),
                child: Text('Discover', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            discoverClubsAsync.when(
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))),
              error: (e, _) => const SliverToBoxAdapter(child: Center(child: Text('Error loading discover', style: TextStyle(color: Colors.red)))),
              data: (clubs) {
                if (clubs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Center(child: Text('No public clubs available to join.', style: TextStyle(color: Colors.white54))),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildClubCard(clubs[index], isDiscover: true),
                      childCount: clubs.length,
                    ),
                  ),
                );
              },
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding for FAB
        ],
      ),
    );
  }
}
