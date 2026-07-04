import 'package:flutter/material.dart';
import '../../domain/models/opportunity.dart';
import '../../domain/models/opportunity_application.dart';
import '../../domain/repositories/opportunity_repository.dart';

class OpportunityController extends ChangeNotifier {
  final OpportunityRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;

  OpportunityController(this._repository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Stream<List<Opportunity>> streamAllOpportunities() {
    return _repository.streamAllOpportunities();
  }

  Stream<List<Opportunity>> streamNgoOpportunities(String ngoId) {
    return _repository.streamNgoOpportunities(ngoId);
  }

  Stream<List<Opportunity>> streamAppliedOpportunities(String volunteerId) {
    return _repository.streamAppliedOpportunities(volunteerId);
  }

  Stream<List<OpportunityApplication>> streamOpportunityApplications(String opportunityId) {
    return _repository.streamOpportunityApplications(opportunityId);
  }

  Future<Opportunity> getOpportunityById(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final opportunity = await _repository.getOpportunityById(id);
      _isLoading = false;
      notifyListeners();
      return opportunity;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<String> createOpportunity(Opportunity opportunity) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = await _repository.createOpportunity(opportunity);
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

  Future<void> updateOpportunity(Opportunity opportunity) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateOpportunity(opportunity);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteOpportunity(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteOpportunity(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> applyForOpportunity(OpportunityApplication application) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.applyForOpportunity(application);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> hasAppliedForOpportunity(String opportunityId, String volunteerId) async {
    try {
      return await _repository.hasAppliedForOpportunity(opportunityId, volunteerId);
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<void> updateApplicationStatus(String applicationId, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateApplicationStatus(applicationId, status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
