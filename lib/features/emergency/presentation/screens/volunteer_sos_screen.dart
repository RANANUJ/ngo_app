import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/sos_alert.dart';
import '../../domain/models/emergency_contact.dart';
import '../../domain/repositories/sos_repository.dart';
import '../controllers/sos_controller.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/utils/network/network_utils.dart';
import 'package:ngo_app/shared/widgets/skeleton_loader.dart';

class VolunteerSOSScreen extends StatefulWidget {
  final String odid;
  final String odname;

  const VolunteerSOSScreen({
    Key? key,
    required this.odid,
    required this.odname,
  }) : super(key: key);

  @override
  State<VolunteerSOSScreen> createState() => _VolunteerSOSScreenState();
}

class _VolunteerSOSScreenState extends State<VolunteerSOSScreen> with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  static const Color sosRed = Color(0xFFE53935);

  late TabController _tabController;

  // Form Inputs
  String? _selectedEmergencyType;
  final TextEditingController _descriptionController = TextEditingController();
  File? _emergencyImage;
  final ImagePicker _imagePicker = ImagePicker();

  // NGO phone (for quick call / contact)
  String? _volunteerPhone;

  // Emergency Types Definitions
  final List<Map<String, dynamic>> _emergencyTypes = [
    {'type': 'Medical', 'icon': Icons.medical_services, 'image': 'assets/medical.png', 'color': Colors.red},
    {'type': 'Accident', 'icon': Icons.car_crash, 'image': 'assets/accident.png', 'color': Colors.orange},
    {'type': 'Fire', 'icon': Icons.local_fire_department, 'image': 'assets/firefighter.png', 'color': Colors.deepOrange},
    {'type': 'Natural Disaster', 'icon': Icons.flood, 'image': 'assets/disaster1.jpeg', 'color': Colors.blue},
    {'type': 'Personal Safety', 'icon': Icons.shield, 'image': 'assets/safety.jpg', 'color': Colors.purple},
    {'type': 'Other', 'icon': Icons.warning, 'image': null, 'color': Colors.grey},
  ];

  // Standard Helpline Contacts
  final List<Map<String, dynamic>> _emergencyContacts = [
    {'name': 'Police', 'number': '100', 'image': 'assets/police.jpg', 'color': Colors.blue},
    {'name': 'Ambulance', 'number': '108', 'image': 'assets/ambulance.png', 'color': Colors.red},
    {'name': 'Fire', 'number': '101', 'image': 'assets/fire.jpeg', 'color': Colors.orange},
    {'name': 'Women Helpline', 'number': '1091', 'image': 'assets/women hepline.png', 'color': Colors.pink},
    {'name': 'Child Helpline', 'number': '1098', 'image': 'assets/child.jpg', 'color': Colors.green},
    {'name': 'Disaster', 'number': '1078', 'image': 'assets/disaster.png', 'color': Colors.purple},
  ];

  final AnalyticsService _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _analytics.logScreenView('sos_screen', screenClass: 'VolunteerSOSScreen');

    // Trigger state loads inside controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<SosController>();
      controller.getCurrentLocation();
      controller.loadEmergencyContacts(widget.odid);
      _loadVolunteerPhone();
    });
  }

  Future<void> _loadVolunteerPhone() async {
    try {
      final phone = await context.read<SosRepository>().getVolunteerPhone(widget.odid);
      if (mounted) {
        setState(() {
          _volunteerPhone = phone;
        });
      }
    } catch (e) {
      debugPrint('Error loading volunteer phone: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: sosRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Emergency SOS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Send SOS', icon: Icon(Icons.sos, size: 20)),
            Tab(text: 'Quick Call', icon: Icon(Icons.phone, size: 20)),
            Tab(text: 'History', icon: Icon(Icons.history, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendSOSTab(),
          _buildQuickCallTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // =============== SEND SOS TAB ===============
  Widget _buildSendSOSTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSOSButton(),
          const SizedBox(height: 24),
          _buildLocationCard(),
          const SizedBox(height: 20),
          _buildEmergencyTypeSection(),
          const SizedBox(height: 20),
          _buildDescriptionSection(),
          const SizedBox(height: 20),
          _buildPhotoSection(),
          const SizedBox(height: 20),
          _buildSendAlertButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSOSButton() {
    return Consumer<SosController>(
      builder: (context, controller, child) {
        final active = controller.sosCountdownActive;
        final seconds = controller.countdownSeconds;

        return Center(
          child: GestureDetector(
            onLongPressStart: (_) {
              controller.startSosCountdown(
                volunteerId: widget.odid,
                volunteerName: widget.odname,
                onTriggered: _sendQuickSOS,
              );
            },
            onLongPressEnd: (_) {
              controller.cancelSosCountdown();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: active ? 180 : 160,
              height: active ? 180 : 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sosRed,
                boxShadow: [
                  BoxShadow(
                    color: sosRed.withValues(alpha: active ? 0.6 : 0.4),
                    blurRadius: active ? 30 : 20,
                    spreadRadius: active ? 10 : 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sos,
                    size: active ? 60 : 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    active ? '$seconds' : 'HOLD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: active ? 28 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!active)
                    const Text(
                      'for 5 sec',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendQuickSOS() async {
    try {
      final controller = context.read<SosController>();
      final newSosId = await controller.triggerQuickSos(
        volunteerId: widget.odid,
        volunteerName: widget.odname,
      );

      if (mounted && newSosId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('SOS Alert Sent! Help is on the way.'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send SOS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildLocationCard() {
    return Consumer<SosController>(
      builder: (context, controller, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Your Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => controller.getCurrentLocation(),
                    icon: Icon(
                      Icons.refresh,
                      color: controller.isLoadingLocation ? Colors.grey : primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (controller.isLoadingLocation)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.currentAddress,
                      style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                    ),
                    if (controller.currentPosition != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Coordinates: ${controller.currentPosition!.latitude.toStringAsFixed(6)}, ${controller.currentPosition!.longitude.toStringAsFixed(6)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmergencyTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _emergencyTypes.length,
          itemBuilder: (context, index) {
            final type = _emergencyTypes[index];
            final isSelected = _selectedEmergencyType == type['type'];

            return GestureDetector(
              onTap: () => setState(() => _selectedEmergencyType = type['type']),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? (type['color'] as Color).withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? type['color'] as Color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    type['image'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              type['image'] as String,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                type['icon'] as IconData,
                                color: type['color'] as Color,
                                size: 40,
                              ),
                            ),
                          )
                        : Icon(
                            type['icon'] as IconData,
                            color: type['color'] as Color,
                            size: 40,
                          ),
                    const SizedBox(height: 8),
                    Text(
                      type['type'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? type['color'] as Color : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Describe Emergency (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe details of the emergency e.g., number of people injured, severity...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            fillColor: Colors.white,
            filled: true,
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
              borderSide: const BorderSide(color: sosRed),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Photo (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _emergencyImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.file(
                          _emergencyImage!,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _emergencyImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Take photo of the situation',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _emergencyImage = File(pickedFile.path);
      });
    }
  }

  Widget _buildSendAlertButton() {
    return Consumer<SosController>(
      builder: (context, controller, child) {
        final loading = controller.isSendingSOS;

        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: loading ? null : _sendDetailedSOS,
            style: ElevatedButton.styleFrom(
              backgroundColor: sosRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'SEND EMERGENCY ALERT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _sendDetailedSOS() async {
    if (_selectedEmergencyType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an emergency type first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final controller = context.read<SosController>();
      final newSosId = await controller.triggerDetailedSos(
        volunteerId: widget.odid,
        volunteerName: widget.odname,
        type: _selectedEmergencyType!,
        description: _descriptionController.text.trim(),
        imageFile: _emergencyImage,
      );

      if (mounted && newSosId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency alert sent to all nearest NGOs!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form inputs
        setState(() {
          _selectedEmergencyType = null;
          _descriptionController.clear();
          _emergencyImage = null;
        });

        // Switch to history tab
        _tabController.animateTo(2);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send SOS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // =============== QUICK CALL TAB ===============
  Widget _buildQuickCallTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Official Emergency Helplines',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _emergencyContacts.length,
            itemBuilder: (context, index) {
              final contact = _emergencyContacts[index];
              return _buildHelplineCard(contact);
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Personal Safety Contacts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildPersonalContactsList(),
        ],
      ),
    );
  }

  Widget _buildHelplineCard(Map<String, dynamic> contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (contact['color'] as Color).withValues(alpha: 0.1),
            child: Icon(Icons.local_phone, color: contact['color'] as Color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  contact['number'] as String,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _makePhoneCall(contact['number'] as String),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalContactsList() {
    return Consumer<SosController>(
      builder: (context, controller, child) {
        if (controller.isLoadingContacts) {
          return const ListSkeleton(itemCount: 3, height: 50);
        }

        final contacts = controller.emergencyContacts;

        if (contacts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.contacts, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'No emergency contacts added',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add family or friends to contact in emergency',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddContactDialog(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Emergency Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sosRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            ...contacts.map((contact) => _buildPersonalContactCard(contact)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddContactDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Another Contact'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: sosRed,
                  side: BorderSide(color: sosRed.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPersonalContactCard(EmergencyContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: sosRed.withValues(alpha: 0.1),
            child: Text(
              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'C',
              style: const TextStyle(color: sosRed, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(contact.phone, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _makePhoneCall(contact.phone),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call, color: Colors.green, size: 20),
            ),
          ),
          IconButton(
            onPressed: () => _deleteEmergencyContact(contact),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEmergencyContact(EmergencyContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to remove ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final controller = context.read<SosController>();
        await controller.removeEmergencyContact(widget.odid, contact);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact removed')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove contact: $e')),
          );
        }
      }
    }
  }

  void _showAddContactDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Emergency Contact'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter phone' : null,
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
              if (formKey.currentState!.validate()) {
                try {
                  final controller = context.read<SosController>();
                  await controller.addEmergencyContact(
                    widget.odid,
                    nameController.text.trim(),
                    phoneController.text.trim(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Emergency contact added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add contact: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: sosRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Contact'),
          ),
        ],
      ),
    );
  }

  // =============== HISTORY TAB ===============
  Widget _buildHistoryTab() {
    final repository = context.read<SosRepository>();

    return StreamBuilder<List<SosAlert>>(
      stream: repository.streamVolunteerSosAlerts(widget.odid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListSkeleton(itemCount: 4, height: 75);
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final alerts = snapshot.data ?? [];

        if (alerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No SOS History',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your emergency alerts will appear here',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        // Sort descending locally by createdAt
        final sortedAlerts = List<SosAlert>.from(alerts);
        sortedAlerts.sort((a, b) {
          final aTime = a.createdAt ?? DateTime(1970);
          final bTime = b.createdAt ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });

        final limitedAlerts = sortedAlerts.take(20).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: limitedAlerts.length,
          itemBuilder: (context, index) {
            final alert = limitedAlerts[index];
            return _buildSOSHistoryCard(alert);
          },
        );
      },
    );
  }

  Widget _buildSOSHistoryCard(SosAlert alert) {
    final status = alert.status;
    final date = alert.createdAt;
    final respondingNgo = alert.respondingNgoName;
    final eta = alert.estimatedArrival;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'resolved':
        statusColor = Colors.green;
        statusText = 'Resolved';
        statusIcon = Icons.check_circle;
        break;
      case 'responding':
        statusColor = Colors.blue;
        statusText = 'Help Coming';
        statusIcon = Icons.directions_run;
        break;
      default:
        statusColor = sosRed;
        statusText = 'Active';
        statusIcon = Icons.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: status == 'responding' ? Border.all(color: Colors.blue, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.emergencyType,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (date != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(date),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Details or action buttons
          if (status == 'active') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelSOS(alert.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel SOS'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _markAsResolved(alert.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Resolve'),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (status == 'responding') ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.withValues(alpha: 0.05),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'NGO: ${respondingNgo ?? "Responding NGO"}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (eta != null)
                        Text(
                          'ETA: $eta mins',
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _makePhoneCall(alert.ngoPhone ?? ''),
                          icon: const Icon(Icons.call, size: 18),
                          label: const Text('Call NGO'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => _VolunteerLiveTrackingScreen(
                                  sosData: alert.toMap()..['id'] = alert.id,
                                  odid: widget.odid,
                                  odname: widget.odname,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text('Track Live'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _markAsResolved(String sosId) async {
    try {
      final controller = context.read<SosController>();
      await controller.resolveSosAlert(sosId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS marked as resolved'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resolving SOS: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelSOS(String sosId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel SOS'),
        content: const Text('Are you sure you want to cancel this SOS alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final controller = context.read<SosController>();
        await controller.cancelSosAlert(sosId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SOS cancelled')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error canceling SOS: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }
}

// Volunteer Live Tracking Screen
class _VolunteerLiveTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> sosData;
  final String odid;
  final String odname;

  const _VolunteerLiveTrackingScreen({
    required this.sosData,
    required this.odid,
    required this.odname,
  });

  @override
  State<_VolunteerLiveTrackingScreen> createState() => _VolunteerLiveTrackingScreenState();
}

class _VolunteerLiveTrackingScreenState extends State<_VolunteerLiveTrackingScreen> {
  static const Color primary = Color(0xFF0099B8);
  static const Color sosRed = Color(0xFFE53935);

  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    _updateLocation();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _updateLocation();
    });
  }

  void _updateLocation() {
    if (mounted) {
      context.read<SosController>().updateVolunteerLiveLocation(widget.sosData['id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<SosRepository>();

    return StreamBuilder<SosAlert?>(
      stream: repository.streamSosAlert(widget.sosData['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final alert = snapshot.data;
        if (alert == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Live Tracking')),
            body: const Center(child: Text('Emergency alert not found or has been removed.')),
          );
        }

        final ngoLat = alert.ngoLatitude;
        final ngoLng = alert.ngoLongitude;
        final volunteerLat = alert.latitude;
        final volunteerLng = alert.longitude;
        final eta = alert.estimatedArrival;
        final status = alert.status;
        final respondingNgo = alert.respondingNgoName ?? 'NGO';

        String distance = '';
        if (volunteerLat != null && volunteerLng != null && ngoLat != null && ngoLng != null) {
          double distanceInMeters = Geolocator.distanceBetween(
            ngoLat,
            ngoLng,
            volunteerLat,
            volunteerLng,
          );
          if (distanceInMeters < 1000) {
            distance = '${distanceInMeters.toInt()} meters';
          } else {
            distance = '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
          }
        }

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            backgroundColor: status == 'resolved' ? Colors.green : sosRed,
            foregroundColor: Colors.white,
            title: const Text('Live Tracking'),
            actions: [
              if (status == 'responding')
                IconButton(
                  onPressed: () => _makePhoneCall(alert.ngoPhone ?? ''),
                  icon: const Icon(Icons.call),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Status Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: status == 'resolved'
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [sosRed, Colors.red.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (status == 'resolved' ? Colors.green : sosRed).withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          status == 'resolved' ? Icons.check_circle : Icons.directions_run,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        status == 'resolved' ? 'Emergency Resolved!' : 'Help is on the way!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (eta != null && status != 'resolved') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'ETA: $eta minutes',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Distance Card
                if (distance.isNotEmpty && status != 'resolved')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.near_me, color: Colors.blue, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Distance Away',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                distance,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.gps_fixed, color: Colors.green),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Responding NGO Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.business, color: primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Responding NGO',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: primary.withValues(alpha: 0.1),
                            radius: 25,
                            child: Text(
                              respondingNgo.isNotEmpty ? respondingNgo[0].toUpperCase() : 'N',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  respondingNgo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: status == 'resolved' ? Colors.grey : Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      status == 'resolved' ? 'Completed' : 'On the way',
                                      style: TextStyle(
                                        color: status == 'resolved' ? Colors.grey : Colors.green,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (status != 'resolved')
                            GestureDetector(
                              onTap: () => _makePhoneCall(alert.ngoPhone ?? ''),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.call, color: Colors.green),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Open in Maps Button
                if (ngoLat != null && ngoLng != null && status != 'resolved')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openMapsToNgo(ngoLat, ngoLng),
                      icon: const Icon(Icons.map),
                      label: const Text('View NGO Location in Maps'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Tips Card
                if (status != 'resolved')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.tips_and_updates, color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Stay Safe',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Stay calm and in a safe location\n• Keep your phone charged\n• Don\'t move unless necessary\n• Help is on the way!',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available. Please try again later.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openMapsToNgo(double lat, double lng) async {
    final Uri mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    }
  }
}
