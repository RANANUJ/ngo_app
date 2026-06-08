import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ngo_app/screens/common/location_picker_screen.dart';

class CreateOpportunityScreen extends StatefulWidget {
  final String ngoId;
  final String ngoName;

  const CreateOpportunityScreen({
    Key? key,
    required this.ngoId,
    required this.ngoName,
  }) : super(key: key);

  @override
  State<CreateOpportunityScreen> createState() => _CreateOpportunityScreenState();
}

class _CreateOpportunityScreenState extends State<CreateOpportunityScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _timeController = TextEditingController();
  final _volunteersNeededController = TextEditingController();
  final _purposeController = TextEditingController();
  final _targetController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  
  final List<File> _selectedImages = [];
  final List<String> _purposes = [];
  final List<String> _targets = [];
  
  String _selectedCause = '';
  double? _latitude;
  double? _longitude;
  DateTime? _eventDate;
  
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  
  final List<String> _causeOptions = [
    'Education', 'Healthcare', 'Environment', 'Child Welfare',
    'Women Empowerment', 'Animal Welfare', 'Elderly Care',
    'Disability Support', 'Poverty Alleviation', 'Disaster Relief',
    'Community Development', 'Food Distribution', 'Teaching slum kids', 'Other'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    _volunteersNeededController.dispose();
    _purposeController.dispose();
    _targetController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((img) => File(img.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _addPurpose() {
    if (_purposeController.text.trim().isNotEmpty) {
      setState(() {
        _purposes.add(_purposeController.text.trim());
        _purposeController.clear();
      });
    }
  }

  void _removePurpose(int index) {
    setState(() {
      _purposes.removeAt(index);
    });
  }

  void _addTarget() {
    if (_targetController.text.trim().isNotEmpty) {
      setState(() {
        _targets.add(_targetController.text.trim());
        _targetController.clear();
      });
    }
  }

  void _removeTarget(int index) {
    setState(() {
      _targets.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    
    for (int i = 0; i < _selectedImages.length; i++) {
      final file = _selectedImages[i];
      final fileName = 'opportunities/${widget.ngoId}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }
    
    return imageUrls;
  }

  Future<void> _postOpportunity() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }
    
    if (_selectedCause.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a cause')),
      );
      return;
    }
    
    if (_purposes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one purpose')),
      );
      return;
    }
    
    if (_targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one target')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload images
      final imageUrls = await _uploadImages();
      
      // Create opportunity document
      await FirebaseFirestore.instance.collection('volunteer_opportunities').add({
        'ngoId': widget.ngoId,
        'ngoName': widget.ngoName,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'cause': _selectedCause,
        'location': _locationController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'time': _timeController.text.trim(),
        'eventDate': _eventDate != null ? Timestamp.fromDate(_eventDate!) : null,
        'volunteersNeeded': int.tryParse(_volunteersNeededController.text) ?? 0,
        'images': imageUrls,
        'purpose': _purposes,
        'target': _targets,
        'contactPhone': _contactPhoneController.text.trim(),
        'contactEmail': _contactEmailController.text.trim(),
        'applicationsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Volunteer opportunity posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting opportunity: $e')),
      );
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
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Opportunity',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
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
              // Images Section
              _buildSectionTitle('Images'),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Add Image button
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, color: primary, size: 32),
                            const SizedBox(height: 4),
                            Text(
                              'Add Image',
                              style: TextStyle(
                                color: primary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Selected images
                    ..._selectedImages.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(entry.value),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => _removeImage(entry.key),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              _buildSectionTitle('Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Enter opportunity title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              _buildSectionTitle('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _inputDecoration('Enter a brief description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Cause
              _buildSectionTitle('Cause'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedCause.isEmpty ? null : _selectedCause,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: Text('Select cause', style: TextStyle(color: Colors.grey.shade400)),
                  items: _causeOptions.map((cause) => DropdownMenuItem(
                    value: cause,
                    child: Text(cause),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCause = value ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Location
              _buildSectionTitle('Location'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Enter location address').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(Icons.location_on, color: primary),
                    onPressed: _openLocationPicker,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              if (_latitude != null && _longitude != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Location coordinates saved',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Event Date
              _buildSectionTitle('Event Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _eventDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(primary: primary),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    setState(() => _eventDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _eventDate != null
                            ? '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'
                            : 'Select event date',
                        style: TextStyle(
                          color: _eventDate != null ? Colors.black87 : Colors.grey.shade400,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Time
              _buildSectionTitle('Time'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _timeController,
                decoration: _inputDecoration('e.g., 10am to 12pm'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Volunteers Needed
              _buildSectionTitle('Volunteers Needed'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _volunteersNeededController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Enter number of volunteers needed'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of volunteers';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Purpose / Goals
              _buildSectionTitle('Purpose / Goals'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purposeController,
                      decoration: _inputDecoration('Add a purpose'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addPurpose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _purposes.asMap().entries.map((entry) {
                  return Chip(
                    label: Text(entry.value),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removePurpose(entry.key),
                    backgroundColor: primary.withOpacity(0.1),
                    labelStyle: TextStyle(color: primary),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Target
              _buildSectionTitle('Target Audience'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetController,
                      decoration: _inputDecoration('Add a target audience'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addTarget,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _targets.asMap().entries.map((entry) {
                  return Chip(
                    label: Text(entry.value),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeTarget(entry.key),
                    backgroundColor: primary.withOpacity(0.1),
                    labelStyle: TextStyle(color: primary),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Contact Information
              _buildSectionTitle('Contact Information'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactPhoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Contact Phone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Contact Email'),
              ),
              const SizedBox(height: 24),

              // Post Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _postOpportunity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Post Opportunity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location selected successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
