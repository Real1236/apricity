import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> follow(String targetUid) async {
    String myUid = FirebaseAuth.instance.currentUser!.uid;
    await _db.doc('users/$myUid/following/$targetUid').set({});
    await _db.doc('users/$targetUid/followers/$myUid').set({});
  }

  Future<void> unfollow(String targetUid) async {
    String myUid = FirebaseAuth.instance.currentUser!.uid;
    await _db.doc('users/$myUid/following/$targetUid').delete();
    await _db.doc('users/$targetUid/followers/$myUid').delete();
  }

  Stream<bool> isFollowing(String targetUid) {
    String myUid = FirebaseAuth.instance.currentUser!.uid;
    return _db
        .doc('users/$myUid/following/$targetUid')
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }
}
