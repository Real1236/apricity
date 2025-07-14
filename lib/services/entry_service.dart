import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Handles CRUD for entries under users/{uid}/entries
class EntryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<void> createEntry({
    required File imageFile,
    required String caption,
  }) async {
    // 0️⃣ Make sure we have (at least) an anonymous user.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('No Firebase user – call signInAnonymously() first');
    }

    final String docId = _uuid.v4();
    final DocumentReference entryRef = _db
        .collection('users')
        .doc(uid)
        .collection('entries')
        .doc(docId);

    // 1️⃣ Stub Firestore document (no photoUrl yet)
    await entryRef.set({
      'caption': caption.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'photoUrl': null,
      'visibility': 'private',
    });

    // 2️⃣ Upload image into a per-user folder
    final storagePath = 'entries/$uid/$docId.jpg';
    final snap = await _storage.ref(storagePath).putFile(imageFile);
    final downloadUrl = await snap.ref.getDownloadURL();

    // 3️⃣ Back-patch Firestore with the real URL
    await entryRef.update({'photoUrl': downloadUrl});

    // 4️⃣ Update streak counters
    await _updateStreak(uid);
  }

  /// Transaction that recalculates `currentStreak`, `longestStreak`,
  /// and `lastEntryDate` based on _today_ in UTC.
  /// TODO: Fix bug - doesn't break streak if no entry for a day.
  Future<void> _updateStreak(String uid) async {
    final userRef = _db.collection('users').doc(uid);

    await _db.runTransaction((tx) async {
      final now = DateTime.now().toUtc();
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final snap = await tx.get(userRef);
      final data = snap.data() ?? {};

      int current = (data['currentStreak'] ?? 0) as int;
      int longest = (data['longestStreak'] ?? 0) as int;
      final lastDateStr = data['lastEntryDate'] as String?;

      // Determine streak logic.
      if (lastDateStr == todayKey) {
        // Already counted today – nothing to change.
        return;
      }

      if (lastDateStr != null) {
        final parts = lastDateStr.split('-').map(int.parse).toList();
        final lastDate = DateTime.utc(parts[0], parts[1], parts[2]);
        final diff = now.difference(lastDate).inDays;
        if (diff == 1) {
          current += 1; // continued streak
        } else {
          current = 1; // reset
        }
      } else {
        current = 1; // very first entry
      }

      if (current > longest) longest = current;

      tx.set(userRef, {
        'currentStreak': current,
        'longestStreak': longest,
        'lastEntryDate': todayKey,
      }, SetOptions(merge: true));
    });
  }
}
