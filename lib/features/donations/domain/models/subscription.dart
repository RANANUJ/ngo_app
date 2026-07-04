import 'package:cloud_firestore/cloud_firestore.dart';

class Subscription {
  final String id;
  final String donorId;
  final String donorName;
  final String donorEmail;
  final String? donorProfileImage;
  final double amount;
  final String category;
  final String ngoId;
  final String ngoName;
  final int deductionDay;
  final String status;
  final DateTime createdAt;
  final DateTime? lastPaymentDate;
  final DateTime? nextPaymentDate;

  Subscription({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.donorEmail,
    this.donorProfileImage,
    required this.amount,
    required this.category,
    required this.ngoId,
    required this.ngoName,
    required this.deductionDay,
    required this.status,
    required this.createdAt,
    this.lastPaymentDate,
    this.nextPaymentDate,
  });

  factory Subscription.fromFirestore(DocumentSnapshot doc, {Map<String, dynamic>? userData}) {
    final data = doc.data() as Map<String, dynamic>;
    return Subscription(
      id: doc.id,
      donorId: data['userId'] ?? '',
      donorName: userData?['name'] ?? data['userName'] ?? 'Anonymous',
      donorEmail: userData?['email'] ?? data['userEmail'] ?? '',
      donorProfileImage: userData?['photoUrl'] ?? userData?['profileImageUrl'],
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? 'general',
      ngoId: data['ngoId'] ?? '',
      ngoName: data['ngoName'] ?? 'Unknown NGO',
      deductionDay: data['deductionDay'] ?? 1,
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastPaymentDate: (data['lastPaymentDate'] as Timestamp?)?.toDate(),
      nextPaymentDate: (data['nextPaymentDate'] as Timestamp?)?.toDate(),
    );
  }
}
