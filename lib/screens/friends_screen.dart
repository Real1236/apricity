import 'package:apricity/services/social_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final SocialService _socialService = SocialService();
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  List<DocumentSnapshot> friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final friendsList = await _socialService.getFriends(_currentUid);
      setState(() {
        friends = friendsList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading friends: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          final friendUid = friend.id;
          final data = friend.data() as Map<String, dynamic>;
          final friendDisplayName = data['displayName'] as String;
          final friendPhotoUrl = data['photoUrl'] as String?;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: friendPhotoUrl != null
                    ? NetworkImage(friendPhotoUrl)
                    : null,
                child: friendPhotoUrl == null
                    ? Text(
                        friendDisplayName[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              title: Text(friendDisplayName),
            ),
          );
        },
      ),
    );
  }
}
