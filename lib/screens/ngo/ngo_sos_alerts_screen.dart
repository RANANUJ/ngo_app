import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class NgoSOSAlertsScreen extends StatefulWidget {
  final String ngoId;
  final String ngoName;

  const NgoSOSAlertsScreen({
    Key? key,
    required this.ngoId,
    required this.ngoName,
  }) : super(key: key);

  @override
  State<NgoSOSAlertsScreen> createState() => _NgoSOSAlertsScreenState();
}

class _NgoSOSAlertsScreenState extends State<NgoSOSAlertsScreen> with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  static const Color sosRed = Color(0xFFE53935);

  late TabController _tabController;
  Position? _currentPosition;
  String _currentAddress = 'Getting location...';
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getCurrentLocation();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _getCurrentLocation();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() => _currentPosition = position);

      // Get address
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          setState(() {
            _currentAddress = '${place.locality}, ${place.administrativeArea}';
          });
        }
      } catch (e) {
        debugPrint('Error getting address: $e');
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: sosRed,
        foregroundColor: Colors.white,
        title: const Text('SOS Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active', icon: Icon(Icons.warning, size: 20)),
            Tab(text: 'Responding', icon: Icon(Icons.directions_run, size: 20)),
            Tab(text: 'Resolved', icon: Icon(Icons.check_circle, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveAlertsTab(),
          _buildRespondingTab(),
          _buildResolvedTab(),
        ],
      ),
    );
  }

  Widget _buildActiveAlertsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sos_alerts')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('SOS Query Error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                const SizedBox(height: 16),
                const Text('Error loading SOS alerts'),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'No Active SOS Alerts',
            subtitle: 'All emergencies have been responded to',
          );
        }

        // Sort locally by createdAt
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // Descending
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return _buildActiveSOSCard(data);
          },
        );
      },
    );
  }

  Widget _buildRespondingTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sos_alerts')
          .where('respondingNgoId', isEqualTo: widget.ngoId)
          .where('status', isEqualTo: 'responding')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Responding Query Error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.directions_run,
            title: 'No Active Responses',
            subtitle: 'You are not responding to any SOS currently',
          );
        }

        // Sort locally
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['respondedAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['respondedAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return _buildRespondingCard(data);
          },
        );
      },
    );
  }

  Widget _buildResolvedTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sos_alerts')
          .where('respondingNgoId', isEqualTo: widget.ngoId)
          .where('status', isEqualTo: 'resolved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Resolved Query Error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: 'No Resolved SOS',
            subtitle: 'Your resolved emergency responses will appear here',
          );
        }

        // Sort locally and limit
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['resolvedAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['resolvedAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });
        final limitedDocs = docs.take(50).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: limitedDocs.length,
          itemBuilder: (context, index) {
            final doc = limitedDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return _buildResolvedCard(data);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSOSCard(Map<String, dynamic> sos) {
    final createdAt = sos['createdAt'] as Timestamp?;
    final date = createdAt?.toDate();
    final timeDiff = date != null ? DateTime.now().difference(date) : null;
    
    String timeAgo = '';
    if (timeDiff != null) {
      if (timeDiff.inMinutes < 1) {
        timeAgo = 'Just now';
      } else if (timeDiff.inMinutes < 60) {
        timeAgo = '${timeDiff.inMinutes} min ago';
      } else if (timeDiff.inHours < 24) {
        timeAgo = '${timeDiff.inHours} hr ago';
      } else {
        timeAgo = '${timeDiff.inDays} days ago';
      }
    }

    // Calculate distance if we have positions
    String distance = '';
    if (_currentPosition != null && sos['latitude'] != null && sos['longitude'] != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        sos['latitude'],
        sos['longitude'],
      );
      if (distanceInMeters < 1000) {
        distance = '${distanceInMeters.toInt()} m away';
      } else {
        distance = '${(distanceInMeters / 1000).toStringAsFixed(1)} km away';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sosRed.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: sosRed.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with urgent indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: sosRed.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: sosRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sos, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sos['emergencyType'] ?? 'Emergency',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: sosRed,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (distance.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          distance,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Volunteer Info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: primary.withOpacity(0.1),
                      child: Text(
                        (sos['odname'] ?? 'V')[0].toUpperCase(),
                        style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sos['odname'] ?? 'Volunteer',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Volunteer in distress',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Call button
                    if (sos['volunteerPhone'] != null)
                      IconButton(
                        onPressed: () => _makePhoneCall(sos['volunteerPhone']),
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

                // Description
                if (sos['description'] != null && sos['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      sos['description'],
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],

                // Location
                if (sos['address'] != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _openMaps(sos['latitude'], sos['longitude']),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sos['address'],
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ),
                          const Icon(Icons.open_in_new, color: Colors.blue, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],

                // Image if any
                if (sos['imageUrl'] != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      sos['imageUrl'],
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ],

                // Action Buttons
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _respondToSOS(sos),
                        icon: const Icon(Icons.directions_run),
                        label: const Text('Respond Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sosRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _viewSOSDetails(sos),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRespondingCard(Map<String, dynamic> sos) {
    final respondedAt = sos['respondedAt'] as Timestamp?;
    final date = respondedAt?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions_run, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sos['emergencyType'] ?? 'Emergency',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        'You are responding',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'IN PROGRESS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Volunteer Info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: sosRed.withOpacity(0.1),
                      child: Text(
                        (sos['odname'] ?? 'V')[0].toUpperCase(),
                        style: TextStyle(color: sosRed, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sos['odname'] ?? 'Volunteer',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (sos['volunteerPhone'] != null)
                            Text(
                              sos['volunteerPhone'],
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _makePhoneCall(sos['volunteerPhone'] ?? ''),
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call, color: Colors.green),
                      ),
                    ),
                  ],
                ),

                // Live Location Button
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openLiveTracking(sos),
                    icon: const Icon(Icons.my_location, color: Colors.blue),
                    label: const Text('View Live Location'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                // Action Buttons
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markResolved(sos['id']),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Mark Resolved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateETA(sos['id']),
                        icon: const Icon(Icons.access_time),
                        label: const Text('Update ETA'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolvedCard(Map<String, dynamic> sos) {
    final resolvedAt = sos['resolvedAt'] as Timestamp?;
    final date = resolvedAt?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sos['emergencyType'] ?? 'Emergency',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  sos['odname'] ?? 'Volunteer',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                if (date != null)
                  Text(
                    'Resolved on ${date.day}/${date.month}/${date.year}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'RESOLVED',
              style: TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _respondToSOS(Map<String, dynamic> sos) async {
    final confirmed = await showDialog<bool>(
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
              child: const Icon(Icons.directions_run, color: sosRed),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Respond to SOS')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are about to respond to this emergency.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your location will be shared with the volunteer for real-time tracking.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.directions_run),
            label: const Text('Respond Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: sosRed,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show ETA dialog
        final eta = await _showETADialog();
        if (eta == null) return;

        await FirebaseFirestore.instance
            .collection('sos_alerts')
            .doc(sos['id'])
            .update({
          'status': 'responding',
          'respondingNgoId': widget.ngoId,
          'respondingNgoName': widget.ngoName,
          'respondedAt': FieldValue.serverTimestamp(),
          'estimatedArrival': eta,
          'ngoLatitude': _currentPosition?.latitude,
          'ngoLongitude': _currentPosition?.longitude,
          'ngoAddress': _currentAddress,
        });

        // Notify nearby volunteers
        await _notifyNearbyVolunteers(sos);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response confirmed! The volunteer has been notified.'),
            backgroundColor: Colors.green,
          ),
        );

        // Switch to Responding tab
        _tabController.animateTo(1);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<int?> _showETADialog() async {
    int selectedETA = 15;
    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Estimated Time of Arrival'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How soon can you reach?'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: selectedETA > 5
                        ? () => setState(() => selectedETA -= 5)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    iconSize: 32,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$selectedETA min',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: selectedETA < 60
                        ? () => setState(() => selectedETA += 5)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    iconSize: 32,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedETA),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _notifyNearbyVolunteers(Map<String, dynamic> sos) async {
    if (sos['latitude'] == null || sos['longitude'] == null) return;

    try {
      // Get all volunteers
      final volunteersSnapshot = await FirebaseFirestore.instance
          .collection('volunteers')
          .get();

      // Create notification for nearby volunteers
      await FirebaseFirestore.instance.collection('volunteer_sos_notifications').add({
        'sosId': sos['id'],
        'emergencyType': sos['emergencyType'],
        'address': sos['address'],
        'latitude': sos['latitude'],
        'longitude': sos['longitude'],
        'volunteerInNeedId': sos['odid'],
        'volunteerInNeedName': sos['odname'],
        'createdAt': FieldValue.serverTimestamp(),
        'respondingNgo': widget.ngoName,
        'status': 'active',
      });
    } catch (e) {
      debugPrint('Error notifying volunteers: $e');
    }
  }

  Future<void> _markResolved(String sosId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Resolved'),
        content: const Text('Are you sure the emergency has been resolved?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Yes, Resolved', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('sos_alerts').doc(sosId).update({
          'status': 'resolved',
          'resolvedAt': FieldValue.serverTimestamp(),
          'resolvedByNgo': widget.ngoName,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS marked as resolved!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateETA(String sosId) async {
    final eta = await _showETADialog();
    if (eta == null) return;

    try {
      await FirebaseFirestore.instance.collection('sos_alerts').doc(sosId).update({
        'estimatedArrival': eta,
        'etaUpdatedAt': FieldValue.serverTimestamp(),
        'ngoLatitude': _currentPosition?.latitude,
        'ngoLongitude': _currentPosition?.longitude,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ETA updated to $eta minutes'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _viewSOSDetails(Map<String, dynamic> sos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sosRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sos, color: sosRed, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sos['emergencyType'] ?? 'Emergency',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'From: ${sos['odname'] ?? 'Volunteer'}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(Icons.description, 'Description', sos['description'] ?? 'No description'),
              _buildDetailRow(Icons.location_on, 'Location', sos['address'] ?? 'Unknown'),
              _buildDetailRow(Icons.phone, 'Contact', sos['volunteerPhone'] ?? 'Not available'),
              if (sos['imageUrl'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Attached Image',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    sos['imageUrl'],
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _respondToSOS(sos);
                  },
                  icon: const Icon(Icons.directions_run),
                  label: const Text('Respond to this SOS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sosRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15),
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
        builder: (context) => _LiveTrackingScreen(
          sosData: sos,
          ngoId: widget.ngoId,
          ngoName: widget.ngoName,
          isNgo: true,
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _openMaps(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final Uri mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    }
  }
}

// Live Tracking Screen
class _LiveTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> sosData;
  final String ngoId;
  final String ngoName;
  final bool isNgo;

  const _LiveTrackingScreen({
    required this.sosData,
    required this.ngoId,
    required this.ngoName,
    required this.isNgo,
  });

  @override
  State<_LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<_LiveTrackingScreen> {
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

      // Update location in Firestore
      if (widget.isNgo) {
        await FirebaseFirestore.instance
            .collection('sos_alerts')
            .doc(widget.sosData['id'])
            .update({
          'ngoLatitude': position.latitude,
          'ngoLongitude': position.longitude,
          'ngoLocationUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final volunteerLat = _liveSOSData?['latitude'] as double?;
    final volunteerLng = _liveSOSData?['longitude'] as double?;
    final ngoLat = _liveSOSData?['ngoLatitude'] as double?;
    final ngoLng = _liveSOSData?['ngoLongitude'] as double?;
    final eta = _liveSOSData?['estimatedArrival'] as int?;
    final status = _liveSOSData?['status'] ?? 'responding';

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: status == 'resolved' ? Colors.green : sosRed,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    status == 'resolved' ? Icons.check_circle : Icons.directions_run,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    status == 'resolved' ? 'Emergency Resolved' : 'Help is on the way!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (eta != null && status != 'resolved') ...[
                    const SizedBox(height: 8),
                    Text(
                      'ETA: $eta minutes',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Distance',
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
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Volunteer Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isNgo ? 'Volunteer in Need' : 'Responding NGO',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: primary.withOpacity(0.1),
                        child: Text(
                          widget.isNgo
                              ? ((_liveSOSData?['odname'] as String?) ?? 'V')[0].toUpperCase()
                              : ((_liveSOSData?['respondingNgoName'] as String?) ?? 'N')[0].toUpperCase(),
                          style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isNgo
                                  ? (_liveSOSData?['odname'] as String?) ?? 'Volunteer'
                                  : (_liveSOSData?['respondingNgoName'] as String?) ?? 'NGO',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              (_liveSOSData?['address'] as String?) ?? 'Location',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Open in Maps
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final lat = widget.isNgo ? volunteerLat : ngoLat;
                  final lng = widget.isNgo ? volunteerLng : ngoLng;
                  if (lat != null && lng != null) {
                    final Uri mapsUri = Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                    );
                    if (await canLaunchUrl(mapsUri)) {
                      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
                icon: const Icon(Icons.map),
                label: Text(widget.isNgo ? 'Open Volunteer Location in Maps' : 'Open NGO Location in Maps'),
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
          ],
        ),
      ),
    );
  }
}
