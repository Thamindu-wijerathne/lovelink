import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'auth_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final AuthService _authService = AuthService();

  String getChatId(String email1, String email2) {
    final sortedEmails = [email1, email2]..sort();
    return sortedEmails.join('_');
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
        'lastMessageAt': FieldValue.serverTimestamp(),
        'validTill': Timestamp.fromDate(
          DateTime.now().add(Duration(hours: validHours)),
        ),
      });
    }
  }

  /// Sending
  Future<void> sendMessage({
    required String senderEmail,
    required String receiverEmail,
    required String text,
    String type = 'text', // default text
  }) async {
    final chatId = getChatId(senderEmail, receiverEmail);

    final messageData = {
      'senderEmail': senderEmail,
      'text': text,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    await messageRef.add(messageData);

    // Update last message details
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
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
            final participants = List<String>.from(doc['participants']);
            final chatPartner = participants.firstWhere(
              (email) => email != userEmail,
              orElse: () => userEmail,
            );
            final lastMessage = doc['lastMessage'] ?? '';
            final lastMessageTime =
                doc['lastMessageAt'] != null
                    ? (doc['lastMessageAt'] as Timestamp).toDate()
                    : null;

            return {
              'chatId': doc.id,
              'chatPartner': chatPartner,
              'lastMessage': lastMessage,
              'lastMessageTime': lastMessageTime,
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
    required int extendDays
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
      'requestSender': senderEmail
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

    final currentValidTill = docSnapshot['validTill']?.toDate() ?? DateTime.now();

    final newValidTill = currentValidTill.add(Duration(days: requestExtend));

    await chatRef.update({
      'validTill': Timestamp.fromDate(newValidTill),
      'requestExtend' : 0
    });
  }

    Future<void> rejectExtendRequest({
    required String senderEmail,
    required String receiverEmail,
  }) async {
    final chatId = getChatId(senderEmail, receiverEmail);
    final chatRef = _firestore.collection('chats').doc(chatId);

    await chatRef.update({
      'requestExtend' : 0
    });
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
