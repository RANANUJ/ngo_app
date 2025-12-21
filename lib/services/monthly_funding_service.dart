import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model class for Monthly Funding data
class MonthlyFundingData {
  final String id;
  final String donorId;
  final String donorName;
  final String donorEmail;
  final String? donorProfileImage;
  final double amount;
  final String paymentId;
  final String? subscriptionId;
  final String category;
  final String ngoId;
  final String ngoName;
  final DateTime donationDate;
  final String status;
  final bool thankYouSent;
  final DateTime? thankYouSentAt;

  MonthlyFundingData({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.donorEmail,
    this.donorProfileImage,
    required this.amount,
    required this.paymentId,
    this.subscriptionId,
    required this.category,
    required this.ngoId,
    required this.ngoName,
    required this.donationDate,
    required this.status,
    this.thankYouSent = false,
    this.thankYouSentAt,
  });

  factory MonthlyFundingData.fromFirestore(DocumentSnapshot doc, {Map<String, dynamic>? userData}) {
    final data = doc.data() as Map<String, dynamic>;
    return MonthlyFundingData(
      id: doc.id,
      donorId: data['userId'] ?? '',
      donorName: userData?['name'] ?? data['userName'] ?? 'Anonymous',
      donorEmail: userData?['email'] ?? data['userEmail'] ?? '',
      donorProfileImage: userData?['photoUrl'] ?? userData?['profileImageUrl'],
      amount: (data['amount'] ?? 0).toDouble(),
      paymentId: data['razorpayPaymentId'] ?? '',
      subscriptionId: data['subscriptionId'],
      category: data['category'] ?? 'general',
      ngoId: data['ngoId'] ?? '',
      ngoName: data['ngoName'] ?? 'Unknown NGO',
      donationDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      thankYouSent: data['thankYouSent'] ?? false,
      thankYouSentAt: (data['thankYouSentAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Model class for Subscription data
class SubscriptionData {
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

  SubscriptionData({
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

  factory SubscriptionData.fromFirestore(DocumentSnapshot doc, {Map<String, dynamic>? userData}) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionData(
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

/// Monthly funding statistics
class MonthlyFundingStats {
  final double totalAmount;
  final int totalDonors;
  final int totalTransactions;
  final double averageDonation;
  final int activeSubscriptions;
  final int thankYouPending;
  final Map<String, double> categoryWiseAmount;

  MonthlyFundingStats({
    required this.totalAmount,
    required this.totalDonors,
    required this.totalTransactions,
    required this.averageDonation,
    required this.activeSubscriptions,
    required this.thankYouPending,
    required this.categoryWiseAmount,
  });

  factory MonthlyFundingStats.empty() {
    return MonthlyFundingStats(
      totalAmount: 0,
      totalDonors: 0,
      totalTransactions: 0,
      averageDonation: 0,
      activeSubscriptions: 0,
      thankYouPending: 0,
      categoryWiseAmount: {},
    );
  }
}

/// Donor summary for leaderboard
class DonorSummary {
  final String donorId;
  final String donorName;
  final String donorEmail;
  final String? donorProfileImage;
  final double totalAmount;
  final int donationCount;
  final DateTime firstDonation;
  final DateTime lastDonation;
  final bool isTopDonor;

  DonorSummary({
    required this.donorId,
    required this.donorName,
    required this.donorEmail,
    this.donorProfileImage,
    required this.totalAmount,
    required this.donationCount,
    required this.firstDonation,
    required this.lastDonation,
    this.isTopDonor = false,
  });
}

/// Service class for managing monthly funding data
class MonthlyFundingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user data from volunteers collection
  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('volunteers').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  /// Get real-time stream of monthly donations for an NGO
  Stream<List<MonthlyFundingData>> getDonationsStream({
    required String ngoId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    // Remove orderBy to avoid composite index requirement
    Query query = _firestore
        .collection('monthly_donations')
        .where('ngoId', isEqualTo: ngoId);

    return query.snapshots().asyncMap((snapshot) async {
      List<MonthlyFundingData> donations = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] as String?;
        Map<String, dynamic>? userData;
        if (userId != null) {
          userData = await _getUserData(userId);
        }
        final donation = MonthlyFundingData.fromFirestore(doc, userData: userData);
        
        // Filter by date if needed
        if (startDate != null && donation.donationDate.isBefore(startDate)) continue;
        if (endDate != null && donation.donationDate.isAfter(endDate)) continue;
        
        donations.add(donation);
      }
      
      // Sort locally by donation date descending
      donations.sort((a, b) => b.donationDate.compareTo(a.donationDate));
      
      // Apply limit if specified
      if (limit != null && donations.length > limit) {
        donations = donations.take(limit).toList();
      }
      
      return donations;
    });
  }

  /// Get active subscriptions for an NGO
  Stream<List<SubscriptionData>> getSubscriptionsStream({
    required String ngoId,
    String? status,
  }) {
    // Remove orderBy to avoid composite index requirement
    Query query = _firestore
        .collection('monthly_subscriptions')
        .where('ngoId', isEqualTo: ngoId);

    return query.snapshots().asyncMap((snapshot) async {
      List<SubscriptionData> subscriptions = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] as String?;
        Map<String, dynamic>? userData;
        if (userId != null) {
          userData = await _getUserData(userId);
        }
        final sub = SubscriptionData.fromFirestore(doc, userData: userData);
        
        // Filter by status if needed
        if (status != null && sub.status != status) continue;
        
        subscriptions.add(sub);
      }
      
      // Sort locally by createdAt descending
      subscriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return subscriptions;
    });
  }

  /// Get monthly funding statistics
  Future<MonthlyFundingStats> getMonthlyStats({
    required String ngoId,
    required int month,
    required int year,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      // Get monthly donations
      final donationsSnapshot = await _firestore
          .collection('monthly_donations')
          .where('ngoId', isEqualTo: ngoId)
          .where('status', isEqualTo: 'completed')
          .get();

      // Filter by date manually
      final donations = donationsSnapshot.docs.where((doc) {
        final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
        if (createdAt == null) return false;
        return createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
               createdAt.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      // Get active subscriptions count
      final subsSnapshot = await _firestore
          .collection('monthly_subscriptions')
          .where('ngoId', isEqualTo: ngoId)
          .where('status', isEqualTo: 'active')
          .get();

      if (donations.isEmpty) {
        return MonthlyFundingStats(
          totalAmount: 0,
          totalDonors: 0,
          totalTransactions: 0,
          averageDonation: 0,
          activeSubscriptions: subsSnapshot.docs.length,
          thankYouPending: 0,
          categoryWiseAmount: {},
        );
      }

      // Calculate statistics
      double totalAmount = 0;
      final Set<String> uniqueDonors = {};
      final Map<String, double> categoryWiseAmount = {};
      int thankYouPending = 0;

      for (final doc in donations) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        final userId = data['userId'] ?? '';
        final category = data['category'] ?? 'general';
        final thankYouSent = data['thankYouSent'] ?? false;

        totalAmount += amount;
        if (userId.isNotEmpty) uniqueDonors.add(userId);
        categoryWiseAmount[category] = (categoryWiseAmount[category] ?? 0) + amount;
        if (!thankYouSent) thankYouPending++;
      }

      return MonthlyFundingStats(
        totalAmount: totalAmount,
        totalDonors: uniqueDonors.length,
        totalTransactions: donations.length,
        averageDonation: donations.isNotEmpty ? totalAmount / donations.length : 0,
        activeSubscriptions: subsSnapshot.docs.length,
        thankYouPending: thankYouPending,
        categoryWiseAmount: categoryWiseAmount,
      );
    } catch (e) {
      debugPrint('Error getting monthly stats: $e');
      return MonthlyFundingStats.empty();
    }
  }

  /// Get top donors for the NGO
  Future<List<DonorSummary>> getTopDonors({
    required String ngoId,
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('monthly_donations')
          .where('ngoId', isEqualTo: ngoId)
          .where('status', isEqualTo: 'completed')
          .get();

      // Group by donor
      final Map<String, List<QueryDocumentSnapshot>> donorDonations = {};
      for (final doc in snapshot.docs) {
        final userId = doc.data()['userId'] as String?;
        if (userId != null && userId.isNotEmpty) {
          donorDonations.putIfAbsent(userId, () => []);
          donorDonations[userId]!.add(doc);
        }
      }

      // Create donor summaries
      final List<DonorSummary> summaries = [];
      for (final entry in donorDonations.entries) {
        final donations = entry.value;
        final userData = await _getUserData(entry.key);
        
        double totalAmount = 0;
        DateTime? firstDate;
        DateTime? lastDate;
        
        for (final doc in donations) {
          final data = doc.data() as Map<String, dynamic>;
          totalAmount += (data['amount'] ?? 0).toDouble();
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          if (createdAt != null) {
            if (firstDate == null || createdAt.isBefore(firstDate)) firstDate = createdAt;
            if (lastDate == null || createdAt.isAfter(lastDate)) lastDate = createdAt;
          }
        }

        summaries.add(DonorSummary(
          donorId: entry.key,
          donorName: userData?['name'] ?? 'Anonymous',
          donorEmail: userData?['email'] ?? '',
          donorProfileImage: userData?['photoUrl'] ?? userData?['profileImageUrl'],
          totalAmount: totalAmount,
          donationCount: donations.length,
          firstDonation: firstDate ?? DateTime.now(),
          lastDonation: lastDate ?? DateTime.now(),
        ));
      }

      // Sort by total amount
      summaries.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

      // Mark top 3 as top donors
      for (int i = 0; i < summaries.length && i < 3; i++) {
        final s = summaries[i];
        summaries[i] = DonorSummary(
          donorId: s.donorId,
          donorName: s.donorName,
          donorEmail: s.donorEmail,
          donorProfileImage: s.donorProfileImage,
          totalAmount: s.totalAmount,
          donationCount: s.donationCount,
          firstDonation: s.firstDonation,
          lastDonation: s.lastDonation,
          isTopDonor: true,
        );
      }

      return summaries.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting top donors: $e');
      return [];
    }
  }

  /// Get yearly funding trend
  Future<Map<String, double>> getYearlyTrend({
    required String ngoId,
    required int year,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('monthly_donations')
          .where('ngoId', isEqualTo: ngoId)
          .where('status', isEqualTo: 'completed')
          .get();

      final Map<String, double> monthlyData = {
        'Jan': 0, 'Feb': 0, 'Mar': 0, 'Apr': 0, 'May': 0, 'Jun': 0,
        'Jul': 0, 'Aug': 0, 'Sep': 0, 'Oct': 0, 'Nov': 0, 'Dec': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null && createdAt.year == year) {
          final monthName = _getMonthName(createdAt.month);
          monthlyData[monthName] = (monthlyData[monthName] ?? 0) + (data['amount'] ?? 0).toDouble();
        }
      }

      return monthlyData;
    } catch (e) {
      debugPrint('Error getting yearly trend: $e');
      return {};
    }
  }

  /// Get all donations for an NGO (non-stream version for easier use)
  Future<List<MonthlyFundingData>> getAllDonations({required String ngoId}) async {
    try {
      // Remove orderBy to avoid composite index requirement
      final snapshot = await _firestore
          .collection('monthly_donations')
          .where('ngoId', isEqualTo: ngoId)
          .get();

      List<MonthlyFundingData> donations = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        Map<String, dynamic>? userData;
        if (userId != null) {
          userData = await _getUserData(userId);
        }
        donations.add(MonthlyFundingData.fromFirestore(doc, userData: userData));
      }
      
      // Sort locally by donation date descending
      donations.sort((a, b) => b.donationDate.compareTo(a.donationDate));
      
      return donations;
    } catch (e) {
      debugPrint('Error getting all donations: $e');
      return [];
    }
  }

  /// Get all subscriptions for an NGO (non-stream version)
  Future<List<SubscriptionData>> getAllSubscriptions({required String ngoId}) async {
    try {
      // Remove orderBy to avoid composite index requirement
      final snapshot = await _firestore
          .collection('monthly_subscriptions')
          .where('ngoId', isEqualTo: ngoId)
          .get();

      List<SubscriptionData> subscriptions = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        Map<String, dynamic>? userData;
        if (userId != null) {
          userData = await _getUserData(userId);
        }
        subscriptions.add(SubscriptionData.fromFirestore(doc, userData: userData));
      }
      
      // Sort locally by createdAt descending
      subscriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return subscriptions;
    } catch (e) {
      debugPrint('Error getting all subscriptions: $e');
      return [];
    }
  }

  /// Mark thank you as sent
  Future<bool> markThankYouSent(String donationId) async {
    try {
      await _firestore.collection('monthly_donations').doc(donationId).update({
        'thankYouSent': true,
        'thankYouSentAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error marking thank you sent: $e');
      return false;
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
