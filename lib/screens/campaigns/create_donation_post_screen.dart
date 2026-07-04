import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ngo_app/features/ngo/data/services/ngo_registration_service.dart';
import 'package:ngo_app/screens/common/location_picker_screen.dart';

class CreateDonationPostScreen extends StatefulWidget {
  final NgoRegistrationRequest ngoData;

  const CreateDonationPostScreen({Key? key, required this.ngoData}) : super(key: key);

  @override
  State<CreateDonationPostScreen> createState() => _CreateDonationPostScreenState();
}

class _CreateDonationPostScreenState extends State<CreateDonationPostScreen> {
  static const Color primary = Color(0xFF0099B8);
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _locationController = TextEditingController();
  
  DateTime? _dueDate;
  String _category = 'General';
  String _urgencyLevel = 'Normal';
  bool _isLoading = false;
  List<File> _selectedImages = [];
  double? _latitude;
  double? _longitude;

  final List<String> _categories = [
    'General',
    'Food',
    'Education',
    'Healthcare',
    'Clothing',
    'Shelter',
    'Emergency',
    'Environment',
    'Animal Welfare',
    'Other',
  ];

  final List<String> _urgencyLevels = [
    'Low',
    'Normal',
    'High',
    'Critical',
  ];

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

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      setState(() => _dueDate = date);
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

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a due date'),
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
            .child('donation_posts')
            .child('${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}.jpg');
        await ref.putFile(image);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // Create donation post
      await FirebaseFirestore.instance.collection('donation_posts').add({
        'ngoId': widget.ngoData.id,
        'ngoName': widget.ngoData.ngoName,
        'ngoLogo': widget.ngoData.profileImageUrl,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'targetAmount': double.tryParse(_targetAmountController.text) ?? 0,
        'collectedAmount': 0,
        'category': _category,
        'urgencyLevel': _urgencyLevel,
        'location': _locationController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'dueDate': Timestamp.fromDate(_dueDate!),
        'images': imageUrls,
        'status': 'active',
        'donorsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Donation Post',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              _buildLabel('Title'),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Enter donation post title'),
                validator: (v) => v?.isEmpty ?? true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              _buildLabel('Description'),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('Describe your donation needs'),
                maxLines: 4,
                validator: (v) => v?.isEmpty ?? true ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              // Target Amount
              _buildLabel('Target Amount (₹)'),
              TextFormField(
                controller: _targetAmountController,
                decoration: _inputDecoration('Enter target amount'),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Amount is required' : null,
              ),
              const SizedBox(height: 16),

              // Category
              _buildLabel('Category'),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: _inputDecoration('Select category'),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),

              // Urgency Level
              _buildLabel('Urgency Level'),
              Row(
                children: _urgencyLevels.map((level) {
                  final isSelected = _urgencyLevel == level;
                  Color chipColor;
                  switch (level) {
                    case 'Low':
                      chipColor = Colors.green;
                      break;
                    case 'Normal':
                      chipColor = primary;
                      break;
                    case 'High':
                      chipColor = Colors.orange;
                      break;
                    case 'Critical':
                      chipColor = Colors.red;
                      break;
                    default:
                      chipColor = primary;
                  }
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(level),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _urgencyLevel = level);
                        },
                        backgroundColor: Colors.grey.shade100,
                        selectedColor: chipColor.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? chipColor : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Location
              _buildLabel('Location'),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Select location').copyWith(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.location_on, color: primary),
                    onPressed: _openLocationPicker,
                  ),
                ),
                readOnly: true,
                onTap: _openLocationPicker,
              ),
              const SizedBox(height: 16),

              // Due Date
              _buildLabel('Due Date'),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Text(
                        _dueDate != null
                            ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                            : 'Select due date',
                        style: TextStyle(
                          color: _dueDate != null ? Colors.black87 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Images
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
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      ),
                      child: Icon(Icons.add_photo_alternate, color: Colors.grey.shade500, size: 32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
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
                      : const Text(
                          'Create Post',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
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
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}
