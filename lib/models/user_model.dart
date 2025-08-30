class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String publicKey;
  final Map<String, dynamic> preferences;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.publicKey,
    required this.preferences,
  });

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'publicKey': publicKey,
      'preferences': preferences,
    };
  }

  // Convert Firestore Map to UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      publicKey: map['publicKey'] ?? '',
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
    );
  }
}
