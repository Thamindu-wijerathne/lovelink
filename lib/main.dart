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
String? activeChatPartner;

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
    final title =
        (message.notification?.title != null &&
                message.notification!.title!.split(" ").length > 3)
            ? message.notification!.title!.split(" ")[3]
            : 'New message';

    final body = message.notification?.body ?? '';
    final profilePicUrl = message.data['image'] ?? '';

    if (navigatorKey.currentState != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final overlay = navigatorKey.currentState!.overlay;
        if (overlay == null || activeChatPartner == message.data['sender'])
          return;

        final context = overlay.context;
        final topPadding = MediaQuery.of(context).padding.top;

        late OverlayEntry overlayEntry;

        overlayEntry = OverlayEntry(
          builder:
              (_) => Positioned(
                top: topPadding + 8,
                left: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    _handleNotificationNavigation(message);
                    overlayEntry.remove(); // remove on tap
                  },
                  child: Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (_) => overlayEntry.remove(),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white, // background white
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // rounded edges
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Profile picture
                            CircleAvatar(
                              radius: 24,
                              backgroundImage:
                                  profilePicUrl.isNotEmpty
                                      ? NetworkImage(profilePicUrl)
                                      : null,
                              child:
                                  profilePicUrl.isEmpty
                                      ? Icon(Icons.person, color: Colors.white)
                                      : null,
                              backgroundColor: Colors.grey,
                            ),
                            SizedBox(width: 12),
                            // Title + Body
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title == 'undefined'
                                        ? "LoveLink AI"
                                        : title,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    body,
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        );

        overlay.insert(overlayEntry);

        // Auto-remove after 5 seconds
        Future.delayed(Duration(seconds: 5), () {
          overlayEntry.remove();
        });
      });
    }
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
