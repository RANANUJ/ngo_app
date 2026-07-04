import 'package:cloud_firestore/cloud_firestore.dart';

class Opportunity {
  final String id;
  final String ngoId;
  final String ngoName;
  final String title;
  final String description;
  final String cause;
  final String location;
  final double? latitude;
  final double? longitude;
  final String time;
  final DateTime? eventDate;
  final int volunteersNeeded;
  final List<String> images;
  final List<String> purpose;
  final List<String> target;
  final String contactPhone;
  final String contactEmail;
  final int applicationsCount;
  final DateTime? createdAt;
  final String status;

  Opportunity({
    required this.id,
    required this.ngoId,
    required this.ngoName,
    required this.title,
    required this.description,
    required this.cause,
    required this.location,
    this.latitude,
    this.longitude,
    required this.time,
    this.eventDate,
    required this.volunteersNeeded,
    required this.images,
    required this.purpose,
    required this.target,
    required this.contactPhone,
    required this.contactEmail,
    required this.applicationsCount,
    this.createdAt,
    required this.status,
  });

  factory Opportunity.fromMap(String id, Map<String, dynamic> map) {
    return Opportunity(
      id: id,
      ngoId: map['ngoId'] ?? '',
      ngoName: map['ngoName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      cause: map['cause'] ?? '',
      location: map['location'] ?? '',
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      time: map['time'] ?? '',
      eventDate: (map['eventDate'] as Timestamp?)?.toDate(),
      volunteersNeeded: (map['volunteersNeeded'] ?? 0) is num
          ? (map['volunteersNeeded'] as num).toInt()
          : int.tryParse(map['volunteersNeeded'].toString()) ?? 0,
      images: List<String>.from(map['images'] ?? []),
      purpose: List<String>.from(map['purpose'] ?? []),
      target: List<String>.from(map['target'] ?? []),
      contactPhone: map['contactPhone'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      applicationsCount: (map['applicationsCount'] ?? 0) is num
          ? (map['applicationsCount'] as num).toInt()
          : int.tryParse(map['applicationsCount'].toString()) ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ngoId': ngoId,
      'ngoName': ngoName,
      'title': title,
      'description': description,
      'cause': cause,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'time': time,
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      'volunteersNeeded': volunteersNeeded,
      'images': images,
      'purpose': purpose,
      'target': target,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'applicationsCount': applicationsCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'status': status,
    };
  }
}
