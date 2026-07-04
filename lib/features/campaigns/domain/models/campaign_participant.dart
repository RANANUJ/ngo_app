import 'package:cloud_firestore/cloud_firestore.dart';

class CampaignParticipant {
  final String id;
  final String campaignId;
  final String userId;
  final DateTime joinedAt;

  CampaignParticipant({
    required this.id,
    required this.campaignId,
    required this.userId,
    required this.joinedAt,
  });

  factory CampaignParticipant.fromMap(String id, Map<String, dynamic> map) {
    return CampaignParticipant(
      id: id,
      campaignId: map['campaignId'] ?? '',
      userId: map['userId'] ?? '',
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'campaignId': campaignId,
      'userId': userId,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}
