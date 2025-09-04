import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app.dart';
import './utils/chatDetailScreen.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

// API Key for Gemini
const apiKey = "AIzaSyCZkB56BNCwp2otIC-d02lputCkHfpOQo8";

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background handler for FCM
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Background message received: ${message.notification?.title}');
  print('📩 Data: ${message.data}');
}

Future<void> main() async {
  Gemini.init(apiKey: apiKey);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Setup background FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyAppWrapper());

  // After first frame, check if app was opened via notification
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkInitialMessage();
  });

  // Setup foreground listeners
  _setupFCMListeners();
}

/// Wrapper that handles online/offline tracking
class MyAppWrapper extends StatefulWidget {
  const MyAppWrapper({super.key});

  @override
  State<MyAppWrapper> createState() => _MyAppWrapperState();
}

class _MyAppWrapperState extends State<MyAppWrapper>
    with WidgetsBindingObserver {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setUserStatus(true); // online when app starts
  }

  void _setUserStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection("users").doc(user.uid).update({
        "isOnline": isOnline,
        "lastSeen": DateTime.now(),
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setUserStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _setUserStatus(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setUserStatus(false); // mark offline when app closes
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MyApp();
  }
}

// FCM Listeners
void _setupFCMListeners() {
  // Foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('🔥 Foreground message received');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
    // TODO: show local notification with flutter_local_notifications
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
          builder: (_) => ChatDetailScreen(
            userEmail: receiver,
            chatPartnerEmail: sender,
          ),
        ),
      );
    });
  }
}