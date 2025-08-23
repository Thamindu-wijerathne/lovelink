import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import 'dart:async';

class ChatDetailScreen extends StatefulWidget {
  final String userEmail;
  final String chatPartnerEmail;

  const ChatDetailScreen({
    super.key,
    required this.userEmail,
    required this.chatPartnerEmail,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  String chatName = 'Loading ...';
  Duration remaining = const Duration(hours: 24);
  Timer? timer;
  DateTime? validTill;
  bool isExpired = false;

  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();

    // Ensure chat doc exists
    _chatService.createChatIfNotExists(
      email1: widget.userEmail,
      email2: widget.chatPartnerEmail,
      validHours: 24,
    );

    // Fetch username
    _getUserName(widget.chatPartnerEmail);

    // Initialize countdown timer
    _initializeTimer();
  }

  Future<void> _initializeTimer() async {
    final doc = await _chatService.getChatDetails(
      widget.userEmail,
      widget.chatPartnerEmail,
    );

    if (doc != null && doc['validTill'] != null) {
      setState(() {
        validTill = doc['validTill'].toDate();
        remaining = validTill!.difference(DateTime.now());
      });

      timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        final diff = validTill!.difference(DateTime.now());
        if (diff.isNegative) {
          t.cancel();
          setState(() => remaining = Duration.zero);
          setState(() {
            isExpired = true;
          });
        } else if (diff.inSeconds <= 10) {
          t.cancel();
          setState(() => remaining = Duration.zero);
          setState(() {
            isExpired = true;
          });
          // Optionally, show a dialog or notification that chat has expired
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Chat Expired'),
                  content: const Text(
                    'This chat session has expired. Do you want to extend it?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                      },
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        // Handle "Yes" action: extend chat session
                        // Add your logic here
                      },
                      child: const Text('Yes'),
                    ),
                  ],
                ),
          );
        } else {
          setState(() => remaining = diff);
        }
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(
      senderEmail: widget.userEmail,
      receiverEmail: widget.chatPartnerEmail,
      text: text,
    );

    _controller.clear();
    _scrollToBottom();
  }

  void _getUserName(String email) async {
    String userName =
        await _authService.getUserNameByEmail(widget.chatPartnerEmail) ?? '';
    if (userName.isNotEmpty) {
      setState(() {
        chatName = userName;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    return DateFormat('hh:mm a').format(date);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(chatName),
        actions: [
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      remaining.inMinutes < 60
                          ? Colors.red
                          : remaining.inMinutes < 180
                          ? Colors.amber
                          : Colors.green,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color:
                        remaining.inMinutes < 60
                            ? Colors.red
                            : remaining.inMinutes < 180
                            ? Colors.amber
                            : Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    remaining.inSeconds <= 10
                        ? 'Chat Expired'
                        : _formatDuration(remaining),
                    style: TextStyle(
                      color:
                          remaining.inMinutes < 60
                              ? Colors.red
                              : remaining.inMinutes < 180
                              ? Colors.amber
                              : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'Extend_Chat') {
                print("Extend Chat ");
              } else if (value == 'Block') {
                print("Block clicked");
              }
            },
            itemBuilder:
                (BuildContext context) => const [
                  PopupMenuItem(
                    value: 'Extend_Chat',
                    child: Text("Extend Chat"),
                  ),
                  PopupMenuItem(value: 'Block', child: Text("Block")),
                ],
          ),
        ],
      ),
      body:
          isExpired
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_off, size: 50, color: Colors.grey),
                    const SizedBox(height: 30),

                    const Text(
                      'This chat session has expired.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Handle "Extend Chat" action
                        print("Extend Chat clicked");
                      },
                      child: const Text('Extend Chat'),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _chatService.getMessages(
                        email1: widget.userEmail,
                        email2: widget.chatPartnerEmail,
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final messages =
                            snapshot.data!.docs
                                .map(
                                  (doc) => doc.data() as Map<String, dynamic>,
                                )
                                .toList()
                                .reversed
                                .toList();

                        // WidgetsBinding.instance.addPostFrameCallback(
                        //   (_) => _scrollToBottom(),
                        // );
                        if (messages.length > _lastMessageCount) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollToBottom();
                          });
                        }
                        _lastMessageCount = messages.length;

                        return ListView.builder(
                          reverse: true,
                          controller: _scrollController,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe = msg['senderEmail'] == widget.userEmail;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          isMe ? Colors.blue : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      msg['text'] ?? '',
                                      style: TextStyle(
                                        color:
                                            isMe ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTimestamp(msg['createdAt']),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        border: const Border(
                          top: BorderSide(color: Colors.grey, width: 1.0),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image),
                            onPressed: () {},
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: TextField(
                                controller: _controller,
                                decoration: const InputDecoration(
                                  hintText: 'Type a message ...',
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                    borderSide: BorderSide(color: Colors.blue),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
