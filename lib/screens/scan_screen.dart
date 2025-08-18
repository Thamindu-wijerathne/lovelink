import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:io';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool showCamera = true;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String scannedData = '';

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
      appBar: AppBar(title: const Text('Scan / Show QR')),
      body: Column(
        children: [
          Expanded(
            child: showCamera
                ? QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                  )
                : Center(
                    child: QrImageView(
                      data: "https://yourapp.com/userid", // Your unique QR data
                      version: QrVersions.auto,
                      size: 250,
                    ),
                  ),
          ),
          if (showCamera && scannedData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Scanned: $scannedData'),
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
                onPressed: () {
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
      setState(() {
        scannedData = scanData.code ?? '';
        // You can trigger chat creation here
      });
    });
  }
}
