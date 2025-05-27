import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class EntryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<void> createEntry({
    required File imageFile,
    required String caption,
  }) async {
    final String docId = _uuid.v4();
    final DocumentReference entryRef = _db.collection('entries').doc(docId);

    // 1. Create Firestore document
    await entryRef.set({
      'caption': caption.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'ownerId': FirebaseAuth.instance.currentUser?.uid ?? 'anon',
      'photoUrl': null,
      'visibility': 'private',
    });

    // 2. Upload image to Storage
    final String storagePath = 'entries/$docId.jpg';
    final UploadTask task = _storage.ref(storagePath).putFile(imageFile);
    final TaskSnapshot snap = await task;
    final String downloadUrl = await snap.ref.getDownloadURL();

    // 3. Update Firestore doc with the image URL
    await entryRef.update({'photoUrl': downloadUrl});
  }
}
