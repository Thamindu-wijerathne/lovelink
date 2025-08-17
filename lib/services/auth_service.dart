import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign In
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign Up
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
