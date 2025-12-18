import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'location_picker_screen.dart';

class EditOpportunityScreen extends StatefulWidget {
  final String opportunityId;
  final Map<String, dynamic> opportunityData;

  const EditOpportunityScreen({
    Key? key,
    required this.opportunityId,
    required this.opportunityData,
  }) : super(key: key);

  @override
  State<EditOpportunityScreen> createState() => _EditOpportunityScreenState();
}

class _EditOpportunityScreenState extends State<EditOpportunityScreen> {
  static const Color primary = Color(0xFF0099B8);
  
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _timeController;
  late TextEditingController _volunteersNeededController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _contactEmailController;
  final _purposeController = TextEditingController();
  final _targetController = TextEditingController();
  
  final List<File> _newImages = [];
  List<String> _existingImages = [];
  List<String> _purposes = [];
  List<String> _targets = [];
  
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
  void initState() {
    super.initState();
    final data = widget.opportunityData;
    
    _titleController = TextEditingController(text: data['title'] ?? '');
    _descriptionController = TextEditingController(text: data['description'] ?? '');
    _locationController = TextEditingController(text: data['location'] ?? '');
    _timeController = TextEditingController(text: data['time'] ?? '');
    _volunteersNeededController = TextEditingController(text: (data['volunteersNeeded'] ?? '').toString());
    _contactPhoneController = TextEditingController(text: data['contactPhone'] ?? '');
    _contactEmailController = TextEditingController(text: data['contactEmail'] ?? '');
    
    _existingImages = List<String>.from(data['images'] ?? []);
    _purposes = List<String>.from(data['purpose'] ?? []);
    _targets = List<String>.from(data['target'] ?? []);
    _selectedCause = data['cause'] ?? '';
    _latitude = data['latitude']?.toDouble();
    _longitude = data['longitude']?.toDouble();
    
    final eventDateData = data['eventDate'];
    if (eventDateData != null && eventDateData is Timestamp) {
      _eventDate = eventDateData.toDate();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    _volunteersNeededController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _purposeController.dispose();
    _targetController.dispose();
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
          _newImages.addAll(images.map((img) => File(img.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
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

  Future<List<String>> _uploadNewImages() async {
    List<String> imageUrls = [];
    final ngoId = widget.opportunityData['ngoId'];
    
    for (int i = 0; i < _newImages.length; i++) {
      final file = _newImages[i];
      final fileName = 'opportunities/$ngoId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }
    
    return imageUrls;
  }

  Future<void> _updateOpportunity() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_existingImages.isEmpty && _newImages.isEmpty) {
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
      // Upload new images
      final newImageUrls = await _uploadNewImages();
      
      // Combine existing and new images
      final allImages = [..._existingImages, ...newImageUrls];
      
      // Update opportunity document
      await FirebaseFirestore.instance
          .collection('volunteer_opportunities')
          .doc(widget.opportunityId)
          .update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'cause': _selectedCause,
        'location': _locationController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'time': _timeController.text.trim(),
        'eventDate': _eventDate != null ? Timestamp.fromDate(_eventDate!) : null,
        'volunteersNeeded': int.tryParse(_volunteersNeededController.text) ?? 0,
        'images': allImages,
        'purpose': _purposes,
        'target': _targets,
        'contactPhone': _contactPhoneController.text.trim(),
        'contactEmail': _contactEmailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opportunity updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating opportunity: $e')),
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
          'Edit Opportunity',
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
              _buildImageSection(),
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
                        'Location coordinates: $_latitude, $_longitude',
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

              // Target Audience
              _buildSectionTitle('Target Audience'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetController,
                      decoration: _inputDecoration('Add target audience'),
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

              // Contact Phone
              _buildSectionTitle('Contact Phone'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactPhoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Enter contact phone'),
              ),
              const SizedBox(height: 16),

              // Contact Email
              _buildSectionTitle('Contact Email'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Enter contact email'),
              ),
              const SizedBox(height: 32),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateOpportunity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Update Opportunity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.grey.shade50,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildImageSection() {
    return SizedBox(
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
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, color: primary, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    'Add Image',
                    style: TextStyle(color: primary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          // Existing images
          ..._existingImages.asMap().entries.map((entry) {
            return Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(entry.value),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => _removeExistingImage(entry.key),
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
          // New images
          ..._newImages.asMap().entries.map((entry) {
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
                    onTap: () => _removeNewImage(entry.key),
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
    );
  }
}
