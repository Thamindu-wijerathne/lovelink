import 'package:flutter/material.dart';

// Show list of Chats
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: ListView(
        children: [
          chatItem(context, 'Alice', 'Hey, how are you?', '10:30 AM'),
          chatItem(context, 'Bob', 'See you soon!', '9:45 AM'),
          chatItem(context, 'Charlie', 'Thanks for that!', 'Yesterday'),
        ],
      ),
    );
  }

  Widget chatItem(BuildContext context, String name, String message, String time) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(name[0]), // Initial as avatar
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(message),
      trailing: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      onTap: () {
        // Open individual chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(chatName: name),
          ),
        );
      },
    );
  }
}

// Open chat 
class ChatDetailScreen extends StatefulWidget {
  final String chatName;
  const ChatDetailScreen({super.key, required this.chatName});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> messages = []; // just for UI demo

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chatName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return Container(
                  alignment: index % 2 == 0 ? Alignment.centerRight : Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      messages[index],
                      style: TextStyle(color: index % 2 == 0 ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.trim().isEmpty) return;
                    setState(() {
                      messages.add(_controller.text.trim());
                      _controller.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
