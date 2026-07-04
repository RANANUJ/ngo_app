import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/models/resource.dart';
import '../../domain/models/resource_request.dart';
import '../../domain/repositories/resource_repository.dart';

class ResourceController extends ChangeNotifier {
  final ResourceRepository _repository;

  bool _isLoading = false;
  String? _error;

  ResourceController(this._repository);

  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<Resource>> streamAvailableResources({String? category}) {
    return _repository.streamAvailableResources(category: category);
  }

  Stream<Resource> streamResourceDetails(String resourceId) {
    return _repository.streamResourceDetails(resourceId);
  }

  Future<bool> shareResource({
    required String title,
    required String description,
    required int quantity,
    required String category,
    required String ngoId,
    required String ngoName,
    required List<File> imageFiles,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final resource = Resource(
        id: '',
        title: title,
        description: description,
        quantity: quantity,
        category: category,
        ngoId: ngoId,
        ngoName: ngoName,
        images: [],
        status: 'available',
        createdAt: DateTime.now(),
      );
      await _repository.shareResource(resource, imageFiles);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteResource(String resourceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteResource(resourceId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleResourceStatus(String resourceId, String currentStatus) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newStatus = currentStatus == 'available' ? 'unavailable' : 'available';
      await _repository.updateResourceStatus(resourceId, newStatus);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitRequest({
    required String resourceId,
    String? resourceName,
    String? requestingNgoId,
    String? ownerNgoId,
    String? requesterId,
    String? requesterEmail,
    required int quantity,
    String? purpose,
    required String message,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = ResourceRequest(
        id: '',
        resourceId: resourceId,
        resourceName: resourceName,
        requestingNgoId: requestingNgoId,
        ownerNgoId: ownerNgoId,
        requesterId: requesterId,
        requesterEmail: requesterEmail,
        quantity: quantity,
        purpose: purpose,
        message: message,
        status: 'pending',
        createdAt: DateTime.now(),
      );
      await _repository.submitResourceRequest(request);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> seedSampleResourcesIfNeeded(String ngoId, String ngoName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.seedSampleResourcesIfNeeded(ngoId, ngoName);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
