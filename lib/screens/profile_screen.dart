import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/db_helper.dart';
import '../services/image_service.dart';

import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ImageService _imageService = ImageService();
  Map<String, dynamic>? userData;
  XFile? _image;

  final List<String> preferencePool = [
    'Sports',
    'Reading',
    'Hiking',
    'Music',
    'Traveling',
    'Cooking',
    'Gaming',
  ];

  List<String> selectedPreferences = [];

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    final user = _authService.getCurrentUser();

    // Fetch user info from Firestore
    Map<String, dynamic>? data;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      data =
          doc.exists
              ? doc.data()
              : {
                'name': 'New User',
                'email': user.email,
                'profilePicture': null,
              };
    }

    // Load preferences from SQLite
    final prefs = await DBHelper.getPreferences();

    setState(() {
      userData = data;
      selectedPreferences = prefs;
    });
  }

  Future<void> savePreferences() async {
    await DBHelper.savePreferences(selectedPreferences);
  }

  void viewProfilePicture(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          XFile? localImage = _image;

          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  iconTheme: const IconThemeData(color: Colors.white),
                  title: const Text(
                    'Profile Picture',
                    style: TextStyle(color: Colors.white),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            localImage = picked;
                          });
                        }
                      },
                    ),
                    localImage != null
                        ? IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () async {
                            final result = await _imageService.uploadImage(
                              localImage!,
                            );
                            if (result != null) {
                              final user = await _authService.getCurrentUser();
                              if (user != null) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .update({'profilePicture': result});
                                setState(() {
                                  userData!['profilePicture'] = result;
                                  _image = null;
                                });
                                Navigator.pop(context);
                              }
                            }
                          },
                        )
                        : Container(),
                  ],
                ),
                backgroundColor: Colors.black,
                body: Center(
                  child: InteractiveViewer(
                    child:
                        localImage != null
                            ? Image.file(
                              File(localImage!.path),
                              width: 400,
                              height: 400,
                              fit: BoxFit.cover,
                            )
                            : Image.network(imageUrl),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void showPreferencesPopup() {
    showDialog(
      context: context,
      builder: (context) {
        List<String> tempSelected = List.from(selectedPreferences);

        return AlertDialog(
          title: const Text('Select your preferences'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setStateDialog) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        preferencePool.map((preference) {
                          final isSelected = tempSelected.contains(preference);
                          return GestureDetector(
                            onTap: () {
                              setStateDialog(() {
                                if (isSelected) {
                                  tempSelected.remove(preference);
                                } else {
                                  tempSelected.add(preference);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.orange
                                        : Colors.grey[200],
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                preference,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedPreferences = tempSelected;
                });
                savePreferences();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 252, 248),
      appBar: AppBar(
        title: Image.asset('assets/images/logo_trans.png', height: 80),
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body:
          userData == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              viewProfilePicture(
                                userData!['profilePicture'] ??
                                    'https://www.w3schools.com/howto/img_avatar.png',
                              );
                              print('Avatar tapped');
                            },
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(
                                userData!['profilePicture'] ??
                                    'https://www.w3schools.com/howto/img_avatar.png',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userData!['name'] ?? 'John Doe',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            userData!['email'] ?? user?.email ?? '',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Preferences:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextButton(
                                onPressed: showPreferencesPopup,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                ),
                                child: const Text('Select'),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children:
                                selectedPreferences
                                    .map(
                                      (pref) => Chip(
                                        backgroundColor: Colors.orange[100],
                                        label: Text(
                                          pref,
                                          style: const TextStyle(
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () async {
                        await _authService.signOut();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // changed text color
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
