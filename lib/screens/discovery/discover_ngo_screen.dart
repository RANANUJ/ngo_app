import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngo_app/features/ngo/data/services/ngo_registration_service.dart';
import 'ngo/ngo_public_profile_screen.dart';

class DiscoverNgoScreen extends StatefulWidget {
  const DiscoverNgoScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverNgoScreen> createState() => _DiscoverNgoScreenState();
}

class _DiscoverNgoScreenState extends State<DiscoverNgoScreen> {
  static const Color primary = Color(0xFF0099B8);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          'Discover NGOs',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
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
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
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

          // NGO List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ngo_registrations')
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading NGOs',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No NGOs found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for approved NGOs',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter by search query
                final allNgos = snapshot.data!.docs;
                final filteredNgos = allNgos.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final ngoName = (data['ngoName'] ?? '').toString().toLowerCase();
                  final address = (data['headOfficeAddress'] ?? '').toString().toLowerCase();
                  final category = (data['category'] ?? '').toString().toLowerCase();
                  return ngoName.contains(_searchQuery) ||
                      address.contains(_searchQuery) ||
                      category.contains(_searchQuery);
                }).toList();

                if (filteredNgos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredNgos.length,
                  itemBuilder: (context, index) {
                    final doc = filteredNgos[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildNgoCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNgoCard(String id, Map<String, dynamic> data) {
    final ngoName = data['ngoName'] ?? 'NGO Name';
    final address = data['headOfficeAddress'] ?? 'Address not available';
    // Check for ngoLogo first (uploaded via NGO Details), then fallback to profileImageUrl
    final ngoLogo = data['ngoLogo'] ?? data['profileImageUrl'];

    return GestureDetector(
      onTap: () => _viewNgoDetails(id, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
          children: [
            // NGO Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Container(
                width: 100,
                height: 85,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ngoLogo != null && ngoLogo.isNotEmpty
                    ? Image.network(
                        ngoLogo,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage(ngoName);
                        },
                      )
                    : _buildPlaceholderImage(ngoName),
              ),
            ),

            // NGO Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#$ngoName',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Address: $address',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // View Details Button
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: OutlinedButton(
                onPressed: () => _viewNgoDetails(id, data),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(String ngoName) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, primary.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Power of NGOs',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'Making Change and Difference',
                style: TextStyle(
                  fontSize: 7,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _viewNgoDetails(String id, Map<String, dynamic> data) {
    // Convert map to NgoRegistrationRequest
    // Use ngoLogo first (uploaded via NGO Details), then fallback to profileImageUrl
    final logoUrl = data['ngoLogo'] ?? data['profileImageUrl'];
    
    // Convert string status to RegistrationStatus enum
    RegistrationStatus status = RegistrationStatus.approved;
    final statusString = data['status'] as String?;
    if (statusString == 'pending') {
      status = RegistrationStatus.pending;
    } else if (statusString == 'rejected') {
      status = RegistrationStatus.rejected;
    }
    
    final ngoData = NgoRegistrationRequest(
      id: id,
      ngoName: data['ngoName'] ?? '',
      registrationNo: data['registrationNo'] ?? '',
      ngoType: data['ngoType'] ?? '',
      category: data['category'] ?? '',
      yearOfEstablishment: data['yearOfEstablishment'] ?? '',
      headOfficeAddress: data['headOfficeAddress'] ?? '',
      branchOfficeAddress: data['branchOfficeAddress'] ?? '',
      officialPhone: data['officialPhone'] ?? '',
      websiteLink: data['websiteLink'] ?? '',
      contactPersonName: data['contactPersonName'] ?? '',
      designation: data['designation'] ?? '',
      mobileNo: data['mobileNo'] ?? '',
      email: data['email'] ?? '',
      idProofType: data['idProofType'] ?? '',
      missionVision: data['publicDescription'] ?? data['missionVision'] ?? '',
      areaOfWork: data['areaOfWork'] ?? '',
      activeVolunteers: data['activeVolunteers'] ?? '',
      achievements: data['achievements'] ?? '',
      idProofUploaded: data['idProofUploaded'] ?? false,
      registrationCertUploaded: data['registrationCertUploaded'] ?? false,
      panCardUploaded: data['panCardUploaded'] ?? false,
      certificate12A80GUploaded: data['certificate12A80GUploaded'] ?? false,
      pastWorkProofUploaded: data['pastWorkProofUploaded'] ?? false,
      status: status,
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profileImageUrl: logoUrl,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NgoPublicProfileScreen(
          ngoData: ngoData,
          isEditable: false,
        ),
      ),
    );
  }
}
