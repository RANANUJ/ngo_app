import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditCommunityScreen extends StatefulWidget {
  final String communityId;
  final Map<String, dynamic> communityData;

  const EditCommunityScreen({
    Key? key,
    required this.communityId,
    required this.communityData,
  }) : super(key: key);

  @override
  State<EditCommunityScreen> createState() => _EditCommunityScreenState();
}

class _EditCommunityScreenState extends State<EditCommunityScreen> {
  static const Color primary = Color(0xFF0099B8);
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final TextEditingController _ruleController = TextEditingController();

  File? _newCoverImage;
  File? _newProfileImage;
  String? _existingCoverUrl;
  String? _existingProfileUrl;
  late bool _isPublic;
  bool _isLoading = false;
  late List<String> _rules;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.communityData['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.communityData['description'] ?? '');
    _existingCoverUrl = widget.communityData['coverUrl'];
    _existingProfileUrl = widget.communityData['imageUrl'];
    _isPublic = widget.communityData['isPublic'] ?? true;
    _rules = List<String>.from(widget.communityData['rules'] ?? []);
  }

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
          _newCoverImage = File(pickedFile.path);
        } else {
          _newProfileImage = File(pickedFile.path);
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

  Future<void> _updateCommunity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? coverUrl = _existingCoverUrl;
      String? imageUrl = _existingProfileUrl;

      // Upload new images if selected
      if (_newCoverImage != null) {
        coverUrl = await _uploadImage(_newCoverImage!, 'covers');
      }
      if (_newProfileImage != null) {
        imageUrl = await _uploadImage(_newProfileImage!, 'profiles');
      }

      // Update community document
      await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .update({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'coverUrl': coverUrl ?? '',
        'imageUrl': imageUrl ?? '',
        'isPublic': _isPublic,
        'rules': _rules,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Community updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating community: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Community',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateCommunity,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              _buildCoverImageSection(),
              // Profile Image
              _buildProfileImageSection(),
              const SizedBox(height: 16),
              // Name
              _buildInputSection(
                'Community Name',
                _nameController,
                'Enter community name',
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              // Description
              _buildInputSection(
                'Description',
                _descriptionController,
                'What is this community about?',
                maxLines: 4,
              ),
              // Privacy Toggle
              _buildPrivacySection(),
              // Rules
              _buildRulesSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImageSection() {
    return GestureDetector(
      onTap: () => _pickImage(true),
      child: Container(
        height: 150,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: _newCoverImage != null
            ? Image.file(_newCoverImage!, fit: BoxFit.cover)
            : (_existingCoverUrl != null && _existingCoverUrl!.isNotEmpty)
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(_existingCoverUrl!, fit: BoxFit.cover),
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 40),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey.shade500),
                      const SizedBox(height: 8),
                      Text(
                        'Add Cover Photo',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Transform.translate(
      offset: const Offset(0, -40),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _pickImage(false),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _newProfileImage != null
                      ? Image.file(_newProfileImage!, fit: BoxFit.cover)
                      : (_existingProfileUrl != null && _existingProfileUrl!.isNotEmpty)
                          ? Image.network(_existingProfileUrl!, fit: BoxFit.cover)
                          : Container(
                              color: primary.withOpacity(0.1),
                              child: Icon(Icons.group, color: primary, size: 30),
                            ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Tap to change profile image',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Community Privacy',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          // Public Option
          GestureDetector(
            onTap: () => setState(() => _isPublic = true),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isPublic ? primary.withOpacity(0.1) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isPublic ? primary : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.public,
                    color: _isPublic ? primary : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Public',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _isPublic ? primary : Colors.black87,
                          ),
                        ),
                        Text(
                          'Anyone can find and join this community',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Radio(
                    value: true,
                    groupValue: _isPublic,
                    onChanged: (value) => setState(() => _isPublic = true),
                    activeColor: primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Private Option
          GestureDetector(
            onTap: () => setState(() => _isPublic = false),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: !_isPublic ? Colors.orange.withOpacity(0.1) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: !_isPublic ? Colors.orange : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock,
                    color: !_isPublic ? Colors.orange : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Private',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: !_isPublic ? Colors.orange : Colors.black87,
                          ),
                        ),
                        Text(
                          'Only invited members can join',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Radio(
                    value: false,
                    groupValue: _isPublic,
                    onChanged: (value) => setState(() => _isPublic = false),
                    activeColor: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Community Rules',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          // Existing Rules
          if (_rules.isNotEmpty) ...[
            ...List.generate(_rules.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      '${index + 1}.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_rules[index])),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                      onPressed: () => _removeRule(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
          // Add Rule Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ruleController,
                  decoration: InputDecoration(
                    hintText: 'Add a rule...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addRule,
                icon: Icon(Icons.add_circle, color: primary, size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
