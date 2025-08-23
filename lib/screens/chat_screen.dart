import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/message_service.dart';
import '../utils/chatDetailScreen.dart';

class ChatScreen extends StatelessWidget {
  ChatScreen({super.key});

  final ChatService _messageService = ChatService();

  @override
  Widget build(BuildContext context) {
    final String currentUserEmail = "prvnmadushan@gmail.com";
    // ✅ Replace with FirebaseAuth.instance.currentUser!.email

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),

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
                currentUserEmail, // ✅ pass down
              );
            },
          );
        },
      ),
    );
  }

  /// ✅ Chat list item widget
  Widget chatItem(
    BuildContext context,
    String name,
    String message,
    String time,
    String chatId,
    String currentUserEmail, // ✅ added
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blueAccent,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : "?",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  chatPartnerEmail: name, // ✅ pass correct partner email
                ),
          ),
        );
      },
    );
  }

  /// ✅ Helper: format time
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
