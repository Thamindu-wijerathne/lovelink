import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:io';
import '../services/auth_service.dart';
// import '../services/qr_service.dart';
import '../utils/chatDetailScreen.dart';
import '../services/message_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final AuthService _authService = AuthService();
  // final QRSessionService _qrSessionService = QRSessionService();
  final ChatService _chatService = ChatService();
  bool showCamera = true;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? userEmail;
  String? Name;
  String scannedData = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = await _authService.getCurrentUser();
    setState(() {
      userEmail = user?.email;
      Name = user?.displayName;
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // for testing purposes ;
  void startChat() async {
    String qrcodeEmail = 'prvnmadushan@gmail.com';
    _showStartChatDialog(qrcodeEmail);
    // print('Simulating chat start with scanned email');
    // List<Map<String, dynamic>> data = await ChatService().getUserChatsOnce(
    //   'prvnmadushan@gmail.com',
    // );
    // print(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan / Show QR')),
      body: Column(
        children: [
          Expanded(
            child:
                showCamera
                    ? QRView(key: qrKey, onQRViewCreated: _onQRViewCreated)
                    : Center(
                      child:
                          userEmail == null
                              ? const CircularProgressIndicator()
                              : Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 40.0),
                                    child: Text(
                                      'Scan the following QR code to start a chat with me',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(5.0),
                                    margin: const EdgeInsets.only(top: 100.0),
                                    child: QrImageView(
                                      data: userEmail!,
                                      version: QrVersions.auto,
                                      size: 250,
                                      dataModuleStyle: QrDataModuleStyle(
                                        color: const Color.fromARGB(
                                          255,
                                          0,
                                          1,
                                          75,
                                        ),
                                        dataModuleShape:
                                            QrDataModuleShape.circle,
                                      ),
                                      eyeStyle: QrEyeStyle(
                                        color: const Color.fromARGB(
                                          255,
                                          0,
                                          1,
                                          75,
                                        ),
                                        eyeShape: QrEyeShape.circle,
                                      ), // QR dots color
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      startChat();
                                    },
                                    child: const Text(
                                      'Simulate QR Scan and Start Chat',
                                    ),
                                  ), //this button will simulate a qr scan
                                ],
                              ),
                    ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    showCamera = true;
                  });
                  controller?.resumeCamera();
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
              ElevatedButton.icon(
                onPressed:
                    userEmail == null
                        ? null
                        : () {
                          setState(() {
                            showCamera = false;
                          });
                          controller?.pauseCamera();
                        },
                icon: const Icon(Icons.qr_code),
                label: const Text('Show QR'),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) {
      final scannedText = scanData.code ?? '';

      if (scannedText.isNotEmpty) {
        controller.pauseCamera(); // stop scanning for now

        // Show alert dialog
        if (mounted) {
          _showStartChatDialog(scannedText); // show confirmation
        }

        setState(() {
          scannedData = scannedText;
        });
      }
    });
  }

  void _showStartChatDialog(String scannedEmail) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Start Chat?'),
            content: Text('Do you want to start a chat with $scannedEmail?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                },
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  _startChat(scannedEmail); // call your function
                },
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }

  Future<void> _startChat(String email) async {
    await _chatService.createChatIfNotExists(email1: userEmail!, email2: email);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatDetailScreen(
              userEmail: userEmail!,
              chatPartnerEmail: email,
            ),
      ),
    );

    // showDialog(
    //   context: context,
    //   builder:
    //       (context) => AlertDialog(
    //         title: const Text('Start Chat'),
    //         content: Text('Starting chat with $email and ${userEmail!}'),
    //         actions: [
    //           TextButton(
    //             onPressed: () {
    //               Navigator.pop(context); // close dialog
    //             },
    //             child: const Text('OK'),
    //           ),
    //         ],
    //       ),
    // );
  }
}
