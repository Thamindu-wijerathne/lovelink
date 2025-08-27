import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/db_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? userData;

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
          doc.exists ? doc.data() : {'name': 'New User', 'email': user.email};
    }

    // Load preferences from SQLite
    final prefs = await DBHelper.getPreferences();

    setState(() {
      userData = data;
      selectedPreferences = prefs;
    });
  }

  // Save preferences to SQLite
  Future<void> savePreferences() async {
    await DBHelper.savePreferences(selectedPreferences);
  }

  // Show popup for preference selection
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
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected ? Colors.blue : Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                preference,
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedPreferences = tempSelected;
                });
                savePreferences();
                Navigator.pop(context);
              },
              child: const Text('Save'),
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
      appBar: AppBar(
        title: Image.asset('assets/images/logo_trans.png', height: 80),
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
      ),
      body:
          userData == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        'https://www.w3schools.com/howto/img_avatar.png',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userData!['name'] ?? 'John Doe',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(userData!['email'] ?? user?.email ?? ''),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Preferences:'),
                        TextButton(
                          onPressed: showPreferencesPopup,
                          child: const Text('Select'),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children:
                          selectedPreferences
                              .map((pref) => Chip(label: Text(pref)))
                              .toList(),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () async {
                        await _authService.signOut();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ),
    );
  }
}
