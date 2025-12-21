import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/ngo_registration_service.dart';

class NgoEditProfileScreen extends StatefulWidget {
  final NgoRegistrationRequest ngoData;
  final VoidCallback? onProfileUpdated;

  const NgoEditProfileScreen({
    Key? key,
    required this.ngoData,
    this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<NgoEditProfileScreen> createState() => _NgoEditProfileScreenState();
}

class _NgoEditProfileScreenState extends State<NgoEditProfileScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isUploadingImage = false;
  File? _selectedImage;
  String? _currentLogoUrl;

  late TextEditingController _ngoNameController;
  late TextEditingController _registrationNoController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _yearEstablishedController;
  late TextEditingController _missionVisionController;
  late TextEditingController _websiteController;
  
  String _selectedNgoType = 'Trust';
  List<String> _selectedCategories = ['Education'];

  final List<String> _ngoTypes = ['Trust', 'Society', 'Section 8 Company', 'Other'];
  final List<String> _categories = [
    'Education',
    'Healthcare',
    'Environment',
    'Women Empowerment',
    'Child Welfare',
    'Animal Welfare',
    'Rural Development',
    'Disaster Relief',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadCurrentLogo();
  }

  void _initControllers() {
    _ngoNameController = TextEditingController(text: widget.ngoData.ngoName);
    _registrationNoController = TextEditingController(text: widget.ngoData.registrationNo);
    _phoneController = TextEditingController(text: widget.ngoData.mobileNo);
    _emailController = TextEditingController(text: widget.ngoData.email);
    _addressController = TextEditingController(text: widget.ngoData.headOfficeAddress);
    _yearEstablishedController = TextEditingController(text: widget.ngoData.yearOfEstablishment);
    _missionVisionController = TextEditingController(text: widget.ngoData.missionVision);
    _websiteController = TextEditingController(text: widget.ngoData.websiteLink);
    _selectedNgoType = widget.ngoData.ngoType.isNotEmpty ? widget.ngoData.ngoType : 'Trust';
    // Handle category as list or string for backward compatibility
    _initCategories();
  }

  void _initCategories() async {
    // Try to load categories from Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ngo_registrations')
          .doc(widget.ngoData.id)
          .get();
      
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null && data['categories'] != null && data['categories'] is List) {
          setState(() {
            _selectedCategories = List<String>.from(data['categories']);
          });
        } else if (widget.ngoData.category.isNotEmpty) {
          setState(() {
            _selectedCategories = [widget.ngoData.category];
          });
        }
      }
    } catch (e) {
      // Fallback to single category
      if (widget.ngoData.category.isNotEmpty) {
        setState(() {
          _selectedCategories = [widget.ngoData.category];
        });
      }
    }
  }

  Future<void> _loadCurrentLogo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ngo_registrations')
          .doc(widget.ngoData.id)
          .get();
      
      if (doc.exists && mounted) {
        setState(() {
          _currentLogoUrl = doc.data()?['ngoLogo'] ?? widget.ngoData.profileImageUrl;
        });
      }
    } catch (e) {
      debugPrint('Error loading logo: $e');
    }
  }

  @override
  void dispose() {
    _ngoNameController.dispose();
    _registrationNoController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _yearEstablishedController.dispose();
    _missionVisionController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<String?> _uploadLogo() async {
    if (_selectedImage == null) return _currentLogoUrl;

    try {
      setState(() => _isUploadingImage = true);

      final fileName = 'ngo_logos/${widget.ngoData.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      
      await ref.putFile(_selectedImage!);
      final downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading logo: $e');
      return null;
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate at least one category is selected
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? logoUrl = _currentLogoUrl;
      
      if (_selectedImage != null) {
        logoUrl = await _uploadLogo();
        if (logoUrl == null) {
          throw Exception('Failed to upload logo');
        }
      }

      await FirebaseFirestore.instance
          .collection('ngo_registrations')
          .doc(widget.ngoData.id)
          .update({
        'ngoName': _ngoNameController.text.trim(),
        'registrationNo': _registrationNoController.text.trim(),
        'mobileNo': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'headOfficeAddress': _addressController.text.trim(),
        'yearOfEstablishment': _yearEstablishedController.text.trim(),
        'missionVision': _missionVisionController.text.trim(),
        'websiteUrl': _websiteController.text.trim(),
        'ngoType': _selectedNgoType,
        'category': _selectedCategories.isNotEmpty ? _selectedCategories.first : '',
        'categories': _selectedCategories,
        if (logoUrl != null) 'ngoLogo': logoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      widget.onProfileUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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
          'Edit Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
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
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary.withOpacity(0.1),
                            border: Border.all(color: primary.withOpacity(0.3), width: 3),
                            image: _selectedImage != null
                                ? DecorationImage(
                                    image: FileImage(_selectedImage!),
                                    fit: BoxFit.cover,
                                  )
                                : (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty)
                                    ? DecorationImage(
                                        image: NetworkImage(_currentLogoUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          child: (_selectedImage == null && (_currentLogoUrl == null || _currentLogoUrl!.isEmpty))
                              ? Icon(Icons.business, size: 50, color: primary)
                              : null,
                        ),
                        if (_isUploadingImage)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black45,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to change logo',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Basic Information Section
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _ngoNameController,
                label: 'NGO Name',
                icon: Icons.business,
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _registrationNoController,
                label: 'Registration Number',
                icon: Icons.badge,
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'NGO Type',
                value: _selectedNgoType,
                items: _ngoTypes,
                onChanged: (value) => setState(() => _selectedNgoType = value!),
              ),
              const SizedBox(height: 16),
              _buildCategoryMultiSelect(),
              const SizedBox(height: 24),

              // Contact Information Section
              _buildSectionTitle('Contact Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Required';
                  if (!value!.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Head Office Address',
                icon: Icons.location_on,
                maxLines: 3,
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _websiteController,
                label: 'Website (optional)',
                icon: Icons.language,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),

              // Additional Information Section
              _buildSectionTitle('Additional Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _yearEstablishedController,
                label: 'Year of Establishment',
                icon: Icons.calendar_today,
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _missionVisionController,
                label: 'Mission & Vision',
                icon: Icons.flag,
                maxLines: 4,
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Change NGO Logo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(Icons.camera_alt, 'Camera', () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                }),
                _buildImageOption(Icons.photo_library, 'Gallery', () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                }),
                if (_selectedImage != null || (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty))
                  _buildImageOption(Icons.delete, 'Remove', () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _currentLogoUrl = null;
                    });
                  }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: icon == Icons.delete ? Colors.red.withOpacity(0.1) : primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: icon == Icons.delete ? Colors.red : primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primary),
        filled: true,
        fillColor: Colors.white,
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
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
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
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCategoryMultiSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Categories',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${_selectedCategories.length}/3 selected',
              style: TextStyle(
                fontSize: 12,
                color: _selectedCategories.length >= 3 ? Colors.orange : Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = _selectedCategories.contains(category);
              final canSelect = _selectedCategories.length < 3 || isSelected;
              
              return FilterChip(
                label: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : (canSelect ? Colors.grey.shade700 : Colors.grey.shade400),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: canSelect ? (selected) {
                  setState(() {
                    if (selected) {
                      if (_selectedCategories.length < 3) {
                        _selectedCategories.add(category);
                      }
                    } else {
                      _selectedCategories.remove(category);
                    }
                  });
                } : null,
                backgroundColor: canSelect ? Colors.grey.shade100 : Colors.grey.shade50,
                selectedColor: primary,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? primary : (canSelect ? Colors.grey.shade300 : Colors.grey.shade200),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              );
            }).toList(),
          ),
        ),
        if (_selectedCategories.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              'Please select at least one category',
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
          ),
        if (_selectedCategories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Select up to 3 categories that best describe your NGO',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
