import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ngo_app/features/profile/domain/models/user_profile.dart';
import 'package:ngo_app/features/profile/presentation/controllers/profile_controller.dart';

class UsernameSetupScreen extends StatefulWidget {
  final String userId;
  final String userType;
  final Map<String, dynamic> existingData;

  const UsernameSetupScreen({
    Key? key,
    required this.userId,
    required this.userType,
    required this.existingData,
  }) : super(key: key);

  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen> {
  static const Color primary = Color(0xFF0099B8);
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  File? _selectedImage;
  String? _currentPhotoUrl;
  bool _isUploadingImage = false;
  bool _isSaving = false;
  
  bool? _isUsernameUnique;
  bool _isValidatingUsername = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.existingData['ngoName'] ?? 
                           widget.existingData['displayName'] ?? 
                           widget.existingData['name'] ?? '';
    _bioController.text = widget.existingData['bio'] ?? 
                          widget.existingData['missionVision'] ?? '';
    _cityController.text = widget.existingData['city'] ?? '';
    _stateController.text = widget.existingData['state'] ?? '';
    _currentPhotoUrl = widget.existingData['photoUrl'] ?? 
                       widget.existingData['ngoLogo'] ?? 
                       widget.existingData['profileImageUrl'];
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    final cleanVal = value.trim().toLowerCase();
    if (cleanVal.isEmpty) {
      setState(() {
        _isUsernameUnique = null;
        _isValidatingUsername = false;
      });
      return;
    }

    setState(() {
      _isValidatingUsername = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      final controller = context.read<ProfileController>();
      final isUnique = await controller.isUsernameUnique(cleanVal, widget.userId);
      if (mounted) {
        setState(() {
          _isUsernameUnique = isUnique;
          _isValidatingUsername = false;
        });
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_selectedImage == null) return _currentPhotoUrl;

    setState(() => _isUploadingImage = true);
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${widget.userId}.jpg');

      final uploadTask = storageRef.putFile(_selectedImage!);
      await uploadTask;
      final url = await storageRef.getDownloadURL();
      setState(() => _isUploadingImage = false);
      return url;
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      setState(() => _isUploadingImage = false);
      return null;
    }
  }

  Future<void> _submitSetup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUsernameUnique != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a valid unique username')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final photoUrl = await _uploadProfileImage();

      final updatedProfile = UserProfile(
        id: widget.userId,
        name: _nameController.text.trim(),
        type: widget.userType,
        photoUrl: photoUrl,
        bio: _bioController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        phone: widget.existingData['phone'] ?? widget.existingData['mobileNo'] ?? '',
        email: widget.existingData['email'] ?? '',
        username: _usernameController.text.trim().toLowerCase(),
      );

      final success = await context.read<ProfileController>().updateProfile(updatedProfile);
      
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile setup completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save profile details')),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                // Heading
                Text(
                  widget.userType == 'ngo' ? 'Setup NGO Profile' : 'Setup Community Profile',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a unique username and complete your profile to access the community and feed sections.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Profile Image Picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary,
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: Colors.white,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                                  ? NetworkImage(_currentPhotoUrl!) as ImageProvider
                                  : null),
                          child: _selectedImage == null && (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty)
                              ? Icon(
                                  widget.userType == 'ngo' ? Icons.business : Icons.person,
                                  size: 56,
                                  color: Colors.grey.shade400,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form Fields Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Username Text Field with status checking
                      TextFormField(
                        controller: _usernameController,
                        onChanged: _onUsernameChanged,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          hintText: 'e.g. child_hope_ngo',
                          prefixText: '@',
                          prefixStyle: const TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primary, width: 2),
                          ),
                          suffixIcon: _isValidatingUsername
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                                  ),
                                )
                              : (_isUsernameUnique != null
                                  ? Icon(
                                      _isUsernameUnique! ? Icons.check_circle : Icons.error,
                                      color: _isUsernameUnique! ? Colors.green : Colors.red,
                                    )
                                  : null),
                          helperText: _isUsernameUnique == true
                              ? 'Username is available'
                              : (_isUsernameUnique == false ? 'Username is already taken' : null),
                          helperStyle: TextStyle(
                            color: _isUsernameUnique == true ? Colors.green : Colors.red,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Username is required';
                          if (value.trim().length < 3) return 'Must be at least 3 characters';
                          if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(value)) {
                            return 'Letters, numbers, underscores and dots only';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Display Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: widget.userType == 'ngo' ? 'NGO Name' : 'Display Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Location Details
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: InputDecoration(
                                labelText: 'City',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'City is required';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _stateController,
                              decoration: InputDecoration(
                                labelText: 'State',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'State is required';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Bio
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: widget.userType == 'ngo' ? 'Mission & Vision' : 'Bio',
                          hintText: 'Tell the community about yourself...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Bio/Mission is required';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_isSaving || _isUploadingImage) ? null : _submitSetup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isSaving || _isUploadingImage
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save & Enter Community',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
