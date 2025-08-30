import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../utils/chatDetailScreen.dart';
import '../services/message_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  bool showCamera = true;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? userEmail;
  String? name;
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
      name = user?.displayName ?? 'User';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 252, 248),
      appBar: AppBar(
        title: Image.asset('assets/images/logo_trans.png', height: 80),
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              if (name != null)
                Column(
                  children: [
                    const Text(
                      'Scan a QR code or show your QR to start chatting',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              // QR or Camera Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),

                elevation: 6,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  height: 400,
                  child:
                      showCamera
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),

                            child: QRView(
                              key: qrKey,
                              onQRViewCreated: _onQRViewCreated,
                            ),
                          )
                          : userEmail == null
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Scan Me to Start Chatting!',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 20),
                              QrImageView(
                                data: userEmail!,
                                version: QrVersions.auto,
                                size: 300,
                                dataModuleStyle: QrDataModuleStyle(
                                  color: const Color.fromARGB(255, 74, 74, 74),
                                  dataModuleShape: QrDataModuleShape.circle,
                                ),
                                eyeStyle: QrEyeStyle(
                                  color: const Color.fromARGB(255, 74, 74, 74),
                                  eyeShape: QrEyeShape.circle,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => startChat(),
                                icon: const Icon(Icons.chat),
                                label: const Text('Start Chat'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF914D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  fixedSize: const Size(180, 45),
                                ),
                              ),
                            ],
                          ),
                ),
              ),
              const SizedBox(height: 20),
              // Camera / QR toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => showCamera = true);
                      controller?.resumeCamera();
                    },
                    icon: Icon(
                      Icons.camera_alt,
                      color:
                          showCamera
                              ? Color.fromARGB(255, 255, 255, 255)
                              : Color.fromARGB(255, 88, 88, 88),
                    ),
                    label: Text(
                      'Camera',
                      style: TextStyle(
                        color:
                            showCamera
                                ? Color.fromARGB(255, 255, 255, 255)
                                : Color.fromARGB(255, 88, 88, 88),
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          showCamera
                              ? const Color.fromARGB(255, 255, 155, 93)
                              : const Color.fromARGB(255, 255, 255, 255),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        userEmail == null
                            ? null
                            : () {
                              setState(() => showCamera = false);
                              controller?.pauseCamera();
                            },
                    icon: Icon(
                      Icons.qr_code,
                      color:
                          !showCamera
                              ? const Color.fromARGB(255, 255, 255, 255)
                              : const Color.fromARGB(255, 88, 88, 88),
                    ),
                    label: Text(
                      'Show QR',
                      style: TextStyle(
                        color:
                            !showCamera
                                ? const Color.fromARGB(255, 255, 255, 255)
                                : const Color.fromARGB(255, 88, 88, 88),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          !showCamera
                              ? const Color.fromARGB(255, 255, 155, 93)
                              : const Color.fromARGB(255, 255, 255, 255),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      final scannedText = scanData.code ?? '';
      if (scannedText.isNotEmpty) {
        controller.pauseCamera();
        if (mounted) _showStartChatDialog(scannedText);
        setState(() => scannedData = scannedText);
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
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startChat(scannedEmail);
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
  }

  void startChat() {
    String qrcodeEmail = 'prvnmadushan@gmail.com';
    _showStartChatDialog(qrcodeEmail);
  }
}
