import 'package:cloud_firestore/cloud_firestore.dart';

class Campaign {
  final String id;
  final String ngoId;
  final String ngoName;
  final String title;
  final String description;
  final String category;
  final String status;
  final bool isActive;
  final double targetAmount;
  final double raisedAmount;
  final int participantsCount;
  final List<String> images;
  final String location;
  final double? latitude;
  final double? longitude;
  final DateTime? eventDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> purpose;
  final List<String> target;
  final DateTime? createdAt;

  Campaign({
    required this.id,
    required this.ngoId,
    required this.ngoName,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.isActive,
    required this.targetAmount,
    required this.raisedAmount,
    required this.participantsCount,
    required this.images,
    required this.location,
    this.latitude,
    this.longitude,
    this.eventDate,
    this.startDate,
    this.endDate,
    required this.purpose,
    required this.target,
    this.createdAt,
  });

  factory Campaign.fromMap(String id, Map<String, dynamic> map) {
    // Handle 'participants' being stored as a String (e.g. '0') or int/num
    int parsedParticipants = 0;
    if (map['participants'] != null) {
      if (map['participants'] is num) {
        parsedParticipants = (map['participants'] as num).toInt();
      } else {
        parsedParticipants = int.tryParse(map['participants'].toString()) ?? 0;
      }
    } else if (map['participantsCount'] != null) {
      if (map['participantsCount'] is num) {
        parsedParticipants = (map['participantsCount'] as num).toInt();
      } else {
        parsedParticipants = int.tryParse(map['participantsCount'].toString()) ?? 0;
      }
    }

    return Campaign(
      id: id,
      ngoId: map['ngoId'] ?? '',
      ngoName: map['ngoName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      status: map['status'] ?? 'active',
      isActive: map['isActive'] ?? (map['status'] == 'active'),
      targetAmount: (map['targetAmount'] ?? 0).toDouble(),
      raisedAmount: (map['raisedAmount'] ?? 0).toDouble(),
      participantsCount: parsedParticipants,
      images: List<String>.from(map['images'] ?? []),
      location: map['location'] ?? '',
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      eventDate: (map['eventDate'] as Timestamp?)?.toDate(),
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      purpose: List<String>.from(map['purpose'] ?? []),
      target: List<String>.from(map['target'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ngoId': ngoId,
      'ngoName': ngoName,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'isActive': isActive,
      'targetAmount': targetAmount,
      'raisedAmount': raisedAmount,
      'participants': participantsCount, // stored as int, can query easily
      'images': images,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'purpose': purpose,
      'target': target,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
