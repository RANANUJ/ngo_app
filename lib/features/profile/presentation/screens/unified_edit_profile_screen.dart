import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ngo_app/features/profile/domain/models/user_profile.dart';
import 'package:ngo_app/features/profile/presentation/controllers/profile_controller.dart';

class UnifiedEditProfileScreen extends StatefulWidget {
  final UserProfile currentProfile;

  const UnifiedEditProfileScreen({
    Key? key,
    required this.currentProfile,
  }) : super(key: key);

  @override
  State<UnifiedEditProfileScreen> createState() => _UnifiedEditProfileScreenState();
}

class _UnifiedEditProfileScreenState extends State<UnifiedEditProfileScreen> {
  static const Color primary = Color(0xFF0099B8);
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;

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
    _nameController = TextEditingController(text: widget.currentProfile.name);
    _usernameController = TextEditingController(text: widget.currentProfile.username ?? '');
    _bioController = TextEditingController(text: widget.currentProfile.bio);
    _cityController = TextEditingController(text: widget.currentProfile.city);
    _stateController = TextEditingController(text: widget.currentProfile.state);
    _currentPhotoUrl = widget.currentProfile.photoUrl;

    if (widget.currentProfile.username != null) {
      _isUsernameUnique = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
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

    if (cleanVal == widget.currentProfile.username?.trim().toLowerCase()) {
      setState(() {
        _isUsernameUnique = true;
        _isValidatingUsername = false;
      });
      return;
    }

    setState(() {
      _isValidatingUsername = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      final controller = context.read<ProfileController>();
      final isUnique = await controller.isUsernameUnique(cleanVal, widget.currentProfile.id);
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
          .child('${widget.currentProfile.id}.jpg');

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

  Future<void> _saveChanges() async {
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
        id: widget.currentProfile.id,
        name: _nameController.text.trim(),
        type: widget.currentProfile.type,
        photoUrl: photoUrl,
        bio: _bioController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        phone: widget.currentProfile.phone,
        email: widget.currentProfile.email,
        username: _usernameController.text.trim().toLowerCase(),
      );

      final success = await context.read<ProfileController>().updateProfile(updatedProfile);

      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile details')),
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
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, size: 28),
            onPressed: (_isSaving || _isUploadingImage) ? null : _saveChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Photo
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
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                                ? NetworkImage(_currentPhotoUrl!) as ImageProvider
                                : null),
                        child: _selectedImage == null && (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty)
                            ? Icon(
                                widget.currentProfile.type == 'ngo' ? Icons.business : Icons.person,
                                size: 50,
                                color: Colors.grey.shade400,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Inputs Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Unique Username
                    TextFormField(
                      controller: _usernameController,
                      onChanged: _onUsernameChanged,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixText: '@',
                        prefixStyle: const TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                        labelText: widget.currentProfile.type == 'ngo' ? 'NGO Name' : 'Display Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Name is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Location
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

                    // Bio / Mission
                    TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: widget.currentProfile.type == 'ngo' ? 'Mission & Vision' : 'Bio',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Bio is required';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (_isSaving || _isUploadingImage)
                const Center(
                  child: CircularProgressIndicator(color: primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
