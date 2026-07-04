import 'package:cloud_firestore/cloud_firestore.dart';

class OpportunityApplication {
  final String id;
  final String opportunityId;
  final String ngoId;
  final String ngoName;
  final String volunteerId;
  final String volunteerName;
  final String? volunteerEmail;
  final String? volunteerPhotoUrl;
  final String status;
  final DateTime appliedAt;

  OpportunityApplication({
    required this.id,
    required this.opportunityId,
    required this.ngoId,
    required this.ngoName,
    required this.volunteerId,
    required this.volunteerName,
    this.volunteerEmail,
    this.volunteerPhotoUrl,
    required this.status,
    required this.appliedAt,
  });

  factory OpportunityApplication.fromMap(String id, Map<String, dynamic> map) {
    return OpportunityApplication(
      id: id,
      opportunityId: map['opportunityId'] ?? '',
      ngoId: map['ngoId'] ?? '',
      ngoName: map['ngoName'] ?? '',
      volunteerId: map['volunteerId'] ?? '',
      volunteerName: map['volunteerName'] ?? '',
      volunteerEmail: map['volunteerEmail'],
      volunteerPhotoUrl: map['volunteerPhotoUrl'] ?? map['volunteerPhoto'],
      status: map['status'] ?? 'pending',
      appliedAt: (map['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'opportunityId': opportunityId,
      'ngoId': ngoId,
      'ngoName': ngoName,
      'volunteerId': volunteerId,
      'volunteerName': volunteerName,
      'volunteerEmail': volunteerEmail,
      'volunteerPhotoUrl': volunteerPhotoUrl,
      'status': status,
      'appliedAt': Timestamp.fromDate(appliedAt),
    };
  }
}
