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
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  List<DocumentSnapshot> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final QuerySnapshot profileSnapshot = await SocialService().searchUsers(
        query,
      );

      // Get user documents for matching usernames
      final List<DocumentSnapshot> userDocs = [];
      for (final profileDoc in profileSnapshot.docs) {
        final uid = profileDoc.data() as Map<String, dynamic>;
        if (uid['uid'] == _currentUid) {
          continue;
        }
        userDocs.add(profileDoc);
      }

      setState(() {
        _searchResults = userDocs;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    }
  }

  Future<void> _sendFriendRequest(
    String targetUid,
    String targetUsername,
  ) async {
    try {
      await SocialService().sendFriendRequest(targetUid, targetUsername);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request sent to $targetUsername')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send request: $e')));
      }
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
          // Search bar
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

          // Search results
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for people to add as friends',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No users found for "$_searchQuery"',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final userDoc = _searchResults[index];
        final userData = userDoc.data() as Map<String, dynamic>;
        final displayName = userDoc.id;
        final photoUrl = userData['photoUrl'] as String?;

        final String pairId = SocialService().createPairId(
          _currentUid,
          userData['uid'],
        );

        return FutureBuilder<DocumentSnapshot>(
          future: _db.collection('friend_requests').doc(pairId).get(),
          builder: (context, snapshot) {
            final requestData = snapshot.data?.data() as Map<String, dynamic>?;

            final isAlreadyFriend = requestData?['status'] == 'accepted';
            final isRequestSent = requestData?['status'] == 'pending';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? Text(
                          displayName[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                title: Text(displayName),
                trailing: _buildActionButton(
                  userData['uid'],
                  displayName,
                  isAlreadyFriend,
                  isRequestSent,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton(
    String targetUid,
    String targetUsername,
    bool isAlreadyFriend,
    bool isRequestSent,
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

    return ElevatedButton(
      onPressed: () => _sendFriendRequest(targetUid, targetUsername),
      child: const Text('Add Friend'),
    );
  }
}
