import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/notification_service.dart';

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
  
  // Location
  Position? _currentPosition;
  String _currentAddress = 'Getting location...';
  bool _isLoadingLocation = true;
  
  // Emergency type
  String? _selectedEmergencyType;
  final TextEditingController _descriptionController = TextEditingController();
  
  // Media
  File? _emergencyImage;
  final ImagePicker _imagePicker = ImagePicker();
  
  // SOS State
  bool _isSendingSOS = false;
  bool _sosCountdownActive = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;

  // Emergency Types
  final List<Map<String, dynamic>> _emergencyTypes = [
    {'type': 'Medical', 'icon': Icons.medical_services, 'color': Colors.red},
    {'type': 'Accident', 'icon': Icons.car_crash, 'color': Colors.orange},
    {'type': 'Fire', 'icon': Icons.local_fire_department, 'color': Colors.deepOrange},
    {'type': 'Natural Disaster', 'icon': Icons.flood, 'color': Colors.blue},
    {'type': 'Personal Safety', 'icon': Icons.shield, 'color': Colors.purple},
    {'type': 'Other', 'icon': Icons.warning, 'color': Colors.grey},
  ];

  // Emergency Contacts
  final List<Map<String, dynamic>> _emergencyContacts = [
    {'name': 'Police', 'number': '100', 'image': 'assets/police.jpg', 'color': Colors.blue},
    {'name': 'Ambulance', 'number': '108', 'image': 'assets/ambulance.png', 'color': Colors.red},
    {'name': 'Fire', 'number': '101', 'image': 'assets/fire.jpeg', 'color': Colors.orange},
    {'name': 'Women Helpline', 'number': '1091', 'image': 'assets/women hepline.png', 'color': Colors.pink},
    {'name': 'Child Helpline', 'number': '1098', 'image': 'assets/child.jpg', 'color': Colors.green},
    {'name': 'Disaster', 'number': '1078', 'image': 'assets/disaster.png', 'color': Colors.purple},
  ];

  // SOS History
  List<Map<String, dynamic>> _sosHistory = [];
  bool _isLoadingHistory = true;
  
  // Volunteer phone for NGO contact
  String? _volunteerPhone;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getCurrentLocation();
    _loadSOSHistory();
    _loadVolunteerPhone();
  }

  Future<void> _loadVolunteerPhone() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(widget.odid)
          .get();
      if (doc.exists) {
        setState(() {
          _volunteerPhone = doc.data()?['phone'] ?? '';
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
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = 'Location services disabled';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress = 'Location permission denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentAddress = 'Location permission permanently denied';
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() => _currentPosition = position);

      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            _currentAddress = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}';
          });
        }
      } catch (e) {
        setState(() {
          _currentAddress = 'Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Error getting location';
      });
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _loadSOSHistory() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sos_alerts')
          .where('odid', isEqualTo: widget.odid)
          .get();

      // Sort client-side to avoid composite index requirement
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      setState(() {
        _sosHistory = docs.take(20).map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        _isLoadingHistory = false;
      });
    } catch (e) {
      debugPrint('Error loading SOS history: $e');
      setState(() => _isLoadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
          // SOS Button
          _buildSOSButton(),
          const SizedBox(height: 24),

          // Location Card
          _buildLocationCard(),
          const SizedBox(height: 20),

          // Emergency Type Selection
          _buildEmergencyTypeSection(),
          const SizedBox(height: 20),

          // Description
          _buildDescriptionSection(),
          const SizedBox(height: 20),

          // Add Photo
          _buildPhotoSection(),
          const SizedBox(height: 20),

          // Send Alert Button
          _buildSendAlertButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSOSButton() {
    return Center(
      child: GestureDetector(
        onLongPressStart: (_) => _startCountdown(),
        onLongPressEnd: (_) => _cancelCountdown(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _sosCountdownActive ? 180 : 160,
          height: _sosCountdownActive ? 180 : 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: sosRed,
            boxShadow: [
              BoxShadow(
                color: sosRed.withOpacity(_sosCountdownActive ? 0.6 : 0.4),
                blurRadius: _sosCountdownActive ? 30 : 20,
                spreadRadius: _sosCountdownActive ? 10 : 5,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sos,
                size: _sosCountdownActive ? 60 : 50,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                _sosCountdownActive ? '$_countdownSeconds' : 'HOLD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _sosCountdownActive ? 28 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!_sosCountdownActive)
                const Text(
                  'for 5 sec',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _startCountdown() {
    setState(() {
      _sosCountdownActive = true;
      _countdownSeconds = 5;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        _sendQuickSOS();
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _sosCountdownActive = false;
      _countdownSeconds = 5;
    });
  }

  Future<void> _sendQuickSOS() async {
    setState(() {
      _sosCountdownActive = false;
      _isSendingSOS = true;
    });

    try {
      // Save SOS alert to Firestore
      final docRef = await FirebaseFirestore.instance.collection('sos_alerts').add({
        'odid': widget.odid,
        'odname': widget.odname,
        'volunteerPhone': _volunteerPhone,
        'emergencyType': 'Quick SOS',
        'description': 'Emergency SOS - Immediate help needed!',
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'address': _currentAddress,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify all NGO members
      await _notifyNGOMembers(
        sosId: docRef.id,
        emergencyType: 'Quick SOS',
        volunteerName: widget.odname,
        address: _currentAddress,
      );

      // Vibrate or play sound
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

      _loadSOSHistory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending SOS: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSendingSOS = false);
    }
  }

  /// Notify all NGO members about the SOS alert
  Future<void> _notifyNGOMembers({
    required String sosId,
    required String emergencyType,
    required String volunteerName,
    required String address,
  }) async {
    try {
      // Store notification in Firestore for all NGOs to receive
      await FirebaseFirestore.instance.collection('sos_notifications').add({
        'sosId': sosId,
        'volunteerId': widget.odid,
        'volunteerName': volunteerName,
        'volunteerPhone': _volunteerPhone,
        'emergencyType': emergencyType,
        'address': address,
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      debugPrint('SOS notification stored for NGO members');
    } catch (e) {
      debugPrint('Error notifying NGO members: $e');
    }
  }

  Widget _buildLocationCard() {
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
                  color: Colors.blue.withOpacity(0.1),
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
                onPressed: _getCurrentLocation,
                icon: Icon(
                  Icons.refresh,
                  color: _isLoadingLocation ? Colors.grey : primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingLocation)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentAddress,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
                if (_currentPosition != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Coordinates: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
        ],
      ),
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
                  color: isSelected ? (type['color'] as Color).withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? type['color'] as Color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      color: type['color'] as Color,
                      size: 28,
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
            hintText: 'Briefly describe the emergency situation...',
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
              borderSide: BorderSide(color: primary),
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
        Row(
          children: [
            GestureDetector(
              onTap: () => _pickImage(ImageSource.camera),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: primary),
                    const SizedBox(height: 4),
                    Text('Camera', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library, color: primary),
                    const SizedBox(height: 4),
                    Text('Gallery', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
            if (_emergencyImage != null) ...[
              const SizedBox(width: 12),
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_emergencyImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => setState(() => _emergencyImage = null),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() => _emergencyImage = File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Widget _buildSendAlertButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (_selectedEmergencyType == null || _isSendingSOS) ? null : _sendDetailedSOS,
        icon: _isSendingSOS
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.send),
        label: Text(_isSendingSOS ? 'Sending...' : 'Send Emergency Alert'),
        style: ElevatedButton.styleFrom(
          backgroundColor: sosRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _sendDetailedSOS() async {
    if (_selectedEmergencyType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an emergency type')),
      );
      return;
    }

    setState(() => _isSendingSOS = true);

    try {
      String? imageUrl;

      // Upload image if available
      if (_emergencyImage != null) {
        final fileName = 'sos_images/${widget.odid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(_emergencyImage!);
        imageUrl = await ref.getDownloadURL();
      }

      // Save SOS alert to Firestore
      final docRef = await FirebaseFirestore.instance.collection('sos_alerts').add({
        'odid': widget.odid,
        'odname': widget.odname,
        'volunteerPhone': _volunteerPhone,
        'emergencyType': _selectedEmergencyType,
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'address': _currentAddress,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify all NGO members
      await _notifyNGOMembers(
        sosId: docRef.id,
        emergencyType: _selectedEmergencyType!,
        volunteerName: widget.odname,
        address: _currentAddress,
      );

      // Clear form
      setState(() {
        _selectedEmergencyType = null;
        _descriptionController.clear();
        _emergencyImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Emergency alert sent successfully! Help is on the way.')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      _loadSOSHistory();
      _tabController.animateTo(2); // Switch to history tab
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending alert: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSendingSOS = false);
    }
  }

  // =============== QUICK CALL TAB ===============
  Widget _buildQuickCallTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emergency Services
          const Text(
            'Emergency Services',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: _emergencyContacts.length,
            itemBuilder: (context, index) {
              final contact = _emergencyContacts[index];
              return _buildEmergencyContactCard(contact);
            },
          ),
          const SizedBox(height: 24),

          // Nearby NGOs
          const Text(
            'Nearby NGOs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildNearbyNGOsList(),
          const SizedBox(height: 24),

          // Personal Emergency Contacts
          const Text(
            'My Emergency Contacts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPersonalContactsList(),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard(Map<String, dynamic> contact) {
    return GestureDetector(
      onTap: () => _makePhoneCall(contact['number']),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: (contact['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  contact['image'] as String,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.emergency,
                      color: contact['color'] as Color,
                      size: 32,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              contact['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              contact['number'] as String,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyNGOsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ngo_registrations')
          .where('status', isEqualTo: 'approved')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('No nearby NGOs found')),
          );
        }

        // Filter out NGOs without names or phone numbers
        final validNgos = snapshot.data!.docs.where((doc) {
          final ngo = doc.data() as Map<String, dynamic>;
          final name = ngo['ngoName']?.toString().trim() ?? '';
          final phone = ngo['mobileNo']?.toString().trim() ?? '';
          return name.isNotEmpty && phone.isNotEmpty;
        }).take(5).toList();

        if (validNgos.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('No nearby NGOs found')),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: validNgos.length,
          itemBuilder: (context, index) {
            final ngo = validNgos[index].data() as Map<String, dynamic>;
            return _buildNGOContactCard(ngo);
          },
        );
      },
    );
  }

  Widget _buildNGOContactCard(Map<String, dynamic> ngo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.business, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ngo['ngoName'] ?? 'NGO',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  ngo['mobileNo'] ?? 'N/A',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _makePhoneCall(ngo['mobileNo'] ?? ''),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call, color: Colors.green, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalContactsList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('od_volunteers')
          .doc(widget.odid)
          .snapshots(),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> emergencyContacts = [];
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data['emergencyContacts'] != null) {
            emergencyContacts = List<Map<String, dynamic>>.from(data['emergencyContacts']);
          }
        }

        if (emergencyContacts.isEmpty) {
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
            ...emergencyContacts.map((contact) => _buildPersonalContactCard(contact)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddContactDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Another Contact'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: sosRed,
                  side: BorderSide(color: sosRed.withOpacity(0.5)),
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

  Widget _buildPersonalContactCard(Map<String, dynamic> contact) {
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
            backgroundColor: sosRed.withOpacity(0.1),
            child: Text(
              (contact['name'] ?? 'C')[0].toUpperCase(),
              style: TextStyle(color: sosRed, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(contact['phone'] ?? '', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _makePhoneCall(contact['phone'] ?? ''),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
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
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEmergencyContact(Map<String, dynamic> contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to remove ${contact['name']}?'),
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
        await FirebaseFirestore.instance
            .collection('od_volunteers')
            .doc(widget.odid)
            .update({
          'emergencyContacts': FieldValue.arrayRemove([contact])
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact removed')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove contact: $e')),
        );
      }
    }
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: sosRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_add, color: sosRed, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Add Emergency Contact',
                style: TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Contact Name',
                  hintText: 'e.g., Mom, Dad, Friend',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g., 9876543210',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a phone number';
                  }
                  if (value.length < 10) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
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
                  final docRef = FirebaseFirestore.instance
                      .collection('od_volunteers')
                      .doc(widget.odid);
                  
                  final doc = await docRef.get();
                  if (doc.exists) {
                    await docRef.update({
                      'emergencyContacts': FieldValue.arrayUnion([
                        {
                          'name': nameController.text.trim(),
                          'phone': phoneController.text.trim(),
                        }
                      ])
                    });
                  } else {
                    await docRef.set({
                      'emergencyContacts': [
                        {
                          'name': nameController.text.trim(),
                          'phone': phoneController.text.trim(),
                        }
                      ]
                    }, SetOptions(merge: true));
                  }
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add Contact'),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not make phone call')),
      );
    }
  }

  // =============== HISTORY TAB ===============
  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sos_alerts')
          .where('odid', isEqualTo: widget.odid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

        // Sort client-side to avoid composite index requirement
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aTime = ((a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final bTime = ((b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
        final limitedDocs = docs.take(20).toList();

        return RefreshIndicator(
          onRefresh: () async {
            // StreamBuilder auto-refreshes
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: limitedDocs.length,
            itemBuilder: (context, index) {
              final doc = limitedDocs[index];
              final sos = doc.data() as Map<String, dynamic>;
              sos['id'] = doc.id;
              return _buildSOSHistoryCard(sos);
            },
          ),
        );
      },
    );
  }

  Widget _buildSOSHistoryCard(Map<String, dynamic> sos) {
    final status = sos['status'] ?? 'active';
    final createdAt = sos['createdAt'] as Timestamp?;
    final date = createdAt?.toDate();
    final respondingNgo = sos['respondingNgoName'];
    final eta = sos['estimatedArrival'] as int?;

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
        border: status == 'responding' 
            ? Border.all(color: Colors.blue, width: 2)
            : null,
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
                    color: statusColor.withOpacity(0.1),
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
                        sos['emergencyType'] ?? 'Emergency',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (date != null)
                        Text(
                          '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
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

          // Responding NGO info (if responding)
          if (status == 'responding' && respondingNgo != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                border: Border(
                  top: BorderSide(color: Colors.blue.withOpacity(0.2)),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.business, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Responding NGO',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              respondingNgo,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      if (eta != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ETA: $eta min',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openLiveTracking(sos),
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('Track Live Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Description
          if (sos['description'] != null && sos['description'].toString().isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                sos['description'],
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],

          // Location
          if (sos['address'] != null) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      sos['address'],
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Resolved info
          if (status == 'resolved' && sos['resolvedByNgo'] != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Resolved by ${sos['resolvedByNgo']}',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

          // Action buttons for active SOS
          if (status == 'active')
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _markAsResolved(sos['id']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                      child: const Text('Mark Resolved'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelSOS(sos['id']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _openLiveTracking(Map<String, dynamic> sos) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _VolunteerLiveTrackingScreen(
          sosData: sos,
          odid: widget.odid,
          odname: widget.odname,
        ),
      ),
    );
  }

  Future<void> _markAsResolved(String sosId) async {
    try {
      await FirebaseFirestore.instance.collection('sos_alerts').doc(sosId).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      _loadSOSHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS marked as resolved'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
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
        await FirebaseFirestore.instance.collection('sos_alerts').doc(sosId).delete();
        _loadSOSHistory();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS cancelled')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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

  Position? _currentPosition;
  Timer? _locationTimer;
  StreamSubscription? _sosSubscription;
  Map<String, dynamic>? _liveSOSData;

  @override
  void initState() {
    super.initState();
    _liveSOSData = widget.sosData;
    _startLocationUpdates();
    _subscribeToSOS();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _sosSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToSOS() {
    _sosSubscription = FirebaseFirestore.instance
        .collection('sos_alerts')
        .doc(widget.sosData['id'])
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _liveSOSData = snapshot.data() as Map<String, dynamic>;
          _liveSOSData!['id'] = snapshot.id;
        });
        
        // Check if status changed to resolved
        if (_liveSOSData?['status'] == 'resolved') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency has been resolved!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  void _startLocationUpdates() {
    _updateLocation();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _updateLocation();
    });
  }

  Future<void> _updateLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _currentPosition = position);

      // Update volunteer's location in Firestore
      await FirebaseFirestore.instance
          .collection('sos_alerts')
          .doc(widget.sosData['id'])
          .update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'volunteerLocationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ngoLat = _liveSOSData?['ngoLatitude'] as double?;
    final ngoLng = _liveSOSData?['ngoLongitude'] as double?;
    final volunteerLat = _liveSOSData?['latitude'] as double?;
    final volunteerLng = _liveSOSData?['longitude'] as double?;
    final eta = _liveSOSData?['estimatedArrival'] as int?;
    final status = _liveSOSData?['status'] ?? 'responding';
    final respondingNgo = _liveSOSData?['respondingNgoName'] ?? 'NGO';

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
              onPressed: () => _makePhoneCall(_liveSOSData?['ngoPhone'] ?? ''),
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
                    color: (status == 'resolved' ? Colors.green : sosRed).withOpacity(0.4),
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
                      color: Colors.white.withOpacity(0.2),
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
                        color: Colors.white.withOpacity(0.2),
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
                        color: Colors.blue.withOpacity(0.1),
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
                        color: Colors.green.withOpacity(0.1),
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
                        backgroundColor: primary.withOpacity(0.1),
                        radius: 25,
                        child: Text(
                          respondingNgo[0].toUpperCase(),
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
                          onTap: () => _makePhoneCall(_liveSOSData?['ngoPhone'] ?? ''),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _openMapsToNgo(double lat, double lng) async {
    final Uri mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    }
  }
}