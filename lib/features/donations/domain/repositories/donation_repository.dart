import '../models/donation.dart';
import '../models/donation_request.dart';
import '../models/subscription.dart';
import '../models/donation_stats.dart';

abstract class DonationRepository {
  // Volunteers
  Future<List<Donation>> getVolunteerDonations(String userId);
  Future<String> saveDonation(Donation donation);

  // NGOs - Received Donations
  Future<List<Donation>> getNgoReceivedDonations(String ngoId);
  Stream<List<Donation>> streamNgoReceivedDonations(String ngoId);

  // NGOs - Monthly Funding
  Future<List<Donation>> getMonthlyDonations({
    required String ngoId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });
  Stream<List<Donation>> streamMonthlyDonations({
    required String ngoId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });

  // NGOs - Subscriptions
  Future<List<Subscription>> getAllSubscriptions({required String ngoId});
  Stream<List<Subscription>> getSubscriptionsStream({
    required String ngoId,
    String? status,
  });

  // NGOs - Statistics
  Future<MonthlyFundingStats> getMonthlyStats({
    required String ngoId,
    required int month,
    required int year,
  });
  Future<List<DonorSummary>> getTopDonors({
    required String ngoId,
    int limit,
  });
  Future<Map<String, double>> getYearlyTrend({
    required String ngoId,
    required int year,
  });
  Future<bool> markThankYouSent(String donationId);

  // Donation Requests / Posts
  Stream<List<DonationRequest>> streamDonationRequests(String ngoId);
  Stream<List<DonationRequest>> streamActiveDonationRequests();
  Future<void> markRequestComplete(String requestId);

  // Blockchain Donations
  Stream<List<Map<String, dynamic>>> streamBlockchainDonations(String ngoId);

  // NGO Combined Donations for Dashboard Charts
  Future<List<Donation>> getNgoCombinedDonations(String ngoId);
}
