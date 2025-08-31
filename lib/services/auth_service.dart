import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lovelink/services/message_service.dart';
import '../models/user_model.dart'; // your UserModel
import 'chat_service.dart';

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
              .where('email', isEqualTo: email.toLowerCase())
              .limit(1)
              .get();
      // print('snapshot: ${snapshot.docs}');

      if (snapshot.docs.isNotEmpty) {
        print(snapshot.docs.first['name']);
        return snapshot.docs.first['name'];
      }
    } catch (e) {
      throw Exception(e.toString());
    }
    return null;
  }

  Future<void> setActiveChat(String chatPartnerEmail) async {
    User? user = _auth.currentUser;
    if (user != null) {
      ChatService _chatService = ChatService();
      String chatId = await _chatService.getChatId(
        chatPartnerEmail,
        user.email!,
      );
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'activeChat': chatId},
      );
    }
  }

  Future<void> clearActiveChat() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'activeChat': null},
      );
    }
  }

  // Current user
  User? getCurrentUser() => _auth.currentUser;

  // Sign Out
  Future<void> signOut() async => await _auth.signOut();

  Future<String?> getUserIdByEmail(String email) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.id; // Firestore doc ID (userId)
      } else {
        return null; // No user found
      }
    } catch (e) {
      print("Error fetching userId: $e");
      return null;
    }
  }

  Future<String?> getUserProfilePicByEmail(String email) async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email.toLowerCase())
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first['profilePicture'];
      }
    } catch (e) {
      throw Exception(e.toString());
    }
    return null;
  }
}
