import 'package:flutter/material.dart';
import '../../domain/models/donation.dart';
import '../../domain/models/donation_request.dart';
import '../../domain/models/subscription.dart';
import '../../domain/models/donation_stats.dart';
import '../../domain/repositories/donation_repository.dart';
import 'package:ngo_app/core/services/email_service.dart';

class DonationController extends ChangeNotifier {
  final DonationRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;

  List<Donation> _volunteerDonations = [];
  MonthlyFundingStats? _monthlyStats;
  List<DonorSummary> _topDonors = [];
  Map<String, double> _yearlyTrend = {};
  List<Donation> _monthlyTransactions = [];
  List<Subscription> _subscriptions = [];

  DonationController(this._repository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Donation> get volunteerDonations => _volunteerDonations;
  MonthlyFundingStats? get monthlyStats => _monthlyStats;
  List<DonorSummary> get topDonors => _topDonors;
  Map<String, double> get yearlyTrend => _yearlyTrend;
  List<Donation> get monthlyTransactions => _monthlyTransactions;
  List<Subscription> get subscriptions => _subscriptions;

  Future<void> loadVolunteerDonations(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _volunteerDonations = await _repository.getVolunteerDonations(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadNgoFundingDashboardData({
    required String ngoId,
    required int month,
    required int year,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _monthlyStats = await _repository.getMonthlyStats(
        ngoId: ngoId,
        month: month,
        year: year,
      );
      _topDonors = await _repository.getTopDonors(ngoId: ngoId, limit: 20);
      _yearlyTrend = await _repository.getYearlyTrend(ngoId: ngoId, year: year);
      _monthlyTransactions = await _repository.getMonthlyDonations(ngoId: ngoId);
      _subscriptions = await _repository.getAllSubscriptions(ngoId: ngoId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> sendThankYouEmail({
    required String donationId,
    required String donorEmail,
    required String donorName,
    required double amount,
    required String campaignTitle,
    required String ngoName,
    required DateTime donationDate,
    required String ngoEmail,
  }) async {
    try {
      final success = await EmailService.sendThankYouEmail(
        donorEmail: donorEmail,
        donorName: donorName,
        amount: amount,
        campaignTitle: campaignTitle,
        ngoName: ngoName,
        donationDate: donationDate,
        ngoEmail: ngoEmail,
      );

      if (success) {
        await _repository.markThankYouSent(donationId);
        // Reload transactions to sync UI state
        _monthlyTransactions = _monthlyTransactions.map((t) {
          if (t.id == donationId) {
            return Donation(
              id: t.id,
              paymentId: t.paymentId,
              orderId: t.orderId,
              signature: t.signature,
              amount: t.amount,
              status: t.status,
              paymentMethod: t.paymentMethod,
              donorName: t.donorName,
              donorEmail: t.donorEmail,
              donorPhone: t.donorPhone,
              donorId: t.donorId,
              profileImageUrl: t.profileImageUrl,
              isAnonymous: t.isAnonymous,
              campaignId: t.campaignId,
              campaignTitle: t.campaignTitle,
              campaignType: t.campaignType,
              ngoId: t.ngoId,
              message: t.message,
              createdAt: t.createdAt,
            );
          }
          return t;
        }).toList();
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markThankYouSent(String donationId) async {
    try {
      final success = await _repository.markThankYouSent(donationId);
      if (success) {
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<void> markRequestComplete(String requestId) async {
    try {
      await _repository.markRequestComplete(requestId);
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Stream<List<DonationRequest>> streamNgoDonationRequests(String ngoId) {
    return _repository.streamDonationRequests(ngoId);
  }

  Stream<List<DonationRequest>> streamActiveDonationRequests() {
    return _repository.streamActiveDonationRequests();
  }

  Stream<List<Donation>> streamNgoReceivedDonations(String ngoId) {
    return _repository.streamNgoReceivedDonations(ngoId);
  }

  Stream<List<Map<String, dynamic>>> streamBlockchainDonations(String ngoId) {
    return _repository.streamBlockchainDonations(ngoId);
  }

  Stream<List<Donation>> streamMonthlyDonations({
    required String ngoId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    return _repository.streamMonthlyDonations(
      ngoId: ngoId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  Future<List<Donation>> getNgoCombinedDonations(String ngoId) {
    return _repository.getNgoCombinedDonations(ngoId);
  }
}
