import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session_model.dart';

class QRSessionService {
  final CollectionReference _sessionsCollection = FirebaseFirestore.instance
      .collection('sessions');

  // Create a session
  Future<void> createSession({
    required String firstUser, // owner of QR
    required String secondUser, // user who scans
  }) async {
    final Timestamp validTill = Timestamp.fromDate(
      DateTime.now().add(const Duration(hours: 24)),
    );

    SessionModel session = SessionModel(
      firstUser: firstUser,
      secondUser: secondUser,
      isAccepted: true,
      validTill: validTill,
    );

    await _sessionsCollection.add(session.toMap());
  }

  Future<List<SessionModel>> getSessionsForUser(String email) async {
    QuerySnapshot snapshot =
        await _sessionsCollection.where('firstuser', isEqualTo: email).get();

    // Also check if the user is secondUser
    QuerySnapshot snapshot2 =
        await _sessionsCollection.where('seconduser', isEqualTo: email).get();

    List<SessionModel> sessions =
        snapshot.docs.map((doc) => SessionModel.fromDocument(doc)).toList();

    sessions.addAll(
      snapshot2.docs.map((doc) => SessionModel.fromDocument(doc)),
    );

    return sessions;
  }
}
