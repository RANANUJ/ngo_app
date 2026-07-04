import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ngo_app/features/ngo/data/services/ngo_registration_service.dart';
import 'package:ngo_app/screens/impact/impact_detail_screen.dart';

class ShareImpactScreen extends StatefulWidget {
  final NgoRegistrationRequest ngoData;

  const ShareImpactScreen({Key? key, required this.ngoData}) : super(key: key);

  @override
  State<ShareImpactScreen> createState() => _ShareImpactScreenState();
}

class _ShareImpactScreenState extends State<ShareImpactScreen> {
  static const Color primary = Color(0xFF0099B8);

  @override
  void initState() {
    super.initState();
    _addSampleImpactsIfNeeded();
  }

  Future<void> _addSampleImpactsIfNeeded() async {
    try {
      // Check if impacts already exist for this NGO
      final existing = await FirebaseFirestore.instance
          .collection('impact_stories')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .limit(1)
          .get();
      
      if (existing.docs.isNotEmpty) return; // Already has impacts
      
      // Sample impact stories data
      final sampleImpacts = [
        {
          'title': '500 Children Educated This Year',
          'description': 'Through our education program, we successfully enrolled 500 underprivileged children in schools across 15 villages. We provided them with books, uniforms, and school supplies. Our teachers conducted regular classes and mentoring sessions.',
          'beneficiaries': 500,
          'category': 'Education',
        },
        {
          'title': 'Clean Water for 3 Villages',
          'description': 'Installed water purification systems in 3 remote villages, providing clean drinking water to over 2,000 residents. The project included training local communities on maintenance and water conservation practices.',
          'beneficiaries': 2000,
          'category': 'Healthcare',
        },
        {
          'title': 'Women Empowerment Workshop',
          'description': 'Conducted skill development workshops for 150 women, teaching them tailoring, handicrafts, and small business management. 80% of participants have started their own small businesses.',
          'beneficiaries': 150,
          'category': 'Livelihood',
        },
        {
          'title': 'Free Health Camp Success',
          'description': 'Organized a week-long free health camp providing medical check-ups, medicines, and health awareness to 1,200 people. Specialists included general physicians, eye doctors, and dentists.',
          'beneficiaries': 1200,
          'category': 'Healthcare',
        },
        {
          'title': 'Tree Plantation Drive',
          'description': 'Planted 5,000 trees across the district with help from local schools and community volunteers. This initiative will help combat climate change and improve air quality in urban areas.',
          'beneficiaries': 10000,
          'category': 'Environment',
        },
        {
          'title': 'Food Distribution During Crisis',
          'description': 'Distributed food packages to 800 families affected by recent floods. Each package contained rice, dal, oil, and essential groceries to sustain a family for two weeks.',
          'beneficiaries': 3200,
          'category': 'Food',
        },
        {
          'title': 'Digital Literacy Program',
          'description': 'Trained 200 youth in basic computer skills, internet usage, and online job applications. 60 participants secured jobs in IT and BPO sectors within 3 months of completion.',
          'beneficiaries': 200,
          'category': 'Education',
        },
        {
          'title': 'Senior Citizens Support',
          'description': 'Provided monthly ration kits and medical assistance to 100 abandoned senior citizens. Regular health check-ups and companionship visits improved their quality of life significantly.',
          'beneficiaries': 100,
          'category': 'Elderly Care',
        },
      ];
      
      // Add each impact story
      for (var i = 0; i < sampleImpacts.length; i++) {
        await FirebaseFirestore.instance.collection('impact_stories').add({
          'ngoId': widget.ngoData.id,
          'ngoName': widget.ngoData.ngoName,
          'ngoLogo': widget.ngoData.profileImageUrl,
          'title': sampleImpacts[i]['title'],
          'description': sampleImpacts[i]['description'],
          'beneficiaries': sampleImpacts[i]['beneficiaries'],
          'category': sampleImpacts[i]['category'],
          'images': <String>[],
          'donationsReceived': (i + 1) * 5000,
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(days: i * 5))),
        });
      }
      
      debugPrint('Added ${sampleImpacts.length} sample impact stories');
    } catch (e) {
      debugPrint('Error adding sample impacts: $e');
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
            'Share Impact',
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
              Tab(text: 'Our Impacts'),
              Tab(text: 'Create Impact'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildImpactsList(),
            _CreateImpactForm(ngoData: widget.ngoData),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('impact_stories')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error loading impacts: ${snapshot.error}');
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

        // Sort by createdAt descending
        var docs = snapshot.data?.docs ?? [];
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
                Icon(Icons.insights, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No impact stories yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your achievements with donors',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
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
            return _buildImpactCard(data, docs[index].id);
          },
        );
      },
    );
  }

  Widget _buildImpactCard(Map<String, dynamic> data, String docId) {
    final title = data['title'] ?? 'Impact Story';
    final description = data['description'] ?? '';
    final beneficiaries = data['beneficiaries'] ?? 0;
    final category = data['category'] ?? 'General';
    final createdAt = data['createdAt'] as Timestamp?;
    final images = List<String>.from(data['images'] ?? []);

    String dateStr = '';
    if (createdAt != null) {
      final date = createdAt.toDate();
      dateStr = '${date.day}/${date.month}/${date.year}';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImpactDetailScreen(
              data: data,
              docId: docId,
              currentNgoId: widget.ngoData.id,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  images.first,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 48, color: Colors.grey),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: primary),
                      const SizedBox(width: 8),
                      Text(
                        '$beneficiaries',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Beneficiaries Impacted',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteImpact(docId),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImpactDetailScreen(
                                data: data,
                                docId: docId,
                                currentNgoId: widget.ngoData.id,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.volunteer_activism, size: 18, color: Colors.white),
                        label: const Text('Donate', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _deleteImpact(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Impact Story'),
        content: const Text('Are you sure you want to delete this impact story?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('impact_stories').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impact story deleted'), backgroundColor: Colors.green),
        );
      }
    }
  }
}

class _CreateImpactForm extends StatefulWidget {
  final NgoRegistrationRequest ngoData;

  const _CreateImpactForm({Key? key, required this.ngoData}) : super(key: key);

  @override
  State<_CreateImpactForm> createState() => _CreateImpactFormState();
}

class _CreateImpactFormState extends State<_CreateImpactForm> {
  static const Color primary = Color(0xFF0099B8);
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _beneficiariesController = TextEditingController();
  
  String _category = 'Education';
  bool _isLoading = false;
  List<File> _selectedImages = [];

  final List<String> _categories = [
    'Education',
    'Healthcare',
    'Food & Nutrition',
    'Environment',
    'Women Empowerment',
    'Child Welfare',
    'Disaster Relief',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _beneficiariesController.dispose();
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

  Future<void> _createImpact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      List<String> imageUrls = [];
      for (var image in _selectedImages) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('impact_stories')
            .child('${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}.jpg');
        await ref.putFile(image);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      await FirebaseFirestore.instance.collection('impact_stories').add({
        'ngoId': widget.ngoData.id,
        'ngoName': widget.ngoData.ngoName,
        'ngoLogo': widget.ngoData.profileImageUrl,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'beneficiaries': int.tryParse(_beneficiariesController.text) ?? 0,
        'category': _category,
        'images': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impact story created!'), backgroundColor: Colors.green),
        );
        
        _titleController.clear();
        _descriptionController.clear();
        _beneficiariesController.clear();
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
            _buildLabel('Impact Title'),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('e.g., 500 children educated'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            _buildLabel('Description'),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration('Describe your impact story'),
              maxLines: 4,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Beneficiaries'),
                      TextFormField(
                        controller: _beneficiariesController,
                        decoration: _inputDecoration('Number'),
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
                        isExpanded: true,
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
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
                onPressed: _isLoading ? null : _createImpact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Share Impact Story', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
