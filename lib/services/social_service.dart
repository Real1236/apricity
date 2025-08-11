import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> sendFriendRequest(
    String targetUid,
    String targetUsername,
  ) async {
    final String pairId = createPairId(targetUid, _currentUid);
    await _db.collection('friend_requests').doc(pairId).set({
      'from': _currentUid,
      'to': targetUid,
      'uLow': pairId.split('~').first,
      'uHigh': pairId.split('~').last,
      'uid': _currentUid,
      'status': 'pending',
    });
  }

  String createPairId(String uid1, String uid2) {
    final uLow = uid1.compareTo(uid2) < 0 ? uid1 : uid2;
    final uHigh = uid1.compareTo(uid2) < 0 ? uid2 : uid1;
    return '$uLow~$uHigh';
  }

  Future<QuerySnapshot> searchUsers(String query) async {
    return await _db
        .collection('profiles')
        .orderBy(FieldPath.documentId)
        .startAt([query.toLowerCase()])
        .endAt(['${query.toLowerCase()}\uf8ff'])
        .limit(10)
        .get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getFriendRequestDoc(
    String pairId,
  ) async {
    return _db.collection('friend_requests').doc(pairId).get();
  }
}
