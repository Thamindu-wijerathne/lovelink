import 'package:flutter/material.dart' hide Key;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lovelink/services/image_service.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import 'dart:async';
import 'dart:io';

import 'dart:ffi';

import 'package:encrypt/encrypt.dart';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Key;

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
  bool sendMessageEnabled = true;
  XFile? _pickedImage;
  bool isUploading = false;

  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  final ImageService _imageService = ImageService();
  int _lastMessageCount = 0;

  int? _extendDays; // NEW: store request days
  String? _requestSender;
  String chatProfilePic = '';

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
    _getUserProfilePic(widget.chatPartnerEmail);

    // mark user's current chat
    _authService.setActiveChat(widget.chatPartnerEmail);
    _chatService.resetUnreadCount(
      userEmail: widget.userEmail,
      chatPartnerEmail: widget.chatPartnerEmail,
    );

    loadExtendRequest(); // NEW

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
          setState(() {
            remaining = Duration.zero;
            if (_extendDays != null && _extendDays! > 0) {
              isExpired = false;
            } else {
              isExpired = true;
            }
            sendMessageEnabled = false;
          });
        } else {
          setState(() => remaining = diff);
          if (sendMessageEnabled == false && remaining.inSeconds > 0) {
            sendMessageEnabled = true;
          }
        }
      });
    }
  }

  // NEW: load extension request
  Future<void> loadExtendRequest() async {
    final request = await _chatService.getExtendRequest(
      senderEmail: widget.userEmail,
      receiverEmail: widget.chatPartnerEmail,
    );
    if (request != null) {
      setState(() {
        _extendDays = request['requestDays'] ?? 0;
        _requestSender = request['requestSender'];
        isExpired =
            false; // in case chat is expired but there's a request to extend
      });
    } else {
      setState(() {
        _extendDays = 0;
        _requestSender = null;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
    _authService.clearActiveChat();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (!sendMessageEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chat is expired. Please extend to continue messaging.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

  void _getUserProfilePic(String email) async {
    String profilePic =
        await _authService.getUserProfilePicByEmail(email) ?? '';
    if (profilePic.isNotEmpty) {
      setState(() {
        chatProfilePic = profilePic;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  // Extend Chat Popup
  void extendChat() {
    int? selectedDays;
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  title: const Text('Extend Chat Session'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Select extension duration:'),
                      const SizedBox(height: 10),
                      RadioListTile<int>(
                        title: const Text('1 Day'),
                        value: 1,
                        groupValue: selectedDays,
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedDays = value;
                          });
                        },
                      ),
                      RadioListTile<int>(
                        title: const Text('3 Days'),
                        value: 3,
                        groupValue: selectedDays,
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedDays = value;
                          });
                        },
                      ),
                      RadioListTile<int>(
                        title: const Text('7 Days'),
                        value: 7,
                        groupValue: selectedDays,
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedDays = value;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (selectedDays != null) {
                          _chatService.sendExtendRequest(
                            senderEmail: widget.userEmail,
                            receiverEmail: widget.chatPartnerEmail,
                            extendDays: selectedDays!,
                          );
                          Navigator.pop(context);
                          loadExtendRequest(); // reload banner
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a duration'),
                            ),
                          );
                        }
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
          ),
    );
  }

  // Accept / Reject
  Future<void> acceptRequest() async {
    await _chatService.acceptExtendRequest(
      senderEmail: widget.userEmail,
      receiverEmail: widget.chatPartnerEmail,
    );
    setState(() {
      _extendDays = null;
    });
    _initializeTimer(); // refresh countdown
  }

  Future<void> rejectRequest() async {
    await _chatService.rejectExtendRequest(
      senderEmail: widget.userEmail,
      receiverEmail: widget.chatPartnerEmail,
    );
    setState(() {
      _extendDays = null;
      _requestSender = null; // clear sender
    });
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

  Future<void> uploadAndSendImage() async {
    try {
      if (_pickedImage != null) {
        setState(() {
          isUploading = true;
        });
        final imageUrl = await _imageService.uploadImage(_pickedImage);
        if (imageUrl != null) {
          _chatService.sendMessage(
            senderEmail: widget.userEmail,
            receiverEmail: widget.chatPartnerEmail,
            text: imageUrl,
            type: 'image',
          );
          setState(() {
            isUploading = false;
            _pickedImage = null;
          });
        }
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  void viewFullImage(String imageUrl, {bool isImage = true}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),

                actions: [
                  isImage
                      ? IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () async {
                          // Implement download functionality
                        },
                      )
                      : SizedBox(),
                ],
              ),
              backgroundColor: Colors.black,
              body: Center(
                child: InteractiveViewer(child: Image.network(imageUrl)),
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        // leading: Icon(Icons.arrow_back),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: GestureDetector(
            onTap: () {
              viewFullImage(chatProfilePic, isImage: false);
            },
            child: Row(
              children: [
                chatProfilePic != ""
                    ? CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(chatProfilePic),
                    )
                    : (Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey,
                      ),
                      height: 40,
                      width: 40,
                      child: Center(
                        child: Text(
                          chatName[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(chatName),
                ),
              ],
            ),
          ),
        ),
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
                extendChat();
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
      body: Column(
        children: [
          if (isExpired)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.timer_off,
                      size: 50,
                      color: Color.fromARGB(255, 97, 97, 97),
                    ),
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
                      onPressed: extendChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text(
                        'Extend Chat',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  if (_extendDays != null &&
                      _extendDays! > 0 &&
                      _requestSender != widget.userEmail)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Request to extend $_extendDays days"),
                          Row(
                            children: [
                              TextButton(
                                onPressed: acceptRequest,
                                child: const Text("Accept"),
                              ),
                              TextButton(
                                onPressed: rejectRequest,
                                child: const Text("Reject"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Container(
                      color: const Color.fromARGB(255, 255, 252, 248),
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

                          final key = Key.fromUtf8(
                            '12345678901234567890123456789012',
                          );
                          final iv = IV.fromUtf8('1234567890123456');
                          final encrypter = Encrypter(AES(key));

                          final messages =
                              snapshot.data!.docs
                                  .map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    String decryptedText;
                                    try {
                                      decryptedText = encrypter.decrypt(
                                        Encrypted(base64Decode(data['text'])),
                                        iv: iv,
                                      );
                                    } catch (e) {
                                      decryptedText = '[Could not decrypt]';
                                    }
                                    return {...data, 'text': decryptedText};
                                  })
                                  .toList()
                                  .reversed
                                  .toList();

                          if (messages.length > _lastMessageCount) {
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => _scrollToBottom(),
                            );
                          }
                          _lastMessageCount = messages.length;

                          return ListView.builder(
                            reverse: true,
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final isMe =
                                  msg['senderEmail'] == widget.userEmail;

                              return Align(
                                alignment:
                                    isMe
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.75,
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isMe
                                              ? Colors.orange[400]
                                              : Colors.grey[400],
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(20),
                                        topRight: const Radius.circular(20),
                                        bottomLeft: Radius.circular(
                                          isMe ? 20 : 0,
                                        ),
                                        bottomRight: Radius.circular(
                                          isMe ? 0 : 20,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 2,
                                          offset: const Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        msg['type'] == 'image'
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: GestureDetector(
                                                onTap: () {
                                                  viewFullImage(msg['text']);
                                                },
                                                child: Image.network(
                                                  msg['text'],
                                                  width: 250,
                                                  height: 250,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            )
                                            : Text(
                                              msg['text'] ?? '',
                                              style: TextStyle(
                                                color:
                                                    isMe
                                                        ? Colors.white
                                                        : Colors.black87,
                                              ),
                                            ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTimestamp(msg['createdAt']),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                isMe
                                                    ? Colors.white70
                                                    : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  // Input Area
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    color: Colors.white,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.image,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          onPressed: () async {
                            final pickedImage = await _imageService.pickImage();

                            if (pickedImage != null) {
                              setState(() {
                                _pickedImage = pickedImage as XFile?;
                              });
                            } else {
                              setState(() {
                                _pickedImage = null;
                              });
                            }
                          },
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: TextField(
                              controller: _controller,
                              minLines: 1,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                hintText: 'Type a message',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                            child: const Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (_pickedImage != null)
            Container(
              height: MediaQuery.of(context).size.height * 0.9,
              color: const Color.fromARGB(255, 255, 255, 255),
              child:
                  isUploading
                      ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          height: 250,
                          width: 250,
                          alignment: Alignment.center,

                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Icon(
                                Icons.upload,
                                color: const Color.fromARGB(255, 0, 0, 0),
                                size: 100,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Sending the Image',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      : Stack(
                        children: [
                          // Image preview
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.0),
                              child: Image.file(
                                File(_pickedImage!.path),
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),

                          // Floating send button (bottom right)
                          Positioned(
                            bottom: 20,
                            right: 20,
                            child: GestureDetector(
                              onTap: () {
                                uploadAndSendImage();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: const Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            top: 20,
                            left: 20,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _pickedImage = null;
                                });
                                // send action
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Color.fromARGB(255, 255, 0, 0),
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
            ),
        ],
      ),
    );
  }
}
