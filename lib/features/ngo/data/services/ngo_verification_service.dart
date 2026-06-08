import 'dart:async';
import 'dart:math';

/// Verification status levels for NGO
enum VerificationLevel {
  pending,
  documentsUploaded,
  autoVerified,
  manualReview,
  verified,
  rejected,
}

/// Individual verification check result
class VerificationCheck {
  final String checkName;
  final bool passed;
  final String? failureReason;
  final DateTime checkedAt;

  VerificationCheck({
    required this.checkName,
    required this.passed,
    this.failureReason,
    DateTime? checkedAt,
  }) : checkedAt = checkedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'checkName': checkName,
    'passed': passed,
    'failureReason': failureReason,
    'checkedAt': checkedAt.toIso8601String(),
  };
}

/// Overall verification result
class VerificationResult {
  final VerificationLevel status;
  final List<VerificationCheck> checks;
  final int trustScore;
  final String? message;
  final String? rejectionReason;

  VerificationResult({
    required this.status,
    required this.checks,
    required this.trustScore,
    this.message,
    this.rejectionReason,
  });

  bool get isVerified => status == VerificationLevel.verified || status == VerificationLevel.autoVerified;
  
  int get passedChecks => checks.where((c) => c.passed).length;
  int get totalChecks => checks.length;
  
  String get statusBadge {
    switch (status) {
      case VerificationLevel.verified:
        return '✅ Verified NGO';
      case VerificationLevel.autoVerified:
        return '✅ Auto Verified';
      case VerificationLevel.manualReview:
        return '⏳ Under Review';
      case VerificationLevel.pending:
        return '📋 Pending';
      case VerificationLevel.rejected:
        return '❌ Rejected';
      default:
        return '📋 Pending';
    }
  }
}

/// NGO Registration Data Model
class NgoRegistrationData {
  final String ngoName;
  final String registrationNo;
  final String? ngoType;
  final String? category;
  final String yearOfEstablishment;
  final String headOfficeAddress;
  final String branchOfficeAddress;
  final String officialPhone;
  final String websiteLink;
  final String contactPersonName;
  final String designation;
  final String mobileNo;
  final String email;
  final String? idProofType;
  final String missionVision;
  final String areaOfWork;
  final String activeVolunteers;
  final String achievements;
  
  // Document paths
  final String? idProofPath;
  final String? registrationCertPath;
  final String? panCardPath;
  final String? certificate12A80GPath;
  final String? pastWorkProofPath;

  NgoRegistrationData({
    required this.ngoName,
    required this.registrationNo,
    this.ngoType,
    this.category,
    required this.yearOfEstablishment,
    required this.headOfficeAddress,
    required this.branchOfficeAddress,
    required this.officialPhone,
    required this.websiteLink,
    required this.contactPersonName,
    required this.designation,
    required this.mobileNo,
    required this.email,
    this.idProofType,
    required this.missionVision,
    required this.areaOfWork,
    required this.activeVolunteers,
    required this.achievements,
    this.idProofPath,
    this.registrationCertPath,
    this.panCardPath,
    this.certificate12A80GPath,
    this.pastWorkProofPath,
  });
}

/// Trust Score Breakdown
class NgoTrustScore {
  final int documentScore;      // 0-25 points
  final int governmentVerified; // 0-25 points
  final int activityScore;      // 0-20 points
  final int transparencyScore;  // 0-15 points
  final int communityScore;     // 0-15 points

  NgoTrustScore({
    required this.documentScore,
    required this.governmentVerified,
    required this.activityScore,
    required this.transparencyScore,
    required this.communityScore,
  });

  int get totalScore => documentScore + governmentVerified + activityScore + transparencyScore + communityScore;

  String get badge {
    final score = totalScore;
    if (score >= 90) return '🏆 Platinum Verified';
    if (score >= 75) return '🥇 Gold Verified';
    if (score >= 50) return '🥈 Silver Verified';
    if (score >= 25) return '🥉 Bronze Verified';
    return '⏳ Pending Verification';
  }

  String get badgeColor {
    final score = totalScore;
    if (score >= 90) return 'platinum';
    if (score >= 75) return 'gold';
    if (score >= 50) return 'silver';
    if (score >= 25) return 'bronze';
    return 'pending';
  }
}

/// Main NGO Verification Service
class NgoVerificationService {
  
  /// Perform complete verification of NGO registration
  static Future<VerificationResult> verifyNgoRegistration(NgoRegistrationData data) async {
    List<VerificationCheck> checks = [];
    
    // Step 1: Verify NGO Darpan Registration
    final darpanCheck = await _verifyNgoDarpan(data.registrationNo, data.ngoName);
    checks.add(darpanCheck);
    
    // Step 2: Verify Registration Number Format
    final regNoFormatCheck = _verifyRegistrationNumberFormat(data.registrationNo, data.ngoType);
    checks.add(regNoFormatCheck);
    
    // Step 3: Verify PAN Card
    final panCheck = await _verifyPanCard(data.ngoName, data.panCardPath);
    checks.add(panCheck);
    
    // Step 4: Verify 12A/80G Certificate
    final certCheck = await _verify12A80GCertificate(data.certificate12A80GPath);
    checks.add(certCheck);
    
    // Step 5: Verify Contact Details
    final contactCheck = await _verifyContactDetails(data.email, data.mobileNo);
    checks.add(contactCheck);
    
    // Step 6: Verify Address
    final addressCheck = await _verifyAddress(data.headOfficeAddress);
    checks.add(addressCheck);
    
    // Step 7: Check for Duplicates
    final duplicateCheck = await _checkForDuplicates(data.registrationNo, data.ngoName);
    checks.add(duplicateCheck);
    
    // Step 8: Verify Website/Social Media (if provided)
    if (data.websiteLink.isNotEmpty) {
      final websiteCheck = await _verifyWebsite(data.websiteLink);
      checks.add(websiteCheck);
    }
    
    // Step 9: Document Completeness Check
    final docCheck = _verifyDocumentCompleteness(data);
    checks.add(docCheck);
    
    // Step 10: Year of Establishment Validation
    final yearCheck = _verifyYearOfEstablishment(data.yearOfEstablishment);
    checks.add(yearCheck);
    
    // Calculate trust score
    final trustScore = _calculateTrustScore(checks, data);
    
    // Determine final status
    final status = _determineVerificationStatus(checks, trustScore);
    
    return VerificationResult(
      status: status,
      checks: checks,
      trustScore: trustScore.totalScore,
      message: _getStatusMessage(status, checks),
      rejectionReason: status == VerificationLevel.rejected 
          ? _getRejectionReason(checks) 
          : null,
    );
  }
  
  /// Verify against NGO Darpan database
  static Future<VerificationCheck> _verifyNgoDarpan(String regNo, String ngoName) async {
    // Simulate API call to NGO Darpan (niti.gov.in)
    await Future.delayed(const Duration(milliseconds: 800));
    
    // In production, integrate with actual NGO Darpan API
    // API endpoint: https://ngodarpan.gov.in/index.php/ajaxcontroller/show_ngo_info
    
    // Validation logic - check if data is actually provided
    String? failureReason;
    bool isValid = false;
    
    if (regNo.trim().isEmpty) {
      failureReason = 'Registration number is required';
    } else if (ngoName.trim().isEmpty) {
      failureReason = 'NGO name is required';
    } else if (regNo.length < 5) {
      failureReason = 'Registration number too short';
    } else {
      // Valid registration number format
      isValid = true;
    }
    
    return VerificationCheck(
      checkName: 'NGO Darpan Verification',
      passed: isValid,
      failureReason: failureReason,
    );
  }
  
  /// Verify registration number format based on NGO type
  static VerificationCheck _verifyRegistrationNumberFormat(String regNo, String? ngoType) {
    bool isValid = false;
    String? failureReason;
    
    if (regNo.trim().isEmpty) {
      failureReason = 'Registration number is required';
    } else if (ngoType == null || ngoType.isEmpty) {
      failureReason = 'NGO type is required';
    } else if (ngoType == 'Trust') {
      // Trust registration format validation
      isValid = regNo.length >= 5 && RegExp(r'^[A-Z0-9/-]+$').hasMatch(regNo.toUpperCase());
      if (!isValid) failureReason = 'Invalid Trust registration number format';
    } else if (ngoType == 'Society') {
      // Society registration format validation
      isValid = regNo.length >= 5;
      if (!isValid) failureReason = 'Invalid Society registration number format';
    } else if (ngoType == 'Section 8 Company') {
      // CIN format validation for Section 8 company
      isValid = regNo.length >= 10;
      if (!isValid) failureReason = 'Invalid CIN format for Section 8 Company';
    } else {
      isValid = regNo.length >= 5;
      if (!isValid) failureReason = 'Registration number must be at least 5 characters';
    }
    
    return VerificationCheck(
      checkName: 'Registration Number Format',
      passed: isValid,
      failureReason: failureReason,
    );
  }
  
  /// Verify PAN Card
  static Future<VerificationCheck> _verifyPanCard(String ngoName, String? panCardPath) async {
    // Simulate PAN verification API call
    await Future.delayed(const Duration(milliseconds: 600));
    
    // In production, integrate with Income Tax Department API
    // Or use third-party services like Karza, Signzy
    
    bool isValid = false;
    String? failureReason;
    
    if (ngoName.trim().isEmpty) {
      failureReason = 'NGO name is required for PAN verification';
    } else if (panCardPath == null || panCardPath.isEmpty) {
      failureReason = 'PAN card document not uploaded';
    } else {
      isValid = true;
    }
    
    return VerificationCheck(
      checkName: 'PAN Card Verification',
      passed: isValid,
      failureReason: failureReason,
    );
  }
  
  /// Verify 12A/80G Certificate
  static Future<VerificationCheck> _verify12A80GCertificate(String? certificatePath) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // In production, verify against Income Tax exemption database
    
    bool isValid = false;
    String? failureReason;
    
    if (certificatePath == null || certificatePath.isEmpty) {
      failureReason = '12A/80G certificate not uploaded';
    } else {
      isValid = true;
    }
    
    return VerificationCheck(
      checkName: '12A/80G Certificate Verification',
      passed: isValid,
      failureReason: failureReason,
    );
  }
  
  /// Verify contact details (email and phone)
  static Future<VerificationCheck> _verifyContactDetails(String email, String phone) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    bool emailValid = email.isNotEmpty && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    bool phoneValid = phone.isNotEmpty && phone.length >= 10;
    
    bool isValid = emailValid && phoneValid;
    
    return VerificationCheck(
      checkName: 'Contact Details Verification',
      passed: isValid,
      failureReason: isValid ? null : 'Invalid email or phone number format',
    );
  }
  
  /// Verify address using geocoding
  static Future<VerificationCheck> _verifyAddress(String address) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // In production, use Google Maps Geocoding API or similar
    // to verify address exists and is valid
    
    bool isValid = address.isNotEmpty && address.length >= 10;
    
    return VerificationCheck(
      checkName: 'Address Verification',
      passed: isValid,
      failureReason: isValid ? null : 'Address could not be verified',
    );
  }
  
  /// Check for duplicate registrations
  static Future<VerificationCheck> _checkForDuplicates(String regNo, String ngoName) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    // In production, check against your database for:
    // - Same registration number
    // - Similar NGO names (fuzzy matching)
    // - Same contact details
    
    bool isValid = false;
    String? failureReason;
    
    if (regNo.trim().isEmpty && ngoName.trim().isEmpty) {
      failureReason = 'Registration number and NGO name are required';
    } else if (regNo.trim().isEmpty) {
      failureReason = 'Registration number is required for duplicate check';
    } else {
      // No duplicates found (in production, query database)
      isValid = true;
    }
    
    return VerificationCheck(
      checkName: 'Duplicate Check',
      passed: isValid,
      failureReason: failureReason,
    );
  }
  
  /// Verify website existence
  static Future<VerificationCheck> _verifyWebsite(String websiteLink) async {
    await Future.delayed(const Duration(milliseconds: 700));
    
    // In production, make HTTP request to verify website exists
    // Also check if website content matches NGO details
    
    bool isValid = websiteLink.startsWith('http://') || 
                   websiteLink.startsWith('https://') ||
                   websiteLink.contains('.');
    
    return VerificationCheck(
      checkName: 'Website Verification',
      passed: isValid,
      failureReason: isValid ? null : 'Website could not be verified',
    );
  }
  
  /// Check document completeness
  static VerificationCheck _verifyDocumentCompleteness(NgoRegistrationData data) {
    int uploadedDocs = 0;
    List<String> missingDocs = [];
    
    if (data.registrationCertPath != null && data.registrationCertPath!.isNotEmpty) {
      uploadedDocs++;
    } else {
      missingDocs.add('Registration Certificate');
    }
    
    if (data.panCardPath != null && data.panCardPath!.isNotEmpty) {
      uploadedDocs++;
    } else {
      missingDocs.add('PAN Card');
    }
    
    if (data.certificate12A80GPath != null && data.certificate12A80GPath!.isNotEmpty) {
      uploadedDocs++;
    } else {
      missingDocs.add('12A/80G Certificate');
    }
    
    if (data.idProofPath != null && data.idProofPath!.isNotEmpty) {
      uploadedDocs++;
    } else {
      missingDocs.add('ID Proof');
    }
    
    bool isComplete = uploadedDocs >= 3; // At least 3 documents required
    
    return VerificationCheck(
      checkName: 'Document Completeness',
      passed: isComplete,
      failureReason: isComplete ? null : 'Missing documents: ${missingDocs.take(2).join(", ")}',
    );
  }
  
  /// Validate year of establishment
  static VerificationCheck _verifyYearOfEstablishment(String year) {
    bool isValid = false;
    String? failureReason;
    
    try {
      // Try parsing as year or date
      int? establishmentYear;
      
      if (year.contains('/')) {
        // Format: DD/MM/YYYY
        final parts = year.split('/');
        if (parts.length == 3) {
          establishmentYear = int.tryParse(parts[2]);
        }
      } else {
        establishmentYear = int.tryParse(year);
      }
      
      if (establishmentYear != null) {
        final currentYear = DateTime.now().year;
        isValid = establishmentYear >= 1800 && establishmentYear <= currentYear;
        if (!isValid) {
          failureReason = 'Year of establishment must be between 1800 and $currentYear';
        }
      } else {
        failureReason = 'Invalid year format';
      }
    } catch (e) {
      failureReason = 'Could not parse year of establishment';
    }
    
    return VerificationCheck(
      checkName: 'Establishment Year Validation',
      passed: isValid,
      failureReason: failureReason,
    );
  }
  
  /// Calculate trust score based on verification checks
  static NgoTrustScore _calculateTrustScore(List<VerificationCheck> checks, NgoRegistrationData data) {
    // Document Score (0-25)
    int documentScore = 0;
    if (data.registrationCertPath != null) documentScore += 7;
    if (data.panCardPath != null) documentScore += 6;
    if (data.certificate12A80GPath != null) documentScore += 6;
    if (data.idProofPath != null) documentScore += 3;
    if (data.pastWorkProofPath != null) documentScore += 3;
    
    // Government Verification Score (0-25)
    int governmentScore = 0;
    for (var check in checks) {
      if (check.checkName == 'NGO Darpan Verification' && check.passed) governmentScore += 10;
      if (check.checkName == 'PAN Card Verification' && check.passed) governmentScore += 8;
      if (check.checkName == '12A/80G Certificate Verification' && check.passed) governmentScore += 7;
    }
    
    // Activity Score (0-20)
    int activityScore = 0;
    if (data.achievements.isNotEmpty) activityScore += 10;
    if (data.activeVolunteers.isNotEmpty) {
      int volunteers = int.tryParse(data.activeVolunteers) ?? 0;
      if (volunteers > 100) activityScore += 10;
      else if (volunteers > 50) activityScore += 7;
      else if (volunteers > 10) activityScore += 5;
      else activityScore += 2;
    }
    
    // Transparency Score (0-15)
    int transparencyScore = 0;
    if (data.websiteLink.isNotEmpty) transparencyScore += 8;
    if (data.missionVision.isNotEmpty) transparencyScore += 4;
    if (data.areaOfWork.isNotEmpty) transparencyScore += 3;
    
    // Community Score (0-15) - In production, this would be from ratings/reviews
    int communityScore = Random().nextInt(10) + 5; // Simulated
    
    return NgoTrustScore(
      documentScore: documentScore.clamp(0, 25),
      governmentVerified: governmentScore.clamp(0, 25),
      activityScore: activityScore.clamp(0, 20),
      transparencyScore: transparencyScore.clamp(0, 15),
      communityScore: communityScore.clamp(0, 15),
    );
  }
  
  /// Determine final verification status
  static VerificationLevel _determineVerificationStatus(List<VerificationCheck> checks, NgoTrustScore trustScore) {
    int passedChecks = checks.where((c) => c.passed).length;
    int totalChecks = checks.length;
    double passRate = passedChecks / totalChecks;
    
    // Check critical failures
    bool hasCriticalFailure = checks.any((c) => 
      !c.passed && (
        c.checkName == 'NGO Darpan Verification' ||
        c.checkName == 'Duplicate Check'
      )
    );
    
    if (hasCriticalFailure) {
      return VerificationLevel.manualReview;
    }
    
    if (passRate >= 0.9 && trustScore.totalScore >= 75) {
      return VerificationLevel.verified;
    } else if (passRate >= 0.7 && trustScore.totalScore >= 50) {
      return VerificationLevel.autoVerified;
    } else if (passRate >= 0.5) {
      return VerificationLevel.manualReview;
    } else {
      return VerificationLevel.rejected;
    }
  }
  
  /// Get status message
  static String _getStatusMessage(VerificationLevel status, List<VerificationCheck> checks) {
    switch (status) {
      case VerificationLevel.verified:
        return 'Congratulations! Your NGO has been fully verified.';
      case VerificationLevel.autoVerified:
        return 'Your NGO has been auto-verified. Welcome aboard!';
      case VerificationLevel.manualReview:
        int failed = checks.where((c) => !c.passed).length;
        return 'Your application is under manual review. $failed check(s) need verification.';
      case VerificationLevel.rejected:
        return 'Unfortunately, your application could not be verified at this time.';
      default:
        return 'Your application is being processed.';
    }
  }
  
  /// Get rejection reason
  static String _getRejectionReason(List<VerificationCheck> checks) {
    List<String> reasons = checks
        .where((c) => !c.passed && c.failureReason != null)
        .map((c) => c.failureReason!)
        .toList();
    
    return reasons.join('\n');
  }
}
