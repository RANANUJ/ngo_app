import '../models/campaign.dart';

abstract class CampaignRepository {
  Stream<List<Campaign>> streamAllCampaigns();
  Stream<List<Campaign>> streamNgoCampaigns(String ngoId);
  Future<Campaign> getCampaignById(String id);
  Future<String> createCampaign(Campaign campaign);
  Future<void> updateCampaign(Campaign campaign);
  Future<void> deleteCampaign(String id);
  Future<void> joinCampaign(String campaignId, String userId);
  Future<bool> hasJoinedCampaign(String campaignId, String userId);
  Stream<List<Campaign>> streamJoinedCampaigns(String userId);
}
