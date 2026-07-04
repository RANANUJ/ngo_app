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
