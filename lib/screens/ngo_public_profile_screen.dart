import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../services/ngo_registration_service.dart';

class NgoPublicProfileScreen extends StatefulWidget {
  final NgoRegistrationRequest ngoData;
  final bool isEditable;

  const NgoPublicProfileScreen({
    Key? key,
    required this.ngoData,
    this.isEditable = false,
  }) : super(key: key);

  @override
  State<NgoPublicProfileScreen> createState() => _NgoPublicProfileScreenState();
}

class _NgoPublicProfileScreenState extends State<NgoPublicProfileScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  late TextEditingController _descriptionController;
  List<String> _photos = [];
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String? _logoUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.ngoData.missionVision.isNotEmpty 
          ? widget.ngoData.missionVision 
          : '',
    );
    _logoUrl = widget.ngoData.profileImageUrl;
    _loadNgoPublicData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadNgoPublicData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ngo_registrations')
          .doc(widget.ngoData.id)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _photos = List<String>.from(data['publicPhotos'] ?? []);
          _reviews = List<Map<String, dynamic>>.from(data['reviews'] ?? []);
          if (data['publicDescription'] != null) {
            _descriptionController.text = data['publicDescription'];
          }
          if (data['ngoLogo'] != null) {
            _logoUrl = data['ngoLogo'];
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading public data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    try {
      setState(() => _isUploading = true);
      
      await FirebaseFirestore.instance
          .collection('ngo_registrations')
          .doc(widget.ngoData.id)
          .update({
        'publicDescription': _descriptionController.text,
        'publicPhotos': _photos,
        'ngoLogo': _logoUrl,
      });

      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving changes: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadLogo() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final file = File(image.path);
      final fileName = 'ngo_logos/${widget.ngoData.id}_logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      setState(() {
        _logoUrl = downloadUrl;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logo uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error uploading logo: $e');
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading logo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final file = File(image.path);
      final fileName = 'ngo_photos/${widget.ngoData.id}_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      setState(() {
        _photos.add(downloadUrl);
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ngoName = widget.ngoData.ngoName;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'NGO Details',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: widget.isEditable
            ? [
                TextButton(
                  onPressed: _isUploading ? null : _saveChanges,
                  child: _isUploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primary,
                          ),
                        )
                      : Text(
                          'Save',
                          style: TextStyle(
                            color: primary, 
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // NGO Name with underline
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          ngoName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primary,
                            decoration: TextDecoration.underline,
                            decorationColor: primary,
                          ),
                        ),
                      ),

                      // NGO Logo/Banner
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // NGO Logo
                            GestureDetector(
                              onTap: widget.isEditable ? _pickAndUploadLogo : null,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: primary.withOpacity(0.5), 
                                    width: 1.5,
                                  ),
                                ),
                                child: _logoUrl != null && _logoUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          _logoUrl!,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                                strokeWidth: 2,
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.add_photo_alternate, size: 30, color: primary),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Add Logo',
                                                  style: TextStyle(fontSize: 11, color: primary),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate,
                                            size: 30,
                                            color: primary,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Add Logo',
                                            style: TextStyle(fontSize: 11, color: primary),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ngoName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Towards Self-Reliance',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description Section
                      _buildSectionTitle('Description', showEdit: widget.isEditable),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: widget.isEditable
                              ? TextField(
                                  controller: _descriptionController,
                                  maxLines: 5,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter description about your NGO...',
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    height: 1.5,
                                  ),
                                )
                              : Text(
                                  _descriptionController.text.isNotEmpty
                                      ? _descriptionController.text
                                      : widget.ngoData.missionVision.isNotEmpty
                                          ? widget.ngoData.missionVision
                                          : 'No description available',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    height: 1.5,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Photos Section - Horizontal Scrollable
                      _buildSectionTitle('Photos', showEdit: widget.isEditable),
                      SizedBox(
                        height: 70,
                        child: Row(
                          children: [
                            Expanded(
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                children: [
                                  // Add Photo Button (first if editable)
                                  if (widget.isEditable)
                                    GestureDetector(
                                      onTap: _pickAndUploadPhoto,
                                      child: Container(
                                        width: 65,
                                        height: 65,
                                        margin: const EdgeInsets.only(right: 10),
                                        decoration: BoxDecoration(
                                          color: primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: primary.withOpacity(0.5)),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_photo_alternate, color: primary, size: 24),
                                            const SizedBox(height: 2),
                                            Text('Add', style: TextStyle(fontSize: 10, color: primary)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  // Existing photos
                                  ..._photos.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final photoUrl = entry.value;
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 65,
                                          height: 65,
                                          margin: const EdgeInsets.only(right: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            image: DecorationImage(
                                              image: NetworkImage(photoUrl),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        if (widget.isEditable)
                                          Positioned(
                                            top: -5,
                                            right: 5,
                                            child: GestureDetector(
                                              onTap: () => _removePhoto(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(3),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  }).toList(),
                                  // Placeholder images if no photos
                                  if (_photos.isEmpty && !widget.isEditable)
                                    ...List.generate(6, (index) => Container(
                                      width: 65,
                                      height: 65,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.image, color: Colors.grey.shade400, size: 24),
                                    )),
                                ],
                              ),
                            ),
                            // Arrow indicator for scrolling
                            if (_photos.length > 4 || (!widget.isEditable && _photos.isEmpty))
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Reviews Section
                      _buildSectionTitle('Reviews'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            ...List.generate(5, (index) {
                              return Icon(
                                index < 4 ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 24,
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Comments Section
                      _buildSectionTitle('Comments'),
                      _buildCommentItem(
                        'User',
                        'Good and healthy work environment...',
                        4,
                      ),
                      _buildCommentItem(
                        'Volunteer',
                        'This was a brilliant experience. And I learned more there Thanks',
                        5,
                      ),
                      if (_reviews.isNotEmpty)
                        ..._reviews.map((review) => _buildCommentItem(
                              review['userName'] ?? 'User',
                              review['comment'] ?? '',
                              review['rating'] ?? 5,
                            )),

                      // Bottom padding for buttons
                      SizedBox(height: widget.isEditable ? 30 : 100),
                    ],
                  ),
                ),
                // Action Buttons for Volunteers (fixed at bottom)
                if (!widget.isEditable)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _joinAsVolunteer(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Join as a volunteer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _viewActivities(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primary,
                                side: BorderSide(color: primary, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'NGOs Activities',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Loading overlay
                if (_isUploading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title, {bool showEdit = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          if (showEdit)
            Icon(Icons.edit, size: 18, color: primary),
        ],
      ),
    );
  }

  Widget _buildCommentItem(String user, String comment, int rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primary.withOpacity(0.2),
            child: Icon(Icons.person, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 14,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _joinAsVolunteer(BuildContext context) {
    final volunteeringController = TextEditingController();
    final locationController = TextEditingController();
    final experienceController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Join as Volunteer',
          style: TextStyle(color: primary, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Fill in your details to send a volunteer request',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: volunteeringController,
                decoration: InputDecoration(
                  labelText: 'Volunteering For',
                  hintText: 'e.g., Teaching children',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Your Location',
                  hintText: 'e.g., Delhi, India',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: experienceController,
                decoration: InputDecoration(
                  labelText: 'Experience',
                  hintText: 'e.g., 2 years',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (volunteeringController.text.isEmpty ||
                  locationController.text.isEmpty ||
                  experienceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please login to send request'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Check if request already exists
                final existingRequest = await FirebaseFirestore.instance
                    .collection('volunteer_requests')
                    .where('ngoId', isEqualTo: widget.ngoData.id)
                    .where('volunteerId', isEqualTo: user.uid)
                    .get();

                if (existingRequest.docs.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You have already sent a request to this NGO'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Save request to Firestore
                await FirebaseFirestore.instance.collection('volunteer_requests').add({
                  'ngoId': widget.ngoData.id,
                  'ngoName': widget.ngoData.ngoName,
                  'volunteerId': user.uid,
                  'volunteerName': user.displayName ?? 'Volunteer',
                  'volunteerEmail': user.email,
                  'volunteerPhotoUrl': user.photoURL,
                  'volunteeringFor': volunteeringController.text.trim(),
                  'location': locationController.text.trim(),
                  'experience': experienceController.text.trim(),
                  'status': 'pending',
                  'requestedAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Volunteer request sent successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error sending request: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primary),
            child: const Text('Send Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _viewActivities(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('NGO Activities - Coming Soon!')),
    );
  }
}
