import 'package:ngo_app/core/utils/network/network_utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngo_app/screens/emergency/emergency_detail_screen.dart';
import 'package:ngo_app/screens/volunteer/volunteer_emergency_detail_screen.dart';

class VolunteerEmergencyScreen extends StatefulWidget {
  const VolunteerEmergencyScreen({super.key});

  @override
  State<VolunteerEmergencyScreen> createState() => _VolunteerEmergencyScreenState();
}

class _VolunteerEmergencyScreenState extends State<VolunteerEmergencyScreen> {
  static const Color primaryColor = Color(0xFF0099B8);
  static const Color emergencyRed = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: emergencyRed),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emergency, color: emergencyRed, size: 24),
            SizedBox(width: 8),
            Text(
              'Emergency',
              style: TextStyle(
                color: emergencyRed,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergency_donations')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: emergencyRed));
          }
          
          if (snapshot.hasError) {
            secureLog('Error loading emergencies: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text('Error loading data', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }
          
          // Filter active emergencies locally
          final allDocs = snapshot.data?.docs ?? [];
          
          final activeDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'active';
          }).toList();
          
          // Sort by createdAt descending
          activeDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          
          if (activeDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emergency, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No active emergencies',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeDocs.length,
            itemBuilder: (context, index) {
              final doc = activeDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildEmergencyCard(data, doc.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmergencyCard(Map<String, dynamic> data, String docId) {
    final title = data['title'] ?? 'Emergency';
    final description = data['description'] ?? '';
    final targetAmount = (data['targetAmount'] ?? 0).toDouble();
    final collectedAmount = (data['collectedAmount'] ?? 0).toDouble();
    final createdAt = data['createdAt'] as Timestamp?;
    final images = List<String>.from(data['images'] ?? []);
    
    final progress = targetAmount > 0 ? (collectedAmount / targetAmount) : 0.0;
    
    String timeAgo = 'Recently';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt.toDate());
      if (diff.inDays > 0) {
        timeAgo = '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours}h ago';
      } else {
        timeAgo = '${diff.inMinutes}m ago';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VolunteerEmergencyDetailScreen(
              emergencyId: docId,
              emergencyData: data,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: emergencyRed.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: emergencyRed.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (images.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  images.first,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 48, color: Colors.grey),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emergency badge and time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: emergencyRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'URGENT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Amount raised
                  Row(
                    children: [
                      Text(
                        '?${collectedAmount.toInt()} raised',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: emergencyRed,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'of ?${targetAmount.toInt()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(emergencyRed),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Donate button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VolunteerEmergencyDetailScreen(
                              emergencyId: docId,
                              emergencyData: data,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emergencyRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Donate',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
