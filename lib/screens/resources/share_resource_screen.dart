import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ngo_app/features/ngo/data/services/ngo_registration_service.dart';
import 'package:ngo_app/screens/resources/resource_detail_screen.dart';

class ShareResourceScreen extends StatefulWidget {
  final NgoRegistrationRequest ngoData;

  const ShareResourceScreen({Key? key, required this.ngoData}) : super(key: key);

  @override
  State<ShareResourceScreen> createState() => _ShareResourceScreenState();
}

class _ShareResourceScreenState extends State<ShareResourceScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  @override
  void initState() {
    super.initState();
    _addSampleResourcesIfNeeded();
  }
  
  Future<void> _addSampleResourcesIfNeeded() async {
    try {
      // Check if resources already exist for this NGO
      final existing = await FirebaseFirestore.instance
          .collection('shared_resources')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .limit(1)
          .get();
      
      if (existing.docs.isNotEmpty) return; // Already has resources
      
      // Sample resources data
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
      
      // Add each resource
      for (var i = 0; i < sampleResources.length; i++) {
        await FirebaseFirestore.instance.collection('shared_resources').add({
          'ngoId': widget.ngoData.id,
          'ngoName': widget.ngoData.ngoName,
          'title': sampleResources[i]['title'],
          'description': sampleResources[i]['description'],
          'quantity': sampleResources[i]['quantity'],
          'category': sampleResources[i]['category'],
          'images': <String>[],
          'status': 'available',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(days: i))),
        });
      }
      
      debugPrint('Added ${sampleResources.length} sample resources');
    } catch (e) {
      debugPrint('Error adding sample resources: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: primary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Share Resource',
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primary,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Available Resources'),
              Tab(text: 'Share New'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildResourcesList(),
            _ShareResourceForm(ngoData: widget.ngoData),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shared_resources')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error loading resources: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text('Error loading data', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }

        // Filter available resources and sort by createdAt
        var docs = snapshot.data?.docs ?? [];
        docs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'available';
        }).toList();
        
        // Sort by createdAt descending
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No shared resources yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildResourceCard(data, docs[index].id);
          },
        );
      },
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> data, String docId) {
    final title = data['title'] ?? 'Resource';
    final description = data['description'] ?? '';
    final quantity = data['quantity'] ?? 0;
    final category = data['category'] ?? 'Other';
    final ngoName = data['ngoName'] ?? '';
    final isOwnResource = data['ngoId'] == widget.ngoData.id;
    final createdAt = data['createdAt'] as Timestamp?;
    
    String timeAgo = '';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt.toDate());
      if (diff.inDays > 0) {
        timeAgo = '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours}h ago';
      } else {
        timeAgo = 'Just now';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResourceDetailScreen(
              data: data,
              docId: docId,
              currentNgoId: widget.ngoData.id,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Qty: $quantity',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            
            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            
            // Footer
            Row(
              children: [
                Icon(Icons.business, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  ngoName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                const SizedBox(width: 8),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const Spacer(),
                if (isOwnResource)
                  Text(
                    'Your Resource',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareResourceForm extends StatefulWidget {
  final NgoRegistrationRequest ngoData;

  const _ShareResourceForm({Key? key, required this.ngoData}) : super(key: key);

  @override
  State<_ShareResourceForm> createState() => _ShareResourceFormState();
}

class _ShareResourceFormState extends State<_ShareResourceForm> {
  static const Color primary = Color(0xFF0099B8);
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  
  String _category = 'Food';
  bool _isLoading = false;
  List<File> _selectedImages = [];

  final List<String> _categories = [
    'Food',
    'Clothing',
    'Medicine',
    'Books',
    'Electronics',
    'Furniture',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((e) => File(e.path)));
      });
    }
  }

  Future<void> _shareResource() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      List<String> imageUrls = [];
      for (var image in _selectedImages) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('shared_resources')
            .child('${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}.jpg');
        await ref.putFile(image);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      await FirebaseFirestore.instance.collection('shared_resources').add({
        'ngoId': widget.ngoData.id,
        'ngoName': widget.ngoData.ngoName,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'quantity': int.tryParse(_quantityController.text) ?? 1,
        'category': _category,
        'images': imageUrls,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resource shared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        _titleController.clear();
        _descriptionController.clear();
        _quantityController.clear();
        setState(() => _selectedImages.clear());
        
        DefaultTabController.of(context).animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Resource Title'),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('e.g., Winter Clothes'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            _buildLabel('Description'),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration('Describe the resource'),
              maxLines: 3,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Quantity'),
                      TextFormField(
                        controller: _quantityController,
                        decoration: _inputDecoration('Qty'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Category'),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: _inputDecoration(''),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildLabel('Images'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._selectedImages.asMap().entries.map((entry) {
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(image: FileImage(entry.value), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImages.removeAt(entry.key)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Icon(Icons.add_photo_alternate, color: Colors.grey.shade500, size: 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _shareResource,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Share Resource', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 2)),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}
