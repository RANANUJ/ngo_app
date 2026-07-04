class SosAlert {
  final String id;
  final String odid;
  final String odname;
  final String volunteerPhone;
  final String emergencyType;
  final String description;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String address;
  final String status; // active, responding, resolved
  final DateTime? createdAt;
  final String? respondingNgoId;
  final String? respondingNgoName;
  final String? ngoPhone;
  final DateTime? respondedAt;
  final int? estimatedArrival; // in minutes
  final double? ngoLatitude;
  final double? ngoLongitude;
  final String? ngoAddress;
  final DateTime? resolvedAt;
  final DateTime? volunteerLocationUpdatedAt;

  SosAlert({
    required this.id,
    required this.odid,
    required this.odname,
    required this.volunteerPhone,
    required this.emergencyType,
    required this.description,
    this.imageUrl,
    this.latitude,
    this.longitude,
    required this.address,
    required this.status,
    this.createdAt,
    this.respondingNgoId,
    this.respondingNgoName,
    this.ngoPhone,
    this.respondedAt,
    this.estimatedArrival,
    this.ngoLatitude,
    this.ngoLongitude,
    this.ngoAddress,
    this.resolvedAt,
    this.volunteerLocationUpdatedAt,
  });

  factory SosAlert.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      // Handle Firestore Timestamp or generic objects
      if (value.runtimeType.toString() == 'Timestamp') {
        return (value as dynamic).toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return null;
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return SosAlert(
      id: id,
      odid: map['odid'] ?? '',
      odname: map['odname'] ?? '',
      volunteerPhone: map['volunteerPhone'] ?? '',
      emergencyType: map['emergencyType'] ?? 'Quick SOS',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      address: map['address'] ?? '',
      status: map['status'] ?? 'active',
      createdAt: parseDateTime(map['createdAt']),
      respondingNgoId: map['respondingNgoId'],
      respondingNgoName: map['respondingNgoName'],
      ngoPhone: map['ngoPhone'],
      respondedAt: parseDateTime(map['respondedAt']),
      estimatedArrival: map['estimatedArrival'] as int?,
      ngoLatitude: parseDouble(map['ngoLatitude']),
      ngoLongitude: parseDouble(map['ngoLongitude']),
      ngoAddress: map['ngoAddress'],
      resolvedAt: parseDateTime(map['resolvedAt']),
      volunteerLocationUpdatedAt: parseDateTime(map['volunteerLocationUpdatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'odid': odid,
      'odname': odname,
      'volunteerPhone': volunteerPhone,
      'emergencyType': emergencyType,
      'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'status': status,
      if (createdAt != null) 'createdAt': createdAt,
      'respondingNgoId': respondingNgoId,
      'respondingNgoName': respondingNgoName,
      'ngoPhone': ngoPhone,
      if (respondedAt != null) 'respondedAt': respondedAt,
      'estimatedArrival': estimatedArrival,
      'ngoLatitude': ngoLatitude,
      'ngoLongitude': ngoLongitude,
      'ngoAddress': ngoAddress,
      if (resolvedAt != null) 'resolvedAt': resolvedAt,
      if (volunteerLocationUpdatedAt != null) 'volunteerLocationUpdatedAt': volunteerLocationUpdatedAt,
    };
  }

  SosAlert copyWith({
    String? id,
    String? odid,
    String? odname,
    String? volunteerPhone,
    String? emergencyType,
    String? description,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? address,
    String? status,
    DateTime? createdAt,
    String? respondingNgoId,
    String? respondingNgoName,
    String? ngoPhone,
    DateTime? respondedAt,
    int? estimatedArrival,
    double? ngoLatitude,
    double? ngoLongitude,
    String? ngoAddress,
    DateTime? resolvedAt,
    DateTime? volunteerLocationUpdatedAt,
  }) {
    return SosAlert(
      id: id ?? this.id,
      odid: odid ?? this.odid,
      odname: odname ?? this.odname,
      volunteerPhone: volunteerPhone ?? this.volunteerPhone,
      emergencyType: emergencyType ?? this.emergencyType,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondingNgoId: respondingNgoId ?? this.respondingNgoId,
      respondingNgoName: respondingNgoName ?? this.respondingNgoName,
      ngoPhone: ngoPhone ?? this.ngoPhone,
      respondedAt: respondedAt ?? this.respondedAt,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      ngoLatitude: ngoLatitude ?? this.ngoLatitude,
      ngoLongitude: ngoLongitude ?? this.ngoLongitude,
      ngoAddress: ngoAddress ?? this.ngoAddress,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      volunteerLocationUpdatedAt: volunteerLocationUpdatedAt ?? this.volunteerLocationUpdatedAt,
    );
  }
}
