import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../domain/models/sos_alert.dart';
import '../../domain/repositories/sos_repository.dart';
import '../controllers/sos_controller.dart';
import 'package:ngo_app/shared/widgets/skeleton_loader.dart';

class NgoSOSAlertsScreen extends StatefulWidget {
  final String ngoId;
  final String ngoName;
  final String ngoPhone;

  const NgoSOSAlertsScreen({
    Key? key,
    required this.ngoId,
    required this.ngoName,
    required this.ngoPhone,
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

      if (mounted) {
        setState(() => _currentPosition = position);
      }

      // Get address
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty && mounted) {
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
    final repository = context.read<SosRepository>();

    return StreamBuilder<List<SosAlert>>(
      stream: repository.streamActiveAlerts(),
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
          return const ListSkeleton(itemCount: 4, height: 85);
        }

        final alerts = snapshot.data ?? [];

        if (alerts.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'No Active SOS Alerts',
            subtitle: 'All emergencies have been responded to',
          );
        }

        // Sort descending locally by createdAt
        final sortedAlerts = List<SosAlert>.from(alerts);
        sortedAlerts.sort((a, b) {
          final aTime = a.createdAt ?? DateTime(1970);
          final bTime = b.createdAt ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedAlerts.length,
          itemBuilder: (context, index) {
            final alert = sortedAlerts[index];
            return _buildActiveSOSCard(alert);
          },
        );
      },
    );
  }

  Widget _buildRespondingTab() {
    final repository = context.read<SosRepository>();

    return StreamBuilder<List<SosAlert>>(
      stream: repository.streamRespondingAlerts(widget.ngoId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Responding Query Error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListSkeleton(itemCount: 3, height: 85);
        }

        final alerts = snapshot.data ?? [];

        if (alerts.isEmpty) {
          return _buildEmptyState(
            icon: Icons.directions_run,
            title: 'No Active Responses',
            subtitle: 'You are not responding to any SOS currently',
          );
        }

        // Sort descending locally by respondedAt
        final sortedAlerts = List<SosAlert>.from(alerts);
        sortedAlerts.sort((a, b) {
          final aTime = a.respondedAt ?? DateTime(1970);
          final bTime = b.respondedAt ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedAlerts.length,
          itemBuilder: (context, index) {
            final alert = sortedAlerts[index];
            return _buildRespondingCard(alert);
          },
        );
      },
    );
  }

  Widget _buildResolvedTab() {
    final repository = context.read<SosRepository>();

    return StreamBuilder<List<SosAlert>>(
      stream: repository.streamResolvedAlerts(widget.ngoId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Resolved Query Error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListSkeleton(itemCount: 3, height: 85);
        }

        final alerts = snapshot.data ?? [];

        if (alerts.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle,
            title: 'No Resolved Alerts',
            subtitle: 'Resolved emergency history will appear here',
          );
        }

        // Sort descending locally by resolvedAt
        final sortedAlerts = List<SosAlert>.from(alerts);
        sortedAlerts.sort((a, b) {
          final aTime = a.resolvedAt ?? DateTime(1970);
          final bTime = b.resolvedAt ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedAlerts.length,
          itemBuilder: (context, index) {
            final alert = sortedAlerts[index];
            return _buildResolvedCard(alert);
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 80, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSOSCard(SosAlert sos) {
    final date = sos.createdAt;
    String timeAgo = '';
    if (date != null) {
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) {
        timeAgo = 'Just now';
      } else if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes} mins ago';
      } else {
        timeAgo = '${diff.inHours} hrs ago';
      }
    }

    double? distance;
    if (_currentPosition != null && sos.latitude != null && sos.longitude != null) {
      distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        sos.latitude!,
        sos.longitude!,
      ) / 1000; // in km
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.red.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sos, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sos.emergencyType,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
                      ),
                      Text(
                        'By ${sos.odname}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeAgo,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (distance != null)
                      Text(
                        '${distance.toStringAsFixed(1)} km away',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                  ],
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
                if (sos.description.isNotEmpty) ...[
                  Text(
                    sos.description,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sos.address,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                if (sos.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      sos.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        color: Colors.grey.shade100,
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _viewSOSDetails(sos),
                    icon: const Icon(Icons.info_outline, size: 20),
                    label: const Text('View Details'),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _respondToSOS(sos),
                    icon: const Icon(Icons.directions_run, size: 20),
                    label: const Text('RESPOND'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sosRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRespondingCard(SosAlert sos) {
    final date = sos.respondedAt;
    final eta = sos.estimatedArrival;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.blue.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_run, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sos.emergencyType,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                      ),
                      Text(
                        'Assisting: ${sos.odname}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (eta != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ETA: $eta min',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sos.address,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                if (date != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Responded at ${DateFormat('hh:mm a').format(date)}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateETA(sos.id),
                    icon: const Icon(Icons.access_time, size: 18),
                    label: const Text('Update ETA'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _NgoLiveTrackingScreen(
                            sosData: sos.toMap()..['id'] = sos.id,
                            ngoId: widget.ngoId,
                            ngoName: widget.ngoName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Track Live'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markResolved(sos.id),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Resolve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolvedCard(SosAlert sos) {
    final date = sos.resolvedAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
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
                  sos.emergencyType,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  sos.odname,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                if (date != null)
                  Text(
                    'Resolved on ${DateFormat('dd/MM/yyyy').format(date)}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
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

  Future<void> _respondToSOS(SosAlert sos) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: sosRed.withValues(alpha: 0.1),
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
                color: Colors.orange.withValues(alpha: 0.1),
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
        final eta = await _showETADialog();
        if (eta == null) return;

        final controller = context.read<SosController>();
        await controller.respondToSosAlert(
          sosId: sos.id,
          ngoId: widget.ngoId,
          ngoName: widget.ngoName,
          ngoPhone: widget.ngoPhone,
          eta: eta,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response confirmed! The volunteer has been notified.'),
            backgroundColor: Colors.green,
          ),
        );

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
                    onPressed: selectedETA > 5 ? () => setState(() => selectedETA -= 5) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    iconSize: 32,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
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
                    onPressed: selectedETA < 60 ? () => setState(() => selectedETA += 5) : null,
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
        final controller = context.read<SosController>();
        await controller.resolveSosAlert(sosId);

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
      final controller = context.read<SosController>();
      await controller.respondToSosAlert(
        sosId: sosId,
        ngoId: widget.ngoId,
        ngoName: widget.ngoName,
        ngoPhone: widget.ngoPhone,
        eta: eta,
      );

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

  void _viewSOSDetails(SosAlert sos) {
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
                      color: sosRed.withValues(alpha: 0.1),
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
                          sos.emergencyType,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'From: ${sos.odname}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(Icons.description, 'Description', sos.description.isNotEmpty ? sos.description : 'No description'),
              _buildDetailRow(Icons.location_on, 'Location', sos.address),
              _buildDetailRow(Icons.phone, 'Contact', sos.volunteerPhone.isNotEmpty ? sos.volunteerPhone : 'Not available'),
              if (sos.imageUrl != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Attached Image',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    sos.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.grey.shade100,
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
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
          Icon(icon, color: primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
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
}

// NGO Live Tracking Screen (tracks the volunteer's current position)
class _NgoLiveTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> sosData;
  final String ngoId;
  final String ngoName;

  const _NgoLiveTrackingScreen({
    required this.sosData,
    required this.ngoId,
    required this.ngoName,
  });

  @override
  State<_NgoLiveTrackingScreen> createState() => _NgoLiveTrackingScreenState();
}

class _NgoLiveTrackingScreenState extends State<_NgoLiveTrackingScreen> {
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
      context.read<SosController>().updateNgoLiveLocation(widget.sosData['id']);
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
            body: const Center(child: Text('Emergency alert not found or has been resolved.')),
          );
        }

        final ngoLat = alert.ngoLatitude;
        final ngoLng = alert.ngoLongitude;
        final volunteerLat = alert.latitude;
        final volunteerLng = alert.longitude;
        final status = alert.status;
        final volunteerName = alert.odname;

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
              IconButton(
                onPressed: () => _makePhoneCall(alert.volunteerPhone),
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
                        status == 'resolved' ? 'Emergency Resolved!' : 'Responding to emergency',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                                'Distance away from volunteer',
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

                // Volunteer Info Card
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
                          Icon(Icons.person, color: primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Volunteer in Need',
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
                              volunteerName.isNotEmpty ? volunteerName[0].toUpperCase() : 'V',
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
                                  volunteerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  alert.address,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _makePhoneCall(alert.volunteerPhone),
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

                // Open in Maps
                if (volunteerLat != null && volunteerLng != null && status != 'resolved')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openMapsToVolunteer(volunteerLat, volunteerLng),
                      icon: const Icon(Icons.map),
                      label: const Text('Open Volunteer Location in Maps'),
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

  Future<void> _openMapsToVolunteer(double lat, double lng) async {
    final Uri mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    }
  }
}
