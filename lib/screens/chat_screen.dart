import 'package:flutter/material.dart' hide Key;
import '../services/message_service.dart';
import '../utils/chatDetailScreen.dart';
import '../services/auth_service.dart';
import 'dart:math';
import 'package:encrypt/encrypt.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _messageService = ChatService();
  final AuthService _authService = AuthService();
  final Random random = Random();
  final key = Key.fromUtf8('12345678901234567890123456789012');
  final iv = IV.fromUtf8('1234567890123456');
  late final Encrypter encrypter;

  String myMail = "";
  String profilePic = "";
  var userData = {};
  @override
  void initState() {
    super.initState();
    encrypter = Encrypter(AES(key));
    _loadUserData();
  }

  void _loadUserData() async {
    final user = await _authService.getCurrentUser();
    setState(() {
      myMail = user?.email ?? "";
    });
  }

  Future<String> _loadUserNameData(String email) async {
    final user = await _authService.getUserNameByEmail(email);
    return user ?? email;
  }

  Future<String> _loadUserProfilePic(String email) async {
    final user = await _authService.getUserProfilePicByEmail(email);
    return user ?? "";
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserEmail = myMail;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 252, 248),
      appBar: AppBar(
        title: Image.asset('assets/images/logo_trans.png', height: 80),
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),

      body: 
      Stack(
        children: [
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: _messageService.getUserChats(currentUserEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final chats = snapshot.data ?? [];
          print(chats);

          if (chats.isEmpty) {
            return const Center(child: Text('No chats yet'));
          }

          return ListView.builder(
            itemCount: chats.length,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final unreadName = _messageService.sanitizeEmailForKey(
                currentUserEmail,
              );
              // print('Unread Name: $unreadName');
              // print(chat['unreadCount']);
              return chatItem(
                context,
                chat['chatPartner'] ?? "Unknown",
                chat['lastMessage'] ?? "",
                _formatTime(chat['lastMessageTime']),
                chat['chatId'],
                currentUserEmail,
                chat['unreadCount'] != null &&
                        chat['unreadCount'][unreadName] != null
                    ? chat['unreadCount'][unreadName]
                    : 0,
                chat['lastMessageBy'] ?? "",
              );
            },
          );
        },
      ),

        // --- AI Chatbot Button ---
        Positioned(
          bottom: 16,
          right: 16,
          child: GestureDetector(
            onTap: () {
              // Open your AI chatbot screen or modal
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(
                    userEmail: currentUserEmail, 
                    chatPartnerEmail: 'LoveLink AI')
                )
              );
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/ai_bot.png', // your AI bot icon
                  width: 35,
                  height: 35,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  String decrypter(String message) {
    String decryptedText;
    try {
      decryptedText = encrypter.decrypt(
        Encrypted(base64Decode(message)),
        iv: iv,
      );
    } catch (e) {
      decryptedText = '[Could not decrypt]';
    }
    return decryptedText;
  }

  Widget chatItem(
    BuildContext context,
    String name,
    String message,
    String time,
    String chatId,
    String currentUserEmail,
    int unreadCount,
    String lastMessageBy,
  ) {
    final List<Color> chatAvatarColors = [
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.redAccent,
      Colors.tealAccent,
      Colors.amberAccent,
      Colors.pinkAccent,
      Colors.indigoAccent,
      Colors.cyanAccent,
    ];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: FutureBuilder<String>(
          future: _loadUserProfilePic(name),
          builder: (context, snapshot) {
            String? imageUrl = snapshot.data;
            return CircleAvatar(
              radius: 25,
              backgroundImage:
                  (imageUrl != null && imageUrl.isNotEmpty)
                      ? NetworkImage(imageUrl)
                      : null,
              backgroundColor:
                  chatAvatarColors[random.nextInt(chatAvatarColors.length)],
              child:
                  (imageUrl == null || imageUrl.isEmpty || imageUrl == "")
                      ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "?",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            );
          },
        ),
        title: FutureBuilder<String>(
          future: _loadUserNameData(name),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                'Loading...',
                style: TextStyle(fontWeight: FontWeight.bold),
              );
            }
            return Text(
              snapshot.data ?? name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            );
          },
        ),

        subtitle: Text(
          message.isEmpty
              ? "No messages yet"
              : (lastMessageBy == currentUserEmail
                  ? "You: ${decrypter(message).startsWith('https://res.cloudinary.com/') ? 'Image' : decrypter(message)}"
                  : decrypter(message).startsWith('https://res.cloudinary.com/')
                  ? 'Image'
                  : decrypter(message)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.black54,
            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Column(
          children: [
            Text(
              time,
              style: TextStyle(
                color: unreadCount > 0 ? Colors.orange : Colors.grey,
                fontSize: 12,
              ),
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(top: 6),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              const SizedBox(height: 16), // Placeholder for alignment
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ChatDetailScreen(
                    userEmail: currentUserEmail,
                    chatPartnerEmail: name,
                  ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return "";
    final now = DateTime.now();
    if (now.difference(dateTime).inDays == 0) {
      return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else if (now.difference(dateTime).inDays == 1) {
      return "Yesterday";
    } else {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }
  }
}

class RequestIcon extends StatelessWidget {
  final int requestCount;

  const RequestIcon({super.key, required this.requestCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.upcoming),
        if (requestCount > 0)
          Positioned(
            right: -4,
            top: -5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                requestCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
