import 'package:cloud_firestore/cloud_firestore.dart';

class Donation {
  final String id;
  final String paymentId;
  final String orderId;
  final String signature;
  final double amount;
  final String status;
  final String paymentMethod;
  final String donorName;
  final String donorEmail;
  final String donorPhone;
  final String? donorId;
  final String? profileImageUrl;
  final bool isAnonymous;
  final String campaignId;
  final String campaignTitle;
  final String campaignType;
  final String? ngoId;
  final String? message;
  final DateTime createdAt;
  final bool thankYouSent;
  final DateTime? thankYouSentAt;
  final String category;

  Donation({
    required this.id,
    required this.paymentId,
    required this.orderId,
    required this.signature,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.donorName,
    required this.donorEmail,
    required this.donorPhone,
    this.donorId,
    this.profileImageUrl,
    required this.isAnonymous,
    required this.campaignId,
    required this.campaignTitle,
    required this.campaignType,
    this.ngoId,
    this.message,
    required this.createdAt,
    this.thankYouSent = false,
    this.thankYouSentAt,
    this.category = 'general',
  });

  factory Donation.fromMap(String id, Map<String, dynamic> map) {
    return Donation(
      id: id,
      paymentId: map['paymentId'] ?? map['razorpayPaymentId'] ?? '',
      orderId: map['orderId'] ?? '',
      signature: map['signature'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? 'unknown',
      donorName: map['donorName'] ?? map['userName'] ?? 'Anonymous',
      donorEmail: map['donorEmail'] ?? map['userEmail'] ?? '',
      donorPhone: map['donorPhone'] ?? '',
      donorId: map['donorId'] ?? map['userId'],
      profileImageUrl: map['profileImageUrl'] ?? map['profileImage'],
      isAnonymous: map['isAnonymous'] ?? false,
      campaignId: map['campaignId'] ?? '',
      campaignTitle: map['campaignTitle'] ?? '',
      campaignType: map['campaignType'] ?? 'general',
      ngoId: map['ngoId'],
      message: map['message'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      thankYouSent: map['thankYouSent'] ?? false,
      thankYouSentAt: (map['thankYouSentAt'] as Timestamp?)?.toDate(),
      category: map['category'] ?? 'general',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'orderId': orderId,
      'signature': signature,
      'amount': amount,
      'status': status,
      'paymentMethod': paymentMethod,
      'donorName': donorName,
      'donorEmail': donorEmail,
      'donorPhone': donorPhone,
      'donorId': donorId,
      'profileImageUrl': profileImageUrl,
      'isAnonymous': isAnonymous,
      'campaignId': campaignId,
      'campaignTitle': campaignTitle,
      'campaignType': campaignType,
      'ngoId': ngoId,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'thankYouSent': thankYouSent,
      'thankYouSentAt': thankYouSentAt != null ? Timestamp.fromDate(thankYouSentAt!) : null,
      'category': category,
    };
  }
}
