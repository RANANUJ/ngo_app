import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/opportunity.dart';
import '../../domain/models/opportunity_application.dart';
import '../../domain/repositories/opportunity_repository.dart';

class FirebaseOpportunityRepository implements OpportunityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Opportunity>> streamAllOpportunities() {
    return _firestore
        .collection('volunteer_opportunities')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Opportunity.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<List<Opportunity>> streamNgoOpportunities(String ngoId) {
    return _firestore
        .collection('volunteer_opportunities')
        .where('ngoId', isEqualTo: ngoId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Opportunity.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<Opportunity> getOpportunityById(String id) async {
    final doc =
        await _firestore.collection('volunteer_opportunities').doc(id).get();
    if (!doc.exists) {
      throw Exception('Opportunity not found');
    }
    return Opportunity.fromMap(doc.id, doc.data()!);
  }

  @override
  Future<String> createOpportunity(Opportunity opportunity) async {
    final ref = await _firestore
        .collection('volunteer_opportunities')
        .add(opportunity.toMap());
    return ref.id;
  }

  @override
  Future<void> updateOpportunity(Opportunity opportunity) async {
    await _firestore
        .collection('volunteer_opportunities')
        .doc(opportunity.id)
        .update(opportunity.toMap());
  }

  @override
  Future<void> deleteOpportunity(String id) async {
    await _firestore.collection('volunteer_opportunities').doc(id).delete();
  }

  @override
  Future<void> applyForOpportunity(OpportunityApplication application) async {
    await _firestore
        .collection('opportunity_applications')
        .add(application.toMap());

    // Update applications count
    await _firestore
        .collection('volunteer_opportunities')
        .doc(application.opportunityId)
        .update({
      'applicationsCount': FieldValue.increment(1),
    });
  }

  @override
  Future<bool> hasAppliedForOpportunity(
      String opportunityId, String volunteerId) async {
    final snapshot = await _firestore
        .collection('opportunity_applications')
        .where('opportunityId', isEqualTo: opportunityId)
        .where('volunteerId', isEqualTo: volunteerId)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Stream<List<Opportunity>> streamAppliedOpportunities(String volunteerId) {
    return _firestore
        .collection('opportunity_applications')
        .where('volunteerId', isEqualTo: volunteerId)
        .snapshots()
        .asyncMap((snapshot) async {
      final oppIds =
          snapshot.docs.map((doc) => doc['opportunityId'] as String).toList();
      if (oppIds.isEmpty) return <Opportunity>[];

      final List<Opportunity> opportunities = [];
      // Fetch in chunks of 10 (Firestore limit for whereIn)
      for (var i = 0; i < oppIds.length; i += 10) {
        final chunk = oppIds.sublist(
            i, i + 10 > oppIds.length ? oppIds.length : i + 10);
        final oppSnapshots = await _firestore
            .collection('volunteer_opportunities')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (var doc in oppSnapshots.docs) {
          opportunities.add(Opportunity.fromMap(doc.id, doc.data()));
        }
      }
      return opportunities;
    });
  }

  @override
  Stream<List<OpportunityApplication>> streamOpportunityApplications(
      String opportunityId) {
    return _firestore
        .collection('opportunity_applications')
        .where('opportunityId', isEqualTo: opportunityId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OpportunityApplication.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<void> updateApplicationStatus(
      String applicationId, String status) async {
    await _firestore
        .collection('opportunity_applications')
        .doc(applicationId)
        .update({'status': status});
  }
}
