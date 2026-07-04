import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controllers/community_controller.dart';

class CreateCommunityScreen extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? userPhoto;
  final String userType;

  const CreateCommunityScreen({
    Key? key,
    this.userId,
    this.userName,
    this.userPhoto,
    required this.userType,
  }) : super(key: key);

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  static const Color primary = Color(0xFF0099B8);
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ruleController = TextEditingController();
  
  File? _coverImage;
  File? _profileImage;
  bool _isPublic = true;
  bool _isLoading = false;
  final List<String> _rules = [];
  String _selectedCategory = 'Environment';
  final List<String> _categories = [
    'Environment',
    'Health',
    'Education',
    'Social Help',
    'Animals',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _ruleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isCover) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: isCover ? 1200 : 500,
      maxHeight: isCover ? 600 : 500,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        if (isCover) {
          _coverImage = File(pickedFile.path);
        } else {
          _profileImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<String?> _uploadImage(File file, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('community_images')
          .child(folder)
          .child(fileName);

      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _addRule() {
    if (_ruleController.text.trim().isNotEmpty) {
      setState(() {
        _rules.add(_ruleController.text.trim());
        _ruleController.clear();
      });
    }
  }

  void _removeRule(int index) {
    setState(() {
      _rules.removeAt(index);
    });
  }

  Future<void> _createCommunity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      String? coverUrl;
      String? imageUrl;

      // Upload images
      if (_coverImage != null) {
        coverUrl = await _uploadImage(_coverImage!, 'covers');
      }
      if (_profileImage != null) {
        imageUrl = await _uploadImage(_profileImage!, 'profiles');
      }

      final controller = context.read<CommunityController>();

      final success = await controller.createCommunity(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        creatorId: userId,
        creatorName: widget.userName ?? 'User',
        creatorLogo: widget.userPhoto ?? '',
        imageUrl: imageUrl ?? '',
        coverUrl: coverUrl ?? '',
        rules: _rules,
        isPublic: _isPublic,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Community created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${controller.error ?? 'Unknown error'}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating community: $e')),
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Community',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              GestureDetector(
                onTap: () => _pickImage(true),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    image: _coverImage != null
                        ? DecorationImage(
                            image: FileImage(_coverImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _coverImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 40, color: Colors.grey.shade500),
                            const SizedBox(height: 8),
                            Text(
                              'Add Cover Photo',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              // Profile Image
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _pickImage(false),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          image: _profileImage != null
                              ? DecorationImage(
                                  image: FileImage(_profileImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _profileImage == null
                            ? Icon(Icons.add_a_photo,
                                color: Colors.grey.shade500)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Community Photo',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to upload a profile image',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Form Fields
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    const Text(
                      'Community Name *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter community name',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a community name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Description
                    const Text(
                      'Description *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'What is this community about?',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Privacy
                    const Text(
                      'Privacy',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isPublic = true),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _isPublic
                                    ? primary.withValues(alpha: 0.1)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: _isPublic
                                    ? Border.all(color: primary, width: 2)
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.public,
                                    color: _isPublic ? primary : Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Public',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _isPublic ? primary : Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Anyone can join',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isPublic = false),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: !_isPublic
                                    ? primary.withValues(alpha: 0.1)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: !_isPublic
                                    ? Border.all(color: primary, width: 2)
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.lock,
                                    color: !_isPublic ? primary : Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Private',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: !_isPublic ? primary : Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Approval needed',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Category
                    const Text(
                      'Category *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: primary),
                          items: _categories.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCategory = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Rules
                    const Text(
                      'Community Rules (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ruleController,
                            decoration: InputDecoration(
                              hintText: 'Add a rule',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addRule,
                          icon: Icon(Icons.add_circle, color: primary, size: 30),
                        ),
                      ],
                    ),
                    if (_rules.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...List.generate(_rules.length, (index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: primary.withValues(alpha: 0.2),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _rules[index],
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.grey.shade600, size: 18),
                                onPressed: () => _removeRule(index),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _createCommunity,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Create Community',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
