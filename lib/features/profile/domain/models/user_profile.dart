class UserProfile {
  final String id;
  final String name;
  final String type; // 'ngo' or 'volunteer'
  final String? photoUrl;
  final String bio;
  final String city;
  final String state;
  final String phone;
  final String email;
  final String? username;

  UserProfile({
    required this.id,
    required this.name,
    required this.type,
    this.photoUrl,
    required this.bio,
    required this.city,
    required this.state,
    required this.phone,
    required this.email,
    this.username,
  });

  factory UserProfile.fromMap(String id, String type, Map<String, dynamic> map) {
    final bio = map['bio'] as String? ?? map['missionVision'] as String? ?? '';
    final photoUrl = map['photoUrl'] as String? ?? 
                     map['profileImageUrl'] as String? ?? 
                     map['logoUrl'] as String? ?? 
                     map['logo'] as String? ?? '';
    final name = map['name'] as String? ?? map['ngoName'] as String? ?? map['organizationName'] as String? ?? '';
    final email = map['email'] as String? ?? '';
    final phone = map['phone'] as String? ?? map['contactPhone'] as String? ?? map['phoneNumber'] as String? ?? '';
    final username = map['username'] as String? ?? '';
    
    // Parse address mapping if it exists
    String city = map['city'] as String? ?? '';
    String state = map['state'] as String? ?? '';
    if (map['address'] is Map) {
      final addressMap = map['address'] as Map;
      if (city.isEmpty) city = addressMap['city'] as String? ?? '';
      if (state.isEmpty) state = addressMap['state'] as String? ?? '';
    }

    return UserProfile(
      id: id,
      name: name,
      type: type,
      photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
      bio: bio,
      city: city,
      state: state,
      phone: phone,
      email: email,
      username: username.isNotEmpty ? username : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'photoUrl': photoUrl,
      'bio': bio,
      'city': city,
      'state': state,
      'phone': phone,
      'email': email,
      'username': username,
    };
  }
}
