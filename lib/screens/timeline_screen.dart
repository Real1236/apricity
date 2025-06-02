import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'gratitude_snap_screen.dart';

/// TimelineScreen shows a live, reverse‑chronological list of the current
/// user's gratitude entries. A floating‑action button launches the
/// GratitudeSnapScreen so the user can create a new entry without leaving the
/// tab.
class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('My Gratitude Journal')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('entries')
            .where('ownerId', isEqualTo: uid)
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
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final caption = data['caption'] as String? ?? '';
              final photoUrl = data['photoUrl'] as String?;
              final timestamp = (data['createdAt'] as Timestamp?)?.toDate();

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (photoUrl != null)
                      CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        height: 240,
                        placeholder: (c, _) => const AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (c, _, __) =>
                            const Icon(Icons.broken_image, size: 48),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            caption,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (timestamp != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _formatDate(timestamp),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'newEntry',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GratitudeSnapScreen(primaryCamera: cameras.first),
          ),
        ),
        child: const Icon(Icons.photo_camera),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    }
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}
