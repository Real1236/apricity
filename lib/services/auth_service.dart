import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) return null;

      final doc = await _db.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        await _db.collection('users').doc(user.uid).set({
          'currentStreak': 0,
          'longestStreak': 0,
          'lastEntryDate': null,
          'displayName': null,
          'photoUrl': user.photoURL,
          'profileComplete': false,
        });
      }

      return user;
    } catch (e) {
      print("Error signing in with Google: $e");
      return null;
    }
  }

  Future<bool> completeProfile(String displayName) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    try {
      // Use batch to ensure both operations succeed or fail together
      final batch = _db.batch();

      batch.update(_db.collection('users').doc(user.uid), {
        'displayName': displayName,
        'profileComplete': true,
      });

      batch.set(_db.collection('profiles').doc(displayName.toLowerCase()), {
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrl': user.photoURL,
      });

      await batch.commit();
      return true;
    } catch (e) {
      print("Error completing profile: $e");
      return false;
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final doc = await _db
          .collection('profiles')
          .doc(username.toLowerCase())
          .get();
      return !doc.exists;
    } catch (e) {
      print("Error checking username: $e");
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  User? get currentUser => _firebaseAuth.currentUser;
}
