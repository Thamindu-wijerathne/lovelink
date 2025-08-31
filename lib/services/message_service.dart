import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Key;


class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String getChatId(String email1, String email2) {
    final sortedEmails = [email1, email2]..sort();
    return sortedEmails.join('_');
  }

  String sanitizeEmailForKey(String email) {
    return email.replaceAll('.', '_');
  }

  Uint8List generateSecureRandomBytes(int length) {
    final secureRandom = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = secureRandom.nextInt(256);
    }
    return bytes;
  }


  //creating a conn
  Future<void> createChatIfNotExists({
    required String email1,
    required String email2,
    int validHours = 24, // chat expires after 24 hours
  }) async {
    final chatId = getChatId(email1, email2);
    final docRef = _firestore.collection('chats').doc(chatId);

    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'participants': [email1, email2],
        'lastMessage': '',
        'chatKey': '12345678901234567890123456789012', // securely store the key
        'lastMessageAt': FieldValue.serverTimestamp(),
        'validTill': Timestamp.fromDate(
          DateTime.now().add(Duration(hours: validHours)),
        ),
      });
    }
  }

  Future<void> sendMessage({
    required String senderEmail,
    required String receiverEmail,
    required String text,
    String type = 'text', // default text
  }) async {
    final chatId = getChatId(senderEmail, receiverEmail);
      final chatRef = _firestore.collection('chats').doc(chatId);
      Encrypted? encrypted;

    try {
      final key = Key.fromUtf8('12345678901234567890123456789012');
      final iv = IV.fromUtf8('1234567890123456');
      final encrypter = Encrypter(AES(key));
      encrypted = encrypter.encrypt(text, iv: iv);
    } catch(e) {
        print("Send msg error : $e");
        debugPrint("Send msg error : $e");

    }

      debugPrint("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
      debugPrint("Text : $text   encrypted : ${encrypted?.base64}");
      debugPrint("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");    

      // --- Save message ---
      final messageData = {
        'senderEmail': senderEmail,
        'text': encrypted?.base64,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await chatRef.collection('messages').add(messageData);

      // Update last message
      await chatRef.update({
        'lastMessage': encrypted?.base64,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageBy': senderEmail,
      });

    // --- Unread count handling ---
    final receiverId = await _authService.getUserIdByEmail(receiverEmail);

    if (receiverId != null) {
      final receiverDocRef = _firestore.collection('users').doc(receiverId);
      final receiverSnapshot = await receiverDocRef.get();

      if (receiverSnapshot.exists) {
        final receiverData = receiverSnapshot.data()!;
        final activeChat = receiverData['activeChat'] as String?;

        // Check if receiver is in this chat
        if (activeChat != chatId) {
          // Not active → increment unread count
          final receiverKey = sanitizeEmailForKey(receiverEmail);

          // Get current unread count
          final chatSnapshot = await chatRef.get();
          int currentUnread = 0;
          if (chatSnapshot.exists && chatSnapshot.data() != null) {
            final data = chatSnapshot.data()!;
            currentUnread = (data['unreadCount']?[receiverKey] ?? 0) as int;
          }
          await chatRef.update({'unreadCount.$receiverKey': currentUnread + 1});
        }
      }
    }
  }

  /// Streaming Received Messages
  Stream<QuerySnapshot> getMessages({
    required String email1,
    required String email2,
  }) {
    final chatId = getChatId(email1, email2);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getMessagesWithDebug({
  required String email1,
  required String email2,
}) {
  final chatId = getChatId(email1, email2);
  final chatRef = _firestore.collection('chats').doc(chatId);
  final key = Key.fromUtf8('12345678901234567890123456789012');
  final iv = IV.fromUtf8('1234567890123456');

  // Get chat key
  chatRef.get().then((chatSnapshot) {
    final encrypter = Encrypter(AES(key));

    // Listen to the messages stream for debug printing
    _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snapshot) {
        print('------------------------------- Full Decrypted Chat -----------------------------------');
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final encryptedText = data['text'] as String;
              try {

          final decryptedText =
              encrypter.decrypt(Encrypted(base64Decode(encryptedText)), iv: iv);
            print('${data['senderEmail']}: $decryptedText');
              } catch (e) {
                print(' encryptedText : $encryptedText');
                print(' encryptedText base64decode: ${base64Decode(encryptedText)}');

                print('${data['senderEmail']}: [Could not decrypt message]');
              }
        }
        print('---------------------------');

    });
  });

  // Return original stream unchanged
  return _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt', descending: false)
      .snapshots();
}




  /// Optional: delete chat (if expired)
  Future<void> deleteChat(String email1, String email2) async {
    final chatId = getChatId(email1, email2);
    await _firestore.collection('chats').doc(chatId).delete();
  }

  /// Get chats for a specific user
  Stream<List<Map<String, dynamic>>> getUserChats(String userEmail) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userEmail)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final participants = List<String>.from(data['participants']);
            final chatPartner = participants.firstWhere(
              (email) => email != userEmail,
              orElse: () => userEmail,
            );

            final lastMessage = data['lastMessage'] ?? '';
            final lastMessageBy = data['lastMessageBy'] ?? '';
            final lastMessageTime =
                data['lastMessageAt'] != null
                    ? (data['lastMessageAt'] as Timestamp).toDate()
                    : null;

            // Safely get unreadCount
            final unreadCount =
                data.containsKey('unreadCount') && data['unreadCount'] != null
                    ? Map<String, dynamic>.from(data['unreadCount'])
                    : <String, dynamic>{};

            return {
              'chatId': doc.id,
              'chatPartner': chatPartner,
              'lastMessage': lastMessage,
              'lastMessageBy': lastMessageBy,
              'lastMessageTime': lastMessageTime,
              'unreadCount': unreadCount,
            };
          }).toList();
        });
  }

  //get chat details
  Future<Map<String, dynamic>?> getChatDetails(
    String email1,
    String email2,
  ) async {
    final chatId = getChatId(email1, email2);
    final doc = await _firestore.collection('chats').doc(chatId).get();

    return doc.data();
  }

  // Asking Extend Request
  Future<void> sendExtendRequest({
    required String senderEmail,
    required String receiverEmail,
    required int extendDays,
  }) async {
    final chatId = getChatId(senderEmail, receiverEmail);
    final chatRef = _firestore.collection('chats').doc(chatId);

    final docSnapshot = await chatRef.get();
    if (!docSnapshot.exists) {
      print("Chat does not exits !");
      return;
    }

    await chatRef.update({
      'requestExtend': extendDays,
      'requestSender': senderEmail,
    });
  }

  Future<Map<String, dynamic>?> getExtendRequest({
    required String senderEmail,
    required String receiverEmail,
  }) async {
    final chatId = getChatId(senderEmail, receiverEmail);
    final chatRef = _firestore.collection('chats').doc(chatId);

    final docSnapshot = await chatRef.get();

    if (!docSnapshot.exists) {
      print("Chat does not exist!");
      return null;
    }

    final data = docSnapshot.data();
    return {
      "requestDays": data?['requestExtend'] as int?,
      "requestSender": data?['requestSender'] as String?,
    };
  }

  Future<void> resetUnreadCount({
    required String userEmail,
    required String chatPartnerEmail,
  }) async {
    final chatId = getChatId(userEmail, chatPartnerEmail);
    final sanitizedEmail = sanitizeEmailForKey(userEmail);

    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount.$sanitizedEmail': 0,
    });
  }

  Future<void> acceptExtendRequest({
    required String senderEmail,
    required String receiverEmail,
  }) async {
    final chatId = getChatId(senderEmail, receiverEmail);
    final chatRef = _firestore.collection('chats').doc(chatId);

    final docSnapshot = await chatRef.get();

    if (!docSnapshot.exists) {
      print("Chat does not exist!");
      return null;
    }

    final requestExtend = docSnapshot["requestExtend"] as int;

    final currentValidTill =
        docSnapshot['validTill']?.toDate() ?? DateTime.now();

    final newValidTill = currentValidTill.add(Duration(days: requestExtend));

    await chatRef.update({
      'validTill': Timestamp.fromDate(newValidTill),
      'requestExtend': 0,
    });
  }

  Future<void> rejectExtendRequest({
    required String senderEmail,
    required String receiverEmail,
  }) async {
    final chatId = getChatId(senderEmail, receiverEmail);
    final chatRef = _firestore.collection('chats').doc(chatId);

    await chatRef.update({'requestExtend': 0});
  }
}






    // final currentValidTill = docSnapshot['validTill']?.toDate() ?? DateTime.now();

    // final newValidTill = currentValidTill.add(Duration(days: extendDays));
    
    // await chatRef.update({
    //   'validTill': Timestamp.fromDate(newValidTill),
    //   'lastExtendedBy' : senderEmail,
    //   'lastExtendedAt' : FieldValue.serverTimestamp(),
    // });
    //   print("Chat extended by $extendDays days. New expiry: $newValidTill");
