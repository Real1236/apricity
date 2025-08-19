import 'dart:async';

import 'package:apricity/models/relationship_state.dart';
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

  Future<void> acceptFriendRequest(String targetUid) async {
    final String pairId = createPairId(targetUid, _currentUid);
    await _db.collection('friend_requests').doc(pairId).update({
      'status': 'accepted',
    });
  }

  Stream<RelationshipState> watchRelationshipState(String uid) {
    final Stream<Set<String>> friendsStream = _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toSet());

    final Stream<Set<String>> outgoingStream = _db
        .collection('friend_requests')
        .where('from', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.map((d) => (d.data())['to'] as String).toSet());

    final Stream<Set<String>> incomingStream = _db
        .collection('friend_requests')
        .where('to', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.map((d) => (d.data())['from'] as String).toSet());

    late StreamController<RelationshipState> controller;
    Set<String> f = {}, out = {}, incoming = {};
    void emit() => controller.add(
      RelationshipState(
        friends: f,
        outgoingPending: out,
        incomingPending: incoming,
      ),
    );

    controller = StreamController<RelationshipState>();

    late final StreamSubscription subF;
    late final StreamSubscription subO;
    late final StreamSubscription subI;

    controller.onListen = () {
      subF = friendsStream.listen((v) {
        f = v;
        emit();
      });
      subO = outgoingStream.listen((v) {
        out = v;
        emit();
      });
      subI = incomingStream.listen((v) {
        incoming = v;
        emit();
      });
    };
    controller.onCancel = () async {
      await subF.cancel();
      await subO.cancel();
      await subI.cancel();
      await controller.close();
    };

    return controller.stream;
  }
}
