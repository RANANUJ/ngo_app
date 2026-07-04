import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/donation.dart';
import '../../domain/models/donation_request.dart';
import '../../domain/models/subscription.dart';
import '../../domain/models/donation_stats.dart';
import '../../domain/repositories/donation_repository.dart';

class FirebaseDonationRepository implements DonationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Helper to load user profile data
  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('volunteers').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Donation>> getVolunteerDonations(String userId) async {
    final List<Donation> allDonations = [];

    // 1. Regular donations
    try {
      final snapshot = await _firestore
          .collection('donations')
          .where('donorId', isEqualTo: userId)
          .get();
      for (var doc in snapshot.docs) {
        allDonations.add(Donation.fromMap(doc.id, doc.data()));
      }
    } catch (e) {
      // Ignored or logged
    }

    // 2. Emergency donations records
    try {
      final snapshot = await _firestore
          .collection('emergency_donations_records')
          .where('donorId', isEqualTo: userId)
          .get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = data['emergencyTitle'] ?? data['campaignTitle'] ?? 'Emergency Donation';
        allDonations.add(Donation.fromMap(doc.id, {
          ...data,
          'campaignTitle': title,
          'campaignType': 'emergency',
        }));
      }
    } catch (e) {
      // Ignored
    }

    // 3. Impact donations
    try {
      final snapshot = await _firestore
          .collection('impact_donations')
          .where('donorId', isEqualTo: userId)
          .get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = data['impactTitle'] ?? data['campaignTitle'] ?? 'Impact Support';
        allDonations.add(Donation.fromMap(doc.id, {
          ...data,
          'campaignTitle': title,
          'campaignType': 'impact',
        }));
      }
    } catch (e) {
      // Ignored
    }

    // Sort by createdAt descending
    allDonations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allDonations;
  }

  @override
  Future<String> saveDonation(Donation donation) async {
    final donationData = donation.toMap();
    
    // Save to main donations collection
    final donationRef = await _firestore.collection('donations').add(donationData);

    // Also save to NGO-specific donations subcollection if NGO ID exists
    final ngoId = donation.ngoId;
    if (ngoId != null && ngoId.isNotEmpty) {
      await _firestore
          .collection('ngos')
          .doc(ngoId)
          .collection('received_donations')
          .doc(donationRef.id)
          .set(donationData);
    }

    // Update campaign raised amount
    final campaignId = donation.campaignId;
    final campaignType = donation.campaignType;
    final amount = donation.amount;

    final collectionName = _getCollectionName(campaignType);
    final campaignRef = _firestore.collection(collectionName).doc(campaignId);
    
    final campaignDoc = await campaignRef.get();
    if (campaignDoc.exists) {
      final data = campaignDoc.data();
      String amountField;
      switch (campaignType) {
        case 'donation_request':
          amountField = 'collectedAmount';
          break;
        case 'emergency':
          amountField = 'collectedAmount';
          break;
        case 'impact':
          amountField = 'donationsReceived';
          break;
        case 'campaign':
        default:
          amountField = 'raisedAmount';
          break;
      }
      
      final currentRaised = (data?[amountField] ?? 0).toDouble();
      final donorCount = (data?['donorCount'] ?? data?['donorsCount'] ?? 0) as int;
      
      await campaignRef.update({
        amountField: currentRaised + amount,
        'donorCount': donorCount + 1,
        'lastDonationAt': FieldValue.serverTimestamp(),
      });
    }

    return donationRef.id;
  }

  String _getCollectionName(String campaignType) {
    switch (campaignType) {
      case 'emergency':
        return 'emergency_donations';
      case 'impact':
        return 'impacts';
      case 'donation_request':
        return 'donation_posts';
      case 'campaign':
      default:
        return 'campaigns';
    }
  }

  @override
  Future<List<Donation>> getNgoReceivedDonations(String ngoId) async {
    final snapshot = await _firestore
        .collection('ngos')
        .doc(ngoId)
        .collection('received_donations')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Donation.fromMap(doc.id, doc.data())).toList();
  }

  @override
  Stream<List<Donation>> streamNgoReceivedDonations(String ngoId) {
    return _firestore
        .collection('ngos')
        .doc(ngoId)
        .collection('received_donations')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => Donation.fromMap(doc.id, doc.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  @override
  Future<List<Donation>> getMonthlyDonations({
    required String ngoId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final snapshot = await _firestore
        .collection('monthly_donations')
        .where('ngoId', isEqualTo: ngoId)
        .get();

    List<Donation> donations = [];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final userId = data['userId'] as String?;
      Map<String, dynamic>? userData;
      if (userId != null) {
        userData = await _getUserData(userId);
      }

      final mappedData = {
        ...data,
        'donorName': userData?['name'] ?? data['userName'] ?? 'Anonymous',
        'donorEmail': userData?['email'] ?? data['userEmail'] ?? '',
        'profileImageUrl': userData?['photoUrl'] ?? userData?['profileImageUrl'],
        'paymentId': data['razorpayPaymentId'] ?? '',
        'campaignType': 'monthly',
      };

      final donation = Donation.fromMap(doc.id, mappedData);

      if (startDate != null && donation.createdAt.isBefore(startDate)) continue;
      if (endDate != null && donation.createdAt.isAfter(endDate)) continue;

      donations.add(donation);
    }

    donations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (limit != null && donations.length > limit) {
      donations = donations.take(limit).toList();
    }

    return donations;
  }

  @override
  Stream<List<Donation>> streamMonthlyDonations({
    required String ngoId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    return _firestore
        .collection('monthly_donations')
        .where('ngoId', isEqualTo: ngoId)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Donation> donations = [];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final userId = data['userId'] as String?;
            Map<String, dynamic>? userData;
            if (userId != null) {
              userData = await _getUserData(userId);
            }

            final mappedData = {
              ...data,
              'donorName': userData?['name'] ?? data['userName'] ?? 'Anonymous',
              'donorEmail': userData?['email'] ?? data['userEmail'] ?? '',
              'profileImageUrl': userData?['photoUrl'] ?? userData?['profileImageUrl'],
              'paymentId': data['razorpayPaymentId'] ?? '',
              'campaignType': 'monthly',
            };

            final donation = Donation.fromMap(doc.id, mappedData);

            if (startDate != null && donation.createdAt.isBefore(startDate)) continue;
            if (endDate != null && donation.createdAt.isAfter(endDate)) continue;

            donations.add(donation);
          }

          donations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (limit != null && donations.length > limit) {
            donations = donations.take(limit).toList();
          }

          return donations;
        });
  }

  @override
  Future<List<Subscription>> getAllSubscriptions({required String ngoId}) async {
    final snapshot = await _firestore
        .collection('monthly_subscriptions')
        .where('ngoId', isEqualTo: ngoId)
        .get();

    List<Subscription> subscriptions = [];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final userId = data['userId'] as String?;
      Map<String, dynamic>? userData;
      if (userId != null) {
        userData = await _getUserData(userId);
      }
      subscriptions.add(Subscription.fromFirestore(doc, userData: userData));
    }

    subscriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return subscriptions;
  }

  @override
  Stream<List<Subscription>> getSubscriptionsStream({
    required String ngoId,
    String? status,
  }) {
    return _firestore
        .collection('monthly_subscriptions')
        .where('ngoId', isEqualTo: ngoId)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Subscription> subscriptions = [];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final userId = data['userId'] as String?;
            Map<String, dynamic>? userData;
            if (userId != null) {
              userData = await _getUserData(userId);
            }
            final sub = Subscription.fromFirestore(doc, userData: userData);

            if (status != null && sub.status != status) continue;

            subscriptions.add(sub);
          }

          subscriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return subscriptions;
        });
  }

  @override
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
        averageDonation: totalAmount / donations.length,
        activeSubscriptions: subsSnapshot.docs.length,
        thankYouPending: thankYouPending,
        categoryWiseAmount: categoryWiseAmount,
      );
    } catch (e) {
      return MonthlyFundingStats.empty();
    }
  }

  @override
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

      final Map<String, List<QueryDocumentSnapshot>> donorDonations = {};
      for (final doc in snapshot.docs) {
        final userId = doc.data()['userId'] as String?;
        if (userId != null && userId.isNotEmpty) {
          donorDonations.putIfAbsent(userId, () => []);
          donorDonations[userId]!.add(doc);
        }
      }

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

      summaries.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

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
      return [];
    }
  }

  @override
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
      return {};
    }
  }

  @override
  Future<bool> markThankYouSent(String donationId) async {
    try {
      await _firestore.collection('monthly_donations').doc(donationId).update({
        'thankYouSent': true,
        'thankYouSentAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<List<DonationRequest>> streamDonationRequests(String ngoId) {
    return _firestore
        .collection('donation_posts')
        .where('ngoId', isEqualTo: ngoId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => DonationRequest.fromMap(doc.id, doc.data())).toList();
        });
  }

  @override
  Stream<List<DonationRequest>> streamActiveDonationRequests() {
    return _firestore
        .collection('donation_posts')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => DonationRequest.fromMap(doc.id, doc.data())).toList();
        });
  }

  @override
  Future<void> markRequestComplete(String requestId) async {
    await _firestore.collection('donation_posts').doc(requestId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> streamBlockchainDonations(String ngoId) {
    return _firestore
        .collection('blockchain_donations')
        .where('ngoId', isEqualTo: ngoId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  @override
  Future<List<Donation>> getNgoCombinedDonations(String ngoId) async {
    final List<Donation> allDonations = [];

    // 1. Regular donations
    try {
      final snapshot = await _firestore
          .collection('donations')
          .where('ngoId', isEqualTo: ngoId)
          .get();
      for (var doc in snapshot.docs) {
        allDonations.add(Donation.fromMap(doc.id, doc.data()));
      }
    } catch (e) {
      // Ignored or logged
    }

    // 2. Emergency donations records
    try {
      final snapshot = await _firestore
          .collection('emergency_donations_records')
          .where('ngoId', isEqualTo: ngoId)
          .get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = data['emergencyTitle'] ?? data['campaignTitle'] ?? 'Emergency Donation';
        allDonations.add(Donation.fromMap(doc.id, {
          ...data,
          'campaignTitle': title,
          'campaignType': 'emergency',
        }));
      }
    } catch (e) {
      // Ignored
    }

    // 3. Impact donations
    try {
      final snapshot = await _firestore
          .collection('impact_donations')
          .where('ngoId', isEqualTo: ngoId)
          .get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = data['impactTitle'] ?? data['campaignTitle'] ?? 'Impact Support';
        allDonations.add(Donation.fromMap(doc.id, {
          ...data,
          'campaignTitle': title,
          'campaignType': 'impact',
        }));
      }
    } catch (e) {
      // Ignored
    }

    // Sort by createdAt descending
    allDonations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allDonations;
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
