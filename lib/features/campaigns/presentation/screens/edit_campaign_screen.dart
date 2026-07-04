import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:ngo_app/screens/common/location_picker_screen.dart';
import '../../domain/models/campaign.dart';
import '../controllers/campaign_controller.dart';

class EditCampaignScreen extends StatefulWidget {
  final String campaignId;
  final Map<String, dynamic> campaignData;

  const EditCampaignScreen({
    Key? key,
    required this.campaignId,
    required this.campaignData,
  }) : super(key: key);

  @override
  State<EditCampaignScreen> createState() => _EditCampaignScreenState();
}

class _EditCampaignScreenState extends State<EditCampaignScreen> {
  static const Color primary = Color(0xFF0099B8);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  final _purposeController = TextEditingController();
  final _targetController = TextEditingController();

  final List<File> _newImages = [];
  List<String> _existingImages = [];
  List<String> _purposes = [];
  List<String> _targets = [];

  DateTime? _selectedDate;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.campaignData['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.campaignData['description'] ?? '');
    _locationController = TextEditingController(text: widget.campaignData['location'] ?? '');
    _existingImages = List<String>.from(widget.campaignData['images'] ?? []);
    _purposes = List<String>.from(widget.campaignData['purpose'] ?? []);
    _targets = List<String>.from(widget.campaignData['target'] ?? []);
    _latitude = widget.campaignData['latitude'] as double?;
    _longitude = widget.campaignData['longitude'] as double?;

    final eventDate = widget.campaignData['eventDate'];
    if (eventDate != null) {
      if (eventDate is DateTime) {
        _selectedDate = eventDate;
      } else {
        // Fallback for firestore Timestamp
        try {
          _selectedDate = (eventDate as dynamic).toDate();
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
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

  Future<List<String>> _uploadNewImages() async {
    List<String> imageUrls = [];
    final ngoId = widget.campaignData['ngoId'] ?? 'unknown_ngo';

    for (int i = 0; i < _newImages.length; i++) {
      final file = _newImages[i];
      final fileName = 'campaigns/$ngoId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }

    return imageUrls;
  }

  Future<void> _updateCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    if (_existingImages.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
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

      final campaign = Campaign(
        id: widget.campaignId,
        ngoId: widget.campaignData['ngoId'] ?? '',
        ngoName: widget.campaignData['ngoName'] ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: widget.campaignData['category'] ?? 'General',
        status: widget.campaignData['status'] ?? 'active',
        isActive: widget.campaignData['isActive'] ?? true,
        targetAmount: (widget.campaignData['targetAmount'] ?? 0).toDouble(),
        raisedAmount: (widget.campaignData['raisedAmount'] ?? 0).toDouble(),
        participantsCount: widget.campaignData['participants'] ?? 0,
        images: allImages,
        location: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        eventDate: _selectedDate,
        purpose: _purposes,
        target: _targets,
        createdAt: widget.campaignData['createdAt'] is DateTime
            ? widget.campaignData['createdAt']
            : null,
      );

      final controller = Provider.of<CampaignController>(context, listen: false);
      await controller.updateCampaign(campaign);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campaign updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating campaign: $e')),
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
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Campaign',
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
              _buildSectionTitle('Campaign Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Enter campaign title'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter campaign title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              _buildSectionTitle('Campaign Images'),
              const SizedBox(height: 8),
              _buildImagePicker(),

              const SizedBox(height: 24),

              _buildSectionTitle('Event Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
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
                    setState(() => _selectedDate = date);
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
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Select event date',
                        style: TextStyle(
                          color: _selectedDate != null ? Colors.black87 : Colors.grey.shade400,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _buildSectionTitle('Event Location'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Enter location address').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(Icons.location_on, color: primary),
                    onPressed: _openLocationPicker,
                  ),
                ),
              ),
              if (_latitude != null && _longitude != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Location coordinates saved',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ),
                      GestureDetector(
                        onTap: _previewLocation,
                        child: Text(
                          'Preview on Map',
                          style: TextStyle(
                            color: primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              _buildSectionTitle('Short Description of Campaign'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('Enter campaign description'),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter campaign description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              _buildSectionTitle('Purpose / Goal of Campaign'),
              const SizedBox(height: 8),
              _buildAddItemField(
                controller: _purposeController,
                hint: 'Add a purpose/goal',
                onAdd: _addPurpose,
              ),
              const SizedBox(height: 8),
              _buildItemList(_purposes, _removePurpose),

              const SizedBox(height: 24),

              _buildSectionTitle('Target'),
              const SizedBox(height: 8),
              _buildAddItemField(
                controller: _targetController,
                hint: 'Add a target audience',
                onAdd: _addTarget,
              ),
              const SizedBox(height: 8),
              _buildItemList(_targets, _removeTarget),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateCampaign,
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
                          'Save Changes',
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
        fontSize: 18,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_existingImages.isNotEmpty || _newImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._existingImages.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            entry.value,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeExistingImage(entry.key),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                ..._newImages.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            entry.value,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeNewImage(entry.key),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

        const SizedBox(height: 12),

        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primary.withValues(alpha: 0.5),
                style: BorderStyle.solid,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.add_photo_alternate_outlined, color: primary, size: 40),
                const SizedBox(height: 8),
                Text(
                  'Add Campaign Images',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddItemField({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: _inputDecoration(hint),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildItemList(List<String> items, Function(int) onRemove) {
    if (items.isEmpty) return const SizedBox();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.asMap().entries.map((entry) {
        return Chip(
          label: Text(entry.value),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () => onRemove(entry.key),
          backgroundColor: primary.withValues(alpha: 0.1),
          labelStyle: TextStyle(color: primary),
          deleteIconColor: primary,
        );
      }).toList(),
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

  void _previewLocation() async {
    if (_latitude == null || _longitude == null) return;

    final url = 'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }
}
