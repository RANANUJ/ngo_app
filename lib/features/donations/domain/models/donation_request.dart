import 'package:cloud_firestore/cloud_firestore.dart';

class DonationRequest {
  final String id;
  final String ngoId;
  final String title;
  final String description;
  final String category;
  final String location;
  final String status;
  final double targetAmount;
  final double collectedAmount;
  final String urgencyLevel;
  final int donorsCount;
  final DateTime createdAt;
  final DateTime? dueDate;
  final List<String> images;

  DonationRequest({
    required this.id,
    required this.ngoId,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.targetAmount,
    required this.collectedAmount,
    required this.urgencyLevel,
    required this.donorsCount,
    required this.createdAt,
    this.dueDate,
    required this.images,
  });

  factory DonationRequest.fromMap(String id, Map<String, dynamic> map) {
    return DonationRequest(
      id: id,
      ngoId: map['ngoId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      location: map['location'] ?? '',
      status: map['status'] ?? 'active',
      targetAmount: (map['targetAmount'] ?? 0).toDouble(),
      collectedAmount: (map['collectedAmount'] ?? 0).toDouble(),
      urgencyLevel: map['urgencyLevel'] ?? 'Normal',
      donorsCount: map['donorsCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      images: List<String>.from(map['images'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ngoId': ngoId,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'status': status,
      'targetAmount': targetAmount,
      'collectedAmount': collectedAmount,
      'urgencyLevel': urgencyLevel,
      'donorsCount': donorsCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'images': images,
    };
  }
}
