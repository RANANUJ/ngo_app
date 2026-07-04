import 'dart:io';
import '../models/resource.dart';
import '../models/resource_request.dart';

abstract class ResourceRepository {
  Stream<List<Resource>> streamAvailableResources({String? category});
  Stream<Resource> streamResourceDetails(String resourceId);
  Future<void> shareResource(Resource resource, List<File> imageFiles);
  Future<void> deleteResource(String resourceId);
  Future<void> updateResourceStatus(String resourceId, String status);
  Future<void> submitResourceRequest(ResourceRequest request);
  Future<void> seedSampleResourcesIfNeeded(String ngoId, String ngoName);
}
