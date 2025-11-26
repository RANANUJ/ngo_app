import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Enum for registration status
enum RegistrationStatus {
  pending,
  approved,
  rejected,
}

/// Model for NGO Registration Request
class NgoRegistrationRequest {
  final String id;
  final String ngoName;
  final String registrationNo;
  final String ngoType;
  final String category;
  final String yearOfEstablishment;
  final String headOfficeAddress;
  final String branchOfficeAddress;
  final String officialPhone;
  final String websiteLink;
  final String contactPersonName;
  final String designation;
  final String mobileNo;
  final String email;
  final String idProofType;
  final String missionVision;
  final String areaOfWork;
  final String activeVolunteers;
  final String achievements;
  final bool idProofUploaded;
  final bool registrationCertUploaded;
  final bool panCardUploaded;
  final bool certificate12A80GUploaded;
  final bool pastWorkProofUploaded;
  final DateTime submittedAt;
  final RegistrationStatus status;
  final String? rejectionReason;
  final DateTime? reviewedAt;

  NgoRegistrationRequest({
    required this.id,
    required this.ngoName,
    required this.registrationNo,
    required this.ngoType,
    required this.category,
    required this.yearOfEstablishment,
    required this.headOfficeAddress,
    required this.branchOfficeAddress,
    required this.officialPhone,
    required this.websiteLink,
    required this.contactPersonName,
    required this.designation,
    required this.mobileNo,
    required this.email,
    required this.idProofType,
    required this.missionVision,
    required this.areaOfWork,
    required this.activeVolunteers,
    required this.achievements,
    required this.idProofUploaded,
    required this.registrationCertUploaded,
    required this.panCardUploaded,
    required this.certificate12A80GUploaded,
    required this.pastWorkProofUploaded,
    required this.submittedAt,
    this.status = RegistrationStatus.pending,
    this.rejectionReason,
    this.reviewedAt,
  });

  /// Calculate document completion percentage
  int get documentCompletionPercentage {
    int uploaded = 0;
    if (idProofUploaded) uploaded++;
    if (registrationCertUploaded) uploaded++;
    if (panCardUploaded) uploaded++;
    if (certificate12A80GUploaded) uploaded++;
    if (pastWorkProofUploaded) uploaded++;
    return ((uploaded / 5) * 100).round();
  }

  /// Check if all required fields are filled
  bool get isComplete {
    return ngoName.isNotEmpty &&
        registrationNo.isNotEmpty &&
        ngoType.isNotEmpty &&
        contactPersonName.isNotEmpty &&
        email.isNotEmpty &&
        mobileNo.isNotEmpty;
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'ngoName': ngoName,
      'registrationNo': registrationNo,
      'ngoType': ngoType,
      'category': category,
      'yearOfEstablishment': yearOfEstablishment,
      'headOfficeAddress': headOfficeAddress,
      'branchOfficeAddress': branchOfficeAddress,
      'officialPhone': officialPhone,
      'websiteLink': websiteLink,
      'contactPersonName': contactPersonName,
      'designation': designation,
      'mobileNo': mobileNo,
      'email': email,
      'idProofType': idProofType,
      'missionVision': missionVision,
      'areaOfWork': areaOfWork,
      'activeVolunteers': activeVolunteers,
      'achievements': achievements,
      'idProofUploaded': idProofUploaded,
      'registrationCertUploaded': registrationCertUploaded,
      'panCardUploaded': panCardUploaded,
      'certificate12A80GUploaded': certificate12A80GUploaded,
      'pastWorkProofUploaded': pastWorkProofUploaded,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status.name,
      'rejectionReason': rejectionReason,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }

  /// Create from Firestore document
  factory NgoRegistrationRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NgoRegistrationRequest(
      id: doc.id,
      ngoName: data['ngoName'] ?? '',
      registrationNo: data['registrationNo'] ?? '',
      ngoType: data['ngoType'] ?? '',
      category: data['category'] ?? '',
      yearOfEstablishment: data['yearOfEstablishment'] ?? '',
      headOfficeAddress: data['headOfficeAddress'] ?? '',
      branchOfficeAddress: data['branchOfficeAddress'] ?? '',
      officialPhone: data['officialPhone'] ?? '',
      websiteLink: data['websiteLink'] ?? '',
      contactPersonName: data['contactPersonName'] ?? '',
      designation: data['designation'] ?? '',
      mobileNo: data['mobileNo'] ?? '',
      email: data['email'] ?? '',
      idProofType: data['idProofType'] ?? '',
      missionVision: data['missionVision'] ?? '',
      areaOfWork: data['areaOfWork'] ?? '',
      activeVolunteers: data['activeVolunteers'] ?? '',
      achievements: data['achievements'] ?? '',
      idProofUploaded: data['idProofUploaded'] ?? false,
      registrationCertUploaded: data['registrationCertUploaded'] ?? false,
      panCardUploaded: data['panCardUploaded'] ?? false,
      certificate12A80GUploaded: data['certificate12A80GUploaded'] ?? false,
      pastWorkProofUploaded: data['pastWorkProofUploaded'] ?? false,
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseStatus(data['status']),
      rejectionReason: data['rejectionReason'],
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }

  static RegistrationStatus _parseStatus(String? status) {
    switch (status) {
      case 'approved':
        return RegistrationStatus.approved;
      case 'rejected':
        return RegistrationStatus.rejected;
      default:
        return RegistrationStatus.pending;
    }
  }
}

/// Service to manage NGO registrations with Firebase
class NgoRegistrationService {
  // Singleton pattern
  static final NgoRegistrationService _instance = NgoRegistrationService._internal();
  factory NgoRegistrationService() => _instance;
  NgoRegistrationService._internal();

  // Firestore collection reference
  final CollectionReference _registrationsCollection =
      FirebaseFirestore.instance.collection('ngo_registrations');

  /// Get stream of all registrations (for admin) - real-time updates
  Stream<List<NgoRegistrationRequest>> get registrationsStream {
    return _registrationsCollection
        .snapshots()
        .map((snapshot) {
          print('Firestore: Got ${snapshot.docs.length} registrations');
          return snapshot.docs
            .map((doc) => NgoRegistrationRequest.fromFirestore(doc))
            .toList()
            ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        });
  }

  /// Get stream of pending registrations only
  Stream<List<NgoRegistrationRequest>> get pendingRegistrationsStream {
    return _registrationsCollection
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NgoRegistrationRequest.fromFirestore(doc))
            .toList());
  }

  /// Submit a new NGO registration
  Future<NgoRegistrationRequest> submitRegistration({
    required String ngoName,
    required String registrationNo,
    required String ngoType,
    required String category,
    required String yearOfEstablishment,
    required String headOfficeAddress,
    required String branchOfficeAddress,
    required String officialPhone,
    required String websiteLink,
    required String contactPersonName,
    required String designation,
    required String mobileNo,
    required String email,
    required String idProofType,
    required String missionVision,
    required String areaOfWork,
    required String activeVolunteers,
    required String achievements,
    required bool idProofUploaded,
    required bool registrationCertUploaded,
    required bool panCardUploaded,
    required bool certificate12A80GUploaded,
    required bool pastWorkProofUploaded,
  }) async {
    final registration = NgoRegistrationRequest(
      id: '', // Will be set by Firestore
      ngoName: ngoName,
      registrationNo: registrationNo,
      ngoType: ngoType,
      category: category,
      yearOfEstablishment: yearOfEstablishment,
      headOfficeAddress: headOfficeAddress,
      branchOfficeAddress: branchOfficeAddress,
      officialPhone: officialPhone,
      websiteLink: websiteLink,
      contactPersonName: contactPersonName,
      designation: designation,
      mobileNo: mobileNo,
      email: email,
      idProofType: idProofType,
      missionVision: missionVision,
      areaOfWork: areaOfWork,
      activeVolunteers: activeVolunteers,
      achievements: achievements,
      idProofUploaded: idProofUploaded,
      registrationCertUploaded: registrationCertUploaded,
      panCardUploaded: panCardUploaded,
      certificate12A80GUploaded: certificate12A80GUploaded,
      pastWorkProofUploaded: pastWorkProofUploaded,
      submittedAt: DateTime.now(),
      status: RegistrationStatus.pending,
    );

    // Add to Firestore
    debugPrint('=== FIRESTORE: Submitting registration... ===');
    debugPrint('NGO Name: $ngoName');
    debugPrint('Email: $email');
    try {
      final docRef = await _registrationsCollection.add(registration.toFirestore());
      debugPrint('=== FIRESTORE: SUCCESS! Doc ID: ${docRef.id} ===');

      // Return with the generated ID
      return NgoRegistrationRequest(
        id: docRef.id,
        ngoName: ngoName,
        registrationNo: registrationNo,
        ngoType: ngoType,
        category: category,
        yearOfEstablishment: yearOfEstablishment,
        headOfficeAddress: headOfficeAddress,
        branchOfficeAddress: branchOfficeAddress,
        officialPhone: officialPhone,
        websiteLink: websiteLink,
        contactPersonName: contactPersonName,
        designation: designation,
        mobileNo: mobileNo,
        email: email,
        idProofType: idProofType,
        missionVision: missionVision,
        areaOfWork: areaOfWork,
        activeVolunteers: activeVolunteers,
        achievements: achievements,
        idProofUploaded: idProofUploaded,
        registrationCertUploaded: registrationCertUploaded,
        panCardUploaded: panCardUploaded,
        certificate12A80GUploaded: certificate12A80GUploaded,
        pastWorkProofUploaded: pastWorkProofUploaded,
        submittedAt: registration.submittedAt,
        status: RegistrationStatus.pending,
      );
    } catch (e, stackTrace) {
      debugPrint('=== FIRESTORE ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get registration by ID
  Future<NgoRegistrationRequest?> getRegistrationById(String id) async {
    try {
      final doc = await _registrationsCollection.doc(id).get();
      if (doc.exists) {
        return NgoRegistrationRequest.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting registration: $e');
      return null;
    }
  }

  /// Get real-time status stream for a specific registration (for NGO member to listen)
  Stream<NgoRegistrationRequest?> getStatusStream(String id) {
    return _registrationsCollection.doc(id).snapshots().map((doc) {
      if (doc.exists) {
        return NgoRegistrationRequest.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Approve a registration (admin action)
  Future<bool> approveRegistration(String id) async {
    try {
      await _registrationsCollection.doc(id).update({
        'status': 'approved',
        'reviewedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error approving registration: $e');
      return false;
    }
  }

  /// Reject a registration (admin action)
  Future<bool> rejectRegistration(String id, String reason) async {
    try {
      await _registrationsCollection.doc(id).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'reviewedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error rejecting registration: $e');
      return false;
    }
  }

  /// Get statistics for admin dashboard
  Future<Map<String, int>> getStatistics() async {
    try {
      final allDocs = await _registrationsCollection.get();
      final pending = allDocs.docs.where((d) => (d.data() as Map)['status'] == 'pending').length;
      final approved = allDocs.docs.where((d) => (d.data() as Map)['status'] == 'approved').length;
      final rejected = allDocs.docs.where((d) => (d.data() as Map)['status'] == 'rejected').length;
      
      return {
        'total': allDocs.docs.length,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {'total': 0, 'pending': 0, 'approved': 0, 'rejected': 0};
    }
  }
}
