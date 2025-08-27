import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/message_service.dart';
import '../utils/chatDetailScreen.dart';
import '../services/auth_service.dart';
import 'dart:math';

class ChatScreen extends StatefulWidget {
  ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _messageService = ChatService();
  final AuthService _authService = AuthService();
  final Random random = Random();
  String myMail = "";

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final String currentUserEmail = myMail;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo_trans.png', height: 80),
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Handle search action
            },
          ),
          IconButton(
            icon: RequestIcon(requestCount: 1),

            onPressed: () {
              // Handle more options action
            },
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _messageService.getUserChats(currentUserEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return const Center(child: Text('No chats yet'));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return chatItem(
                context,
                chat['chatPartner'] ?? "Unknown",
                chat['lastMessage'] ?? "",
                _formatTime(chat['lastMessageTime']),
                chat['chatId'],
                currentUserEmail,
              );
            },
          );
        },
      ),
    );
  }

  Widget chatItem(
    BuildContext context,
    String name,
    String message,
    String time,
    String chatId,
    String currentUserEmail,
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
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),

      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              chatAvatarColors[random.nextInt(chatAvatarColors.length)],
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "?",
            style: const TextStyle(color: Colors.white),
          ),
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
          message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: Text(
          time,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
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
        Icon(requestCount > 0 ? Icons.upcoming : Icons.upcoming_rounded),
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
