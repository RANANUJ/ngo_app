import 'package:flutter/material.dart';
import '../../domain/models/campaign.dart';
import '../../domain/repositories/campaign_repository.dart';

class CampaignController extends ChangeNotifier {
  final CampaignRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;

  CampaignController(this._repository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Stream<List<Campaign>> streamAllCampaigns() {
    return _repository.streamAllCampaigns();
  }

  Stream<List<Campaign>> streamNgoCampaigns(String ngoId) {
    return _repository.streamNgoCampaigns(ngoId);
  }

  Stream<List<Campaign>> streamJoinedCampaigns(String userId) {
    return _repository.streamJoinedCampaigns(userId);
  }

  Future<Campaign> getCampaignById(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final campaign = await _repository.getCampaignById(id);
      _isLoading = false;
      notifyListeners();
      return campaign;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<String> createCampaign(Campaign campaign) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = await _repository.createCampaign(campaign);
      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCampaign(Campaign campaign) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateCampaign(campaign);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCampaign(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteCampaign(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> joinCampaign(String campaignId, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.joinCampaign(campaignId, userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> hasJoinedCampaign(String campaignId, String userId) async {
    try {
      return await _repository.hasJoinedCampaign(campaignId, userId);
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}
