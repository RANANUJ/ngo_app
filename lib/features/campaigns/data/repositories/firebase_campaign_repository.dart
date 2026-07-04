import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/campaign.dart';
import '../../domain/repositories/campaign_repository.dart';

class FirebaseCampaignRepository implements CampaignRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Campaign>> streamAllCampaigns() {
    return _firestore
        .collection('campaigns')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Campaign.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<List<Campaign>> streamNgoCampaigns(String ngoId) {
    return _firestore
        .collection('campaigns')
        .where('ngoId', isEqualTo: ngoId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Campaign.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<Campaign> getCampaignById(String id) async {
    final doc = await _firestore.collection('campaigns').doc(id).get();
    if (!doc.exists) {
      throw Exception('Campaign not found');
    }
    return Campaign.fromMap(doc.id, doc.data()!);
  }

  @override
  Future<String> createCampaign(Campaign campaign) async {
    final ref = await _firestore.collection('campaigns').add(campaign.toMap());
    return ref.id;
  }

  @override
  Future<void> updateCampaign(Campaign campaign) async {
    await _firestore
        .collection('campaigns')
        .doc(campaign.id)
        .update(campaign.toMap());
  }

  @override
  Future<void> deleteCampaign(String id) async {
    await _firestore.collection('campaigns').doc(id).delete();
  }

  @override
  Future<void> joinCampaign(String campaignId, String userId) async {
    final docId = '${campaignId}_$userId';
    await _firestore.collection('campaign_participants').doc(docId).set({
      'campaignId': campaignId,
      'userId': userId,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // Update participant count in campaigns collection
    await _firestore.collection('campaigns').doc(campaignId).update({
      'participants': FieldValue.increment(1),
    });
  }

  @override
  Future<bool> hasJoinedCampaign(String campaignId, String userId) async {
    final doc = await _firestore
        .collection('campaign_participants')
        .doc('${campaignId}_$userId')
        .get();
    return doc.exists;
  }

  @override
  Stream<List<Campaign>> streamJoinedCampaigns(String userId) {
    return _firestore
        .collection('campaign_participants')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final campaignIds =
          snapshot.docs.map((doc) => doc['campaignId'] as String).toList();
      if (campaignIds.isEmpty) return <Campaign>[];

      final List<Campaign> campaigns = [];
      // Fetch in chunks of 10 (Firestore limit for whereIn)
      for (var i = 0; i < campaignIds.length; i += 10) {
        final chunk = campaignIds.sublist(
            i, i + 10 > campaignIds.length ? campaignIds.length : i + 10);
        final campaignSnapshots = await _firestore
            .collection('campaigns')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (var doc in campaignSnapshots.docs) {
          campaigns.add(Campaign.fromMap(doc.id, doc.data()));
        }
      }
      return campaigns;
    });
  }
}
