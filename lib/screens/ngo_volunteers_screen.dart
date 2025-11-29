import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NgoVolunteersScreen extends StatefulWidget {
  final String ngoId;
  final String ngoName;
  final bool isEmbedded; // If true, no Scaffold/AppBar

  const NgoVolunteersScreen({
    Key? key,
    required this.ngoId,
    required this.ngoName,
    this.isEmbedded = false,
  }) : super(key: key);

  @override
  State<NgoVolunteersScreen> createState() => _NgoVolunteersScreenState();
}

class _NgoVolunteersScreenState extends State<NgoVolunteersScreen> {
  static const Color primary = Color(0xFF0099B8);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTab = 0; // 0 = My Volunteers, 1 = Requests

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search here...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
              suffixIcon: Icon(Icons.mic, color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Tab Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTab == 0 ? primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: primary,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'My Volunteers',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTab == 0 ? Colors.white : primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTab == 1 ? primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: primary,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _selectedTab == 1 ? 'Sended Request' : 'Request',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTab == 1 ? Colors.white : primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Volunteer List
        Expanded(
          child: _selectedTab == 0
              ? _buildMyVolunteersList()
              : _buildRequestsList(),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Volunteers',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: content,
    );
  }

  Widget _buildMyVolunteersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('volunteer_requests')
          .where('ngoId', isEqualTo: widget.ngoId)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading volunteers',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No volunteers yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Accepted volunteers will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        final volunteers = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['volunteerName'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: volunteers.length,
          itemBuilder: (context, index) {
            final doc = volunteers[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildVolunteerCard(doc.id, data, isRequest: false);
          },
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('volunteer_requests')
          .where('ngoId', isEqualTo: widget.ngoId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading requests',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No pending requests',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Volunteer requests will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['volunteerName'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final doc = requests[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildVolunteerCard(doc.id, data, isRequest: true);
          },
        );
      },
    );
  }

  Widget _buildVolunteerCard(String docId, Map<String, dynamic> data, {required bool isRequest}) {
    final name = data['volunteerName'] ?? 'Unknown';
    final volunteering = data['volunteeringFor'] ?? 'General volunteering';
    final location = data['location'] ?? 'Location not specified';
    final experience = data['experience'] ?? 'Not specified';
    final volunteerId = data['volunteerId'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image - Fetch from volunteers collection
          _buildVolunteerAvatar(volunteerId, data['volunteerPhotoUrl']),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 4),
                _buildInfoRow('Volunteering', volunteering),
                _buildInfoRow('Location', location),
                _buildInfoRow('Experience', experience),
              ],
            ),
          ),

          // Accept Button (only for requests)
          if (isRequest)
            ElevatedButton(
              onPressed: () => _acceptRequest(docId, data),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Accept',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Build volunteer avatar - fetches photo from volunteers collection
  Widget _buildVolunteerAvatar(String? volunteerId, String? fallbackPhotoUrl) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: primary.withOpacity(0.1),
      ),
      child: volunteerId != null
          ? FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('volunteers')
                  .doc(volunteerId)
                  .get(),
              builder: (context, snapshot) {
                String? photoUrl;
                
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  photoUrl = data?['photoUrl'];
                }
                
                // Fallback to request photo URL if not in volunteers collection
                photoUrl ??= fallbackPhotoUrl;
                
                if (photoUrl != null && photoUrl.isNotEmpty) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primary,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                    ),
                  );
                }
                return _buildDefaultAvatar();
              },
            )
          : _buildDefaultAvatar(),
    );
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Icon(Icons.person, color: primary, size: 30),
    );
  }

  Future<void> _acceptRequest(String docId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('volunteer_requests')
          .doc(docId)
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data['volunteerName']} has been accepted as a volunteer!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
