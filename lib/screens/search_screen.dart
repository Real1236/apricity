import 'dart:async';
import 'package:apricity/models/relationship_state.dart';
import 'package:apricity/services/social_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;
  final _service = SocialService();

  // UI state
  List<DocumentSnapshot> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  // Relationship state
  RelationshipState _rel = const RelationshipState(
    friends: {},
    outgoingPending: {},
    incomingPending: {},
  );
  StreamSubscription<RelationshipState>? _relSub;

  @override
  void initState() {
    super.initState();
    _relSub = _service.watchRelationshipState(_currentUid).listen((state) {
      if (!mounted) return;
      setState(() => _rel = state);
    });
  }

  @override
  void dispose() {
    _relSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final snap = await _service.searchUsers(query);

      final filtered = <DocumentSnapshot>[];
      for (final d in snap.docs) {
        final data = d.data() as Map<String, dynamic>;
        if (data['uid'] == _currentUid) continue;
        filtered.add(d);
      }

      if (!mounted) return;
      setState(() {
        _searchResults = filtered;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
    }
  }

  Future<void> _sendFriendRequest(
    String targetUid,
    String targetDisplayName,
  ) async {
    try {
      await _service.sendFriendRequest(targetUid, targetDisplayName);
      // optimistic UI
      setState(
        () => _rel = RelationshipState(
          friends: _rel.friends,
          outgoingPending: {..._rel.outgoingPending, targetUid},
          incomingPending: _rel.incomingPending,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request sent to $targetDisplayName')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send request: $e')));
    }
  }

  Future<void> _acceptFriendRequest(String otherUid) async {
    try {
      await _service.acceptFriendRequest(otherUid);
      // optimistic UI; CF will add edges shortly
      setState(
        () => _rel = RelationshipState(
          friends: {..._rel.friends, otherUid},
          outgoingPending: _rel.outgoingPending,
          incomingPending: {..._rel.incomingPending}..remove(otherUid),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to accept request: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Friends'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return _EmptyHint(
        icon: Icons.search,
        text: 'Search for people to add as friends',
        color: Theme.of(context).colorScheme.outline,
      );
    }

    if (_isSearching) return const Center(child: CircularProgressIndicator());

    if (_searchResults.isEmpty) {
      return _EmptyHint(
        icon: Icons.person_search,
        text: 'No users found for "$_searchQuery"',
        color: Theme.of(context).colorScheme.outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final profileDoc = _searchResults[index];
        final data = profileDoc.data() as Map<String, dynamic>;
        final targetUid = data['uid'] as String;
        final displayName = profileDoc.id;
        final photoUrl = data['photoUrl'] as String?;

        final isFriend = _rel.friends.contains(targetUid);
        final isRequestSent = _rel.outgoingPending.contains(targetUid);
        final isRequestReceived = _rel.incomingPending.contains(targetUid);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(
                      displayName[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            title: Text(displayName),
            trailing: _buildActionButton(
              targetUid,
              displayName,
              isFriend,
              isRequestSent,
              isRequestReceived,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    String targetUid,
    String targetDisplayName,
    bool isAlreadyFriend,
    bool isRequestSent,
    bool isRequestReceived,
  ) {
    if (isAlreadyFriend) {
      return const Chip(
        label: Text('Friends'),
        backgroundColor: Colors.green,
        labelStyle: TextStyle(color: Colors.white),
      );
    }
    if (isRequestSent) {
      return const Chip(
        label: Text('Pending'),
        backgroundColor: Colors.orange,
        labelStyle: TextStyle(color: Colors.white),
      );
    }
    if (isRequestReceived) {
      return ElevatedButton(
        onPressed: () => _acceptFriendRequest(targetUid),
        child: const Text('Accept Friend Request'),
      );
    }
    return ElevatedButton(
      onPressed: () => _sendFriendRequest(targetUid, targetDisplayName),
      child: const Text('Add Friend'),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _EmptyHint({
    required this.icon,
    required this.text,
    required this.color,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color),
          const SizedBox(height: 16),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
