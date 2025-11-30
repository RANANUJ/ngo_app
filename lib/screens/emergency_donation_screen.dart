import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/ngo_registration_service.dart';
import 'location_picker_screen.dart';
import 'emergency_detail_screen.dart';

class EmergencyDonationScreen extends StatefulWidget {
  final NgoRegistrationRequest ngoData;

  const EmergencyDonationScreen({Key? key, required this.ngoData}) : super(key: key);

  @override
  State<EmergencyDonationScreen> createState() => _EmergencyDonationScreenState();
}

class _EmergencyDonationScreenState extends State<EmergencyDonationScreen> {
  static const Color primary = Color(0xFF0099B8);
  static const Color emergencyRed = Color(0xFFE53935);

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
            icon: const Icon(Icons.arrow_back, color: emergencyRed),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emergency, color: emergencyRed, size: 24),
              SizedBox(width: 8),
              Text(
                'Emergency',
                style: TextStyle(
                  color: emergencyRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: emergencyRed,
            unselectedLabelColor: Colors.grey,
            indicatorColor: emergencyRed,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Active Emergencies'),
              Tab(text: 'Create Emergency'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildActiveEmergencies(),
            _CreateEmergencyTab(ngoData: widget.ngoData),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveEmergencies() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emergency_donations')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error loading emergencies: ${snapshot.error}');
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
          return const Center(child: CircularProgressIndicator(color: emergencyRed));
        }

        // Filter active emergencies and sort by createdAt
        var docs = snapshot.data?.docs ?? [];
        docs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'active';
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
                Icon(Icons.emergency, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No active emergencies',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create an emergency appeal when urgent help is needed',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
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
            return _buildEmergencyCard(data, docs[index].id);
          },
        );
      },
    );
  }

  Widget _buildEmergencyCard(Map<String, dynamic> data, String docId) {
    final title = data['title'] ?? 'Emergency';
    final description = data['description'] ?? '';
    final targetAmount = (data['targetAmount'] ?? 0).toDouble();
    final collectedAmount = (data['collectedAmount'] ?? 0).toDouble();
    final createdAt = data['createdAt'] as Timestamp?;
    final images = List<String>.from(data['images'] ?? []);
    
    final progress = targetAmount > 0 ? (collectedAmount / targetAmount) : 0.0;
    
    String timeAgo = 'Recently';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt.toDate());
      if (diff.inDays > 0) {
        timeAgo = '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours}h ago';
      } else {
        timeAgo = '${diff.inMinutes}m ago';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmergencyDetailScreen(
              data: data,
              docId: docId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: emergencyRed.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: emergencyRed.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (images.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                images.first,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
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
                // Emergency badge and time
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: emergencyRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'URGENT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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
                const SizedBox(height: 8),
                
                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
                // Progress
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${collectedAmount.toStringAsFixed(0)} raised',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: emergencyRed,
                          ),
                        ),
                        Text(
                          'of ₹${targetAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(emergencyRed),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _closeEmergency(docId),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EmergencyDetailScreen(
                                data: data,
                                docId: docId,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: emergencyRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Donate', style: TextStyle(color: Colors.white)),
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

  Future<void> _closeEmergency(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Emergency'),
        content: const Text('Are you sure you want to close this emergency appeal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: emergencyRed),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('emergency_donations')
          .doc(docId)
          .update({
        'status': 'closed',
        'closedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency appeal closed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _shareEmergency(Map<String, dynamic> data) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        backgroundColor: primary,
      ),
    );
  }
}

class _CreateEmergencyTab extends StatefulWidget {
  final NgoRegistrationRequest ngoData;

  const _CreateEmergencyTab({Key? key, required this.ngoData}) : super(key: key);

  @override
  State<_CreateEmergencyTab> createState() => _CreateEmergencyTabState();
}

class _CreateEmergencyTabState extends State<_CreateEmergencyTab> {
  static const Color primary = Color(0xFF0099B8);
  static const Color emergencyRed = Color(0xFFE53935);
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _locationController = TextEditingController();
  
  bool _isLoading = false;
  List<File> _selectedImages = [];
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _locationController.dispose();
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

  void _openLocationPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          initialAddress: _locationController.text,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _locationController.text = result['address'] ?? '';
        _latitude = result['latitude'];
        _longitude = result['longitude'];
      });
    }
  }

  Future<void> _createEmergency() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload images
      List<String> imageUrls = [];
      for (var image in _selectedImages) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('emergency_donations')
            .child('${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}.jpg');
        await ref.putFile(image);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // Create emergency
      await FirebaseFirestore.instance.collection('emergency_donations').add({
        'ngoId': widget.ngoData.id,
        'ngoName': widget.ngoData.ngoName,
        'ngoLogo': widget.ngoData.profileImageUrl,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'targetAmount': double.tryParse(_targetAmountController.text) ?? 0,
        'collectedAmount': 0,
        'location': _locationController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'images': imageUrls,
        'status': 'active',
        'donorsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency appeal created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _targetAmountController.clear();
        _locationController.clear();
        setState(() {
          _selectedImages.clear();
          _latitude = null;
          _longitude = null;
        });
        
        // Switch to active emergencies tab
        DefaultTabController.of(context).animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
            // Warning banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: emergencyRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: emergencyRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: emergencyRed),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Emergency appeals are for urgent and critical situations only. Use responsibly.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Title
            _buildLabel('Emergency Title'),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('e.g., Urgent flood relief needed'),
              validator: (v) => v?.isEmpty ?? true ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Description
            _buildLabel('Description'),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration('Describe the emergency situation'),
              maxLines: 4,
              validator: (v) => v?.isEmpty ?? true ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),

            // Target Amount
            _buildLabel('Target Amount (₹)'),
            TextFormField(
              controller: _targetAmountController,
              decoration: _inputDecoration('Enter amount needed'),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Amount is required' : null,
            ),
            const SizedBox(height: 16),

            // Location
            _buildLabel('Location'),
            TextFormField(
              controller: _locationController,
              decoration: _inputDecoration('Select emergency location').copyWith(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.location_on, color: emergencyRed),
                  onPressed: _openLocationPicker,
                ),
              ),
              readOnly: true,
              onTap: _openLocationPicker,
            ),
            const SizedBox(height: 16),

            // Images
            _buildLabel('Images (required)'),
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
                          image: DecorationImage(
                            image: FileImage(entry.value),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(entry.key);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
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
                      color: emergencyRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: emergencyRed.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.add_photo_alternate, color: emergencyRed, size: 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createEmergency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: emergencyRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emergency, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Create Emergency Appeal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: emergencyRed, width: 2),
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}
