import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lovelink/services/message_service.dart';
import '../models/user_model.dart'; // your UserModel
import 'chat_service.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert'; // for base64 encoding
import 'dart:typed_data';
import '../services/private_key_helper.dart';



class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign In
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Check if private key already exists locally
        // final existingPrivateKey = await PrivateKeyHelper.getPrivateKey(user.uid);

        // if (existingPrivateKey == null) {
          // --- Generate new key pair using X25519 ---
          final algorithm = X25519();
          final keyPair = await algorithm.newKeyPair();
          final publicKey = await keyPair.extractPublicKey();
          final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

          // Convert public key to Base64 to save in Firestore
          String publicKeyBase64 = base64Encode(publicKey.bytes);

          // Save public key in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'publicKey': publicKeyBase64});

          // Save private key locally in SQLite
          await PrivateKeyHelper.savePrivateKey(
              user.uid, Uint8List.fromList(privateKeyBytes));
        // }
      }

      return user;
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
        // --- Generate key pair using X25519 (public/private) ---
        final algorithm = X25519();
        final keyPair = await algorithm.newKeyPair();
        final publicKey = await keyPair.extractPublicKey();
        // Suppose privateKeyBytes is List<int>
        List<int> privateKeyBytes = await keyPair.extractPrivateKeyBytes();
        // Convert to Uint8List
        Uint8List privateKeyData = Uint8List.fromList(privateKeyBytes);


        // Convert keys to Base64 for storing in Firestore
        String publicKeyBase64 = base64Encode(publicKey.bytes);
        String privateKeyBase64 = base64Encode(privateKeyData);

        // Create UserModel including public key
        UserModel newUser = UserModel(
          uid: user.uid,
          name: userModel.name,
          email: userModel.email,
          phone: userModel.phone,
          address: userModel.address,
          publicKey: publicKeyBase64,
          preferences: userModel.preferences,
        );

        // Save private key locally
        // here pass privateKeyData instead of Base64 version is passing
        // that Base64 make it damage.  so past bytethen change their
        await PrivateKeyHelper.savePrivateKey(user.uid, privateKeyData);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(newUser.toMap());
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
}
