import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String firstUser; // owner of the QR
  final bool isAccepted;
  final String? secondUser; // scanner email, null if not scanned yet
  final Timestamp validTill;

  SessionModel({
    required this.firstUser,
    this.secondUser,
    required this.isAccepted,
    required this.validTill,
  });

  // Convert to Map to store in Firestore
  Map<String, dynamic> toMap() {
    return {
      'firstuser': firstUser,
      'isAccepted': isAccepted,
      'seconduser': secondUser,
      'validtill': validTill,
    };
  }

  // Create from Firestore DocumentSnapshot
  factory SessionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel(
      firstUser: data['firstuser'],
      isAccepted: data['isAccepted'],
      secondUser: data['seconduser'],
      validTill: data['validtill'],
    );
  }
}
