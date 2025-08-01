import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// ---------------------------------------------
/// TimelineScreen
/// ---------------------------------------------
/// Live, reverse‑chronological feed of the current user’s
/// gratitude entries. Uses a StreamBuilder so the list updates
/// instantly when you pop back from the snap screen or when
/// offline writes sync.
class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('entries')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No entries yet — tap the camera button to add today\'s gratitude!',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return EntryCard(
                caption: data['caption'] as String? ?? '',
                photoUrl: data['photoUrl'] as String?,
                createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
              );
            },
          );
        },
      ),
    );
  }
}

/// ---------------------------------------------
/// EntryCard (pure UI, no Firestore)
/// ---------------------------------------------
class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.caption,
    required this.photoUrl,
    required this.createdAt,
  });

  final String caption;
  final String? photoUrl;
  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (photoUrl != null)
            CachedNetworkImage(
              imageUrl: photoUrl!,
              fit: BoxFit.cover,
              height: 240,
              placeholder: (c, _) => const AspectRatio(
                aspectRatio: 4 / 3,
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (c, _, _) =>
                  const Icon(Icons.broken_image, size: 48),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(caption, style: Theme.of(context).textTheme.bodyLarge),
                if (createdAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatDate(createdAt!),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Local helper (kept inside the card to avoid polluting global scope)
  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    }
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}
