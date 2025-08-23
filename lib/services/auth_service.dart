import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart'; // your UserModel

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign In
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign Up + Save extra info
  Future<User?> signUpWithDetails({
    required String email,
    required String password,
    required UserModel userModel,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
      }
      return user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String?> getUserNameByEmail(String email) async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first['name'];
      }
    } catch (e) {
      throw Exception(e.toString());
    }
    return null;
  }

  // Current user
  User? getCurrentUser() => _auth.currentUser;

  // Sign Out
  Future<void> signOut() async => await _auth.signOut();
}
