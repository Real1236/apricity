import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> sendFriendRequest(String targetUsername) async {
    final currentUserDoc = await _db.collection('users').doc(_currentUid).get();
    final String currentUsername = currentUserDoc.data()!['displayName'];

    final String uLow = currentUsername.compareTo(targetUsername) < 0
        ? currentUsername
        : targetUsername;
    final String uHigh = currentUsername.compareTo(targetUsername) < 0
        ? targetUsername
        : currentUsername;
    final String pairId = '${uLow}_$uHigh';

    _db.collection('friend_requests').doc(pairId).set({
      'from': currentUsername,
      'to': targetUsername,
      'uLow': uLow,
      'uHigh': uHigh,
      'uid': _currentUid,
      'status': 'pending',
    });
  }
}
