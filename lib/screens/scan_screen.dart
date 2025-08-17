import 'package:flutter/material.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool showCamera = true; // Initially show camera

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: showCamera
                  ? const Text(
                      'Camera View\n(Replace with camera widget)',
                      textAlign: TextAlign.center,
                    )
                  : const Text(
                      'Your QR Code\n(Replace with QR widget)',
                      textAlign: TextAlign.center,
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
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    showCamera = false;
                  });
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
}
