import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app.dart';
import './utils/chatDetailScreen.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background handler for FCM
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Background message received: ${message.notification?.title}');
  print('📩 Data: ${message.data}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkInitialMessage();
  });

  _setupFCMListeners();
}

// Foreground & notification tap listeners
void _setupFCMListeners() {
  // Foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('🔥 Foreground message received');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
    // Optional: show local notification here using flutter_local_notifications
  });

  // Notification tapped
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationNavigation(message);
  });
}

// Terminated state notification
Future<void> _checkInitialMessage() async {
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    _handleNotificationNavigation(initialMessage);
  }
}

// Navigate to ChatDetailScreen
void _handleNotificationNavigation(RemoteMessage message) {
  final data = message.data;
  final sender = data['sender'];
  final receiver = data['receiver'];

  if (sender != null && receiver != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder:
              (_) => ChatDetailScreen(
                userEmail: receiver,
                chatPartnerEmail: sender,
              ),
        ),
      );
    });
  }
}
