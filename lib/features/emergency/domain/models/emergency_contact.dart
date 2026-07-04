class EmergencyContact {
  final String name;
  final String phone;

  EmergencyContact({
    required this.name,
    required this.phone,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}
