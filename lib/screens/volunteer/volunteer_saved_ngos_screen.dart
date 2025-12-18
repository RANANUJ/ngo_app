import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ngo/ngo_public_profile_screen.dart';
import '../../services/ngo_registration_service.dart';

class VolunteerSavedNgosScreen extends StatefulWidget {
  const VolunteerSavedNgosScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerSavedNgosScreen> createState() => _VolunteerSavedNgosScreenState();
}

class _VolunteerSavedNgosScreenState extends State<VolunteerSavedNgosScreen> {
  static const Color primary = Color(0xFF0099B8);
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Saved NGOs'),
      ),
      body: _userId == null
          ? const Center(child: Text('Please login to view saved NGOs'))
          : _buildNgosList(),
    );
  }

  Widget _buildNgosList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('volunteer_registrations')
          .where('volunteerId', isEqualTo: _userId)
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Try with alternate query
          return _buildAlternateNgosList();
        }

        final registrations = snapshot.data?.docs ?? [];

        if (registrations.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: registrations.length,
            itemBuilder: (context, index) {
              final registration = registrations[index].data() as Map<String, dynamic>;
              final ngoId = registration['ngoId'] as String?;

              if (ngoId == null) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('ngo_registrations')
                    .doc(ngoId)
                    .get(),
                builder: (context, ngoSnapshot) {
                  if (ngoSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingCard();
                  }

                  if (!ngoSnapshot.hasData || !ngoSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final ngo = ngoSnapshot.data!.data() as Map<String, dynamic>;
                  return _buildNgoCard(ngo, ngoId, registration);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAlternateNgosList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('volunteer_registrations')
          .where('volunteerId', isEqualTo: _userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allRegistrations = snapshot.data?.docs ?? [];
        
        // Filter approved ones manually
        final registrations = allRegistrations.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'approved';
        }).toList();

        if (registrations.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: registrations.length,
            itemBuilder: (context, index) {
              final registration = registrations[index].data() as Map<String, dynamic>;
              final ngoId = registration['ngoId'] as String?;

              if (ngoId == null) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('ngo_registrations')
                    .doc(ngoId)
                    .get(),
                builder: (context, ngoSnapshot) {
                  if (ngoSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingCard();
                  }

                  if (!ngoSnapshot.hasData || !ngoSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final ngo = ngoSnapshot.data!.data() as Map<String, dynamic>;
                  return _buildNgoCard(ngo, ngoId, registration);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Saved NGOs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'NGOs you\'ve registered with will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.explore),
            label: const Text('Explore NGOs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
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

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 150, height: 16, color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Container(width: 100, height: 12, color: Colors.grey.shade200),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNgoCard(
    Map<String, dynamic> ngo,
    String ngoId,
    Map<String, dynamic> registration,
  ) {
    final name = ngo['ngoName'] ?? ngo['name'] ?? 'Unknown NGO';
    final logoUrl = ngo['ngoLogo'] ?? ngo['logoUrl'] ?? ngo['profileImageUrl'];
    final location = ngo['headOfficeAddress'] ?? ngo['address'] ?? ngo['location'] ?? '';
    final category = ngo['category'] ?? ngo['focusArea'] ?? '';
    final role = registration['role'] ?? 'Volunteer';
    final joinedAt = registration['approvedAt'] ?? registration['createdAt'];

    return GestureDetector(
      onTap: () async {
        // Fetch the full NGO document and use fromFirestore
        try {
          final doc = await FirebaseFirestore.instance
              .collection('ngo_registrations')
              .doc(ngoId)
              .get();
          
          if (doc.exists) {
            final ngoData = NgoRegistrationRequest.fromFirestore(doc);
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NgoPublicProfileScreen(ngoData: ngoData),
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('Error loading NGO: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error loading NGO details')),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // NGO Logo
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primary.withOpacity(0.2)),
                    ),
                    child: logoUrl != null && logoUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.business, color: primary, size: 32),
                            ),
                          )
                        : Icon(Icons.business, color: primary, size: 32),
                  ),
                  const SizedBox(width: 16),
                  
                  // NGO Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 11,
                                color: primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        if (location.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  
                  // Arrow
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
            
            // Bottom section with role
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.badge,
                    size: 16,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Role: $role',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (joinedAt != null)
                    Text(
                      'Joined: ${_formatDate(joinedAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
    return '';
  }
}
