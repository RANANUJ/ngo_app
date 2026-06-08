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
  final String? profileImageUrl;
  final bool idProofUploaded;
  final bool registrationCertUploaded;
  final bool panCardUploaded;
  final bool certificate12A80GUploaded;
  final bool pastWorkProofUploaded;
  // Document URLs for actual file storage
  final String? idProofUrl;
  final String? registrationCertUrl;
  final String? panCardUrl;
  final String? certificate12A80GUrl;
  final String? pastWorkProofUrl;
  final String password; // Password for login (default: 123456)
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
    this.profileImageUrl,
    required this.idProofUploaded,
    required this.registrationCertUploaded,
    required this.panCardUploaded,
    required this.certificate12A80GUploaded,
    required this.pastWorkProofUploaded,
    this.idProofUrl,
    this.registrationCertUrl,
    this.panCardUrl,
    this.certificate12A80GUrl,
    this.pastWorkProofUrl,
    this.password = '123456', // Default password
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
      'profileImageUrl': profileImageUrl,
      'idProofUploaded': idProofUploaded,
      'registrationCertUploaded': registrationCertUploaded,
      'panCardUploaded': panCardUploaded,
      'certificate12A80GUploaded': certificate12A80GUploaded,
      'pastWorkProofUploaded': pastWorkProofUploaded,
      'idProofUrl': idProofUrl,
      'registrationCertUrl': registrationCertUrl,
      'panCardUrl': panCardUrl,
      'certificate12A80GUrl': certificate12A80GUrl,
      'pastWorkProofUrl': pastWorkProofUrl,
      'password': password,
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
      profileImageUrl: data['profileImageUrl'],
      idProofUploaded: data['idProofUploaded'] ?? false,
      registrationCertUploaded: data['registrationCertUploaded'] ?? false,
      panCardUploaded: data['panCardUploaded'] ?? false,
      certificate12A80GUploaded: data['certificate12A80GUploaded'] ?? false,
      pastWorkProofUploaded: data['pastWorkProofUploaded'] ?? false,
      idProofUrl: data['idProofUrl'],
      registrationCertUrl: data['registrationCertUrl'],
      panCardUrl: data['panCardUrl'],
      certificate12A80GUrl: data['certificate12A80GUrl'],
      pastWorkProofUrl: data['pastWorkProofUrl'],
      password: data['password'] ?? '123456',
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
    return _registrationsCollection.snapshots().handleError((e, st) {
      debugPrint('Firestore snapshots error: $e');
      debugPrint('$st');
    }).map((snapshot) {
      debugPrint('Firestore: Got ${snapshot.docs.length} registrations');
      final List<NgoRegistrationRequest> list = [];
      for (final doc in snapshot.docs) {
        try {
          list.add(NgoRegistrationRequest.fromFirestore(doc));
        } catch (e, st) {
          debugPrint('Error parsing registration doc ${doc.id}: $e');
          debugPrint('$st');
        }
      }
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    });
  }

  /// Get stream of pending registrations only
  Stream<List<NgoRegistrationRequest>> get pendingRegistrationsStream {
    return _registrationsCollection
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .handleError((e, st) {
          debugPrint('Pending snapshots error: $e');
          debugPrint('$st');
        })
        .map((snapshot) {
          final List<NgoRegistrationRequest> list = [];
          for (final doc in snapshot.docs) {
            try {
              list.add(NgoRegistrationRequest.fromFirestore(doc));
            } catch (e, st) {
              debugPrint('Error parsing pending doc ${doc.id}: $e');
              debugPrint('$st');
            }
          }
          return list;
        });
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
    String? idProofUrl,
    String? registrationCertUrl,
    String? panCardUrl,
    String? certificate12A80GUrl,
    String? pastWorkProofUrl,
    String password = '123456', // Default password if not provided
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
      idProofUrl: idProofUrl,
      registrationCertUrl: registrationCertUrl,
      panCardUrl: panCardUrl,
      certificate12A80GUrl: certificate12A80GUrl,
      pastWorkProofUrl: pastWorkProofUrl,
      password: password.isEmpty ? '123456' : password,
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
        idProofUrl: idProofUrl,
        registrationCertUrl: registrationCertUrl,
        panCardUrl: panCardUrl,
        certificate12A80GUrl: certificate12A80GUrl,
        pastWorkProofUrl: pastWorkProofUrl,
        password: password.isEmpty ? '123456' : password,
        submittedAt: registration.submittedAt,
        status: RegistrationStatus.pending,
      );
    } catch (e, stackTrace) {
      debugPrint('=== FIRESTORE ERROR ===');
      if (e is FirebaseException) {
        debugPrint('FirebaseException code: ${e.code}');
        debugPrint('FirebaseException message: ${e.message}');
      }
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
    return _registrationsCollection.doc(id).snapshots().handleError((e, st) {
      debugPrint('Status snapshot error for $id: $e');
      debugPrint('$st');
    }).map((doc) {
      try {
        if (doc.exists) {
          return NgoRegistrationRequest.fromFirestore(doc);
        }
      } catch (e, st) {
        debugPrint('Error parsing status doc ${doc.id}: $e');
        debugPrint('$st');
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

  /// Find approved registration by phone number (for NGO login)
  Future<NgoRegistrationRequest?> findApprovedRegistrationByPhone(String phone) async {
    try {
      // Try to find with the exact phone number
      var querySnapshot = await _registrationsCollection
          .where('mobileNo', isEqualTo: phone)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return NgoRegistrationRequest.fromFirestore(querySnapshot.docs.first);
      }
      
      // Also try with +91 prefix
      querySnapshot = await _registrationsCollection
          .where('mobileNo', isEqualTo: '+91$phone')
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return NgoRegistrationRequest.fromFirestore(querySnapshot.docs.first);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error finding registration by phone: $e');
      return null;
    }
  }

  /// Find registration by ID (for login verification)
  Future<NgoRegistrationRequest?> findRegistrationById(String id) async {
    try {
      final doc = await _registrationsCollection.doc(id).get();
      if (doc.exists) {
        return NgoRegistrationRequest.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error finding registration by ID: $e');
      return null;
    }
  }

  /// Verify NGO login with phone and password
  Future<NgoRegistrationRequest?> verifyLoginWithPassword(String phone, String password) async {
    try {
      // Try to find with the exact phone number
      var querySnapshot = await _registrationsCollection
          .where('mobileNo', isEqualTo: phone)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        // Also try with +91 prefix
        querySnapshot = await _registrationsCollection
            .where('mobileNo', isEqualTo: '+91$phone')
            .where('status', isEqualTo: 'approved')
            .limit(1)
            .get();
      }
      
      if (querySnapshot.docs.isNotEmpty) {
        final registration = NgoRegistrationRequest.fromFirestore(querySnapshot.docs.first);
        // Verify password
        if (registration.password == password) {
          return registration;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error verifying login with password: $e');
      return null;
    }
  }
}
