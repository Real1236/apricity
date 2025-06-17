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
  }
}
