import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserStatusService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  void setUserStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection("users").doc(user.uid).update({
        "isOnline": isOnline,
        "lastSeen": DateTime.now(),
      });
    }
  }
}
