import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/models/resource.dart';
import '../../domain/models/resource_request.dart';
import '../../domain/repositories/resource_repository.dart';

class FirebaseResourceRepository implements ResourceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Stream<List<Resource>> streamAvailableResources({String? category}) {
    Query query = _firestore
        .collection('shared_resources')
        .where('status', isEqualTo: 'available');

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Resource.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      
      // Sort by createdAt descending
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Stream<Resource> streamResourceDetails(String resourceId) {
    return _firestore
        .collection('shared_resources')
        .doc(resourceId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            throw Exception('Resource not found');
          }
          return Resource.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        });
  }

  @override
  Future<void> shareResource(Resource resource, List<File> imageFiles) async {
    final List<String> imageUrls = [];
    for (int i = 0; i < imageFiles.length; i++) {
      final ref = _storage
          .ref()
          .child('shared_resources')
          .child('${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
      await ref.putFile(imageFiles[i]);
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }

    final data = resource.toMap();
    // Convert DateTime string back to FieldValue.serverTimestamp() or Timestamp for Firestore
    data['createdAt'] = FieldValue.serverTimestamp();
    data['images'] = imageUrls;

    await _firestore.collection('shared_resources').add(data);
  }

  @override
  Future<void> deleteResource(String resourceId) async {
    await _firestore.collection('shared_resources').doc(resourceId).delete();
  }

  @override
  Future<void> updateResourceStatus(String resourceId, String status) async {
    await _firestore.collection('shared_resources').doc(resourceId).update({
      'status': status,
    });
  }

  @override
  Future<void> submitResourceRequest(ResourceRequest request) async {
    final data = request.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('resource_requests').add(data);
  }

  @override
  Future<void> seedSampleResourcesIfNeeded(String ngoId, String ngoName) async {
    final existing = await _firestore
        .collection('shared_resources')
        .where('ngoId', isEqualTo: ngoId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return; // Already has resources

    final sampleResources = [
      {
        'title': 'Winter Clothes Bundle',
        'description': 'A collection of warm winter clothes including jackets, sweaters, and blankets for those in need during the cold season.',
        'quantity': 50,
        'category': 'Clothing',
      },
      {
        'title': 'School Supplies Kit',
        'description': 'Educational supplies including notebooks, pens, pencils, geometry boxes, and school bags for underprivileged students.',
        'quantity': 100,
        'category': 'Education',
      },
      {
        'title': 'Food Grain Package',
        'description': 'Essential food grains including rice, wheat, dal, and cooking oil to support families in need.',
        'quantity': 75,
        'category': 'Food',
      },
      {
        'title': 'Medical First Aid Kits',
        'description': 'Complete first aid kits with bandages, antiseptics, basic medicines, and health essentials for community health camps.',
        'quantity': 30,
        'category': 'Medical',
      },
      {
        'title': 'Children\'s Books Collection',
        'description': 'Story books, educational books, and learning materials suitable for children aged 5-15 years.',
        'quantity': 200,
        'category': 'Education',
      },
      {
        'title': 'Hygiene Care Package',
        'description': 'Hygiene essentials including soap, sanitizers, toothpaste, toothbrush, and sanitary products.',
        'quantity': 120,
        'category': 'Hygiene',
      },
      {
        'title': 'Blankets for Shelter',
        'description': 'Warm blankets and bedding materials for homeless shelters and disaster relief.',
        'quantity': 80,
        'category': 'Shelter',
      },
      {
        'title': 'Cooking Utensils Set',
        'description': 'Basic cooking utensils including pots, pans, plates, and cups for community kitchens.',
        'quantity': 40,
        'category': 'Other',
      },
    ];

    for (var i = 0; i < sampleResources.length; i++) {
      await _firestore.collection('shared_resources').add({
        'ngoId': ngoId,
        'ngoName': ngoName,
        'title': sampleResources[i]['title'],
        'description': sampleResources[i]['description'],
        'quantity': sampleResources[i]['quantity'],
        'category': sampleResources[i]['category'],
        'images': <String>[],
        'status': 'available',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(days: i))),
      });
    }
  }
}
