import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'campaign_detail_screen.dart';

class CampaignListScreen extends StatefulWidget {
  final String? ngoId; // If provided, show only this NGO's campaigns
  final bool isVolunteerView; // If true, show all active campaigns for volunteers

  const CampaignListScreen({
    Key? key,
    this.ngoId,
    this.isVolunteerView = false,
  }) : super(key: key);

  @override
  State<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends State<CampaignListScreen> {
  static const Color primary = Color(0xFF0099B8);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _demoDataSeeded = false;

  // Demo campaigns data
  final List<Map<String, dynamic>> _demoCampaigns = [
    {
      'title': 'Clean Water Initiative',
      'description': '''Providing clean and safe drinking water to rural communities across Maharashtra is our primary mission with this comprehensive water initiative campaign.

Access to clean water is a fundamental human right, yet millions of people in rural India still lack access to safe drinking water. Contaminated water sources lead to waterborne diseases, affecting the health and productivity of entire communities. Children are particularly vulnerable, with many falling ill and missing school due to preventable water-related illnesses.

Our Clean Water Initiative aims to transform this reality by implementing sustainable water solutions in 10 underserved villages. We will install advanced water purification systems, bore wells with filtration units, and rainwater harvesting structures. Each installation will be designed to serve 500+ families, ensuring long-term access to clean water.

Beyond infrastructure, we focus on community education about water hygiene, maintenance training for local technicians, and establishing village water committees for sustainable management. We partner with local governments and health departments to ensure our solutions align with regional development plans.

The impact of clean water extends far beyond health - it enables children to attend school regularly, women to pursue economic activities instead of walking miles for water, and communities to thrive with improved agricultural practices. Join us in creating a ripple effect of positive change that will benefit over 5,000 people and future generations.''',
      'category': 'Water & Sanitation',
      'status': 'active',
      'isActive': true,
      'targetAmount': 500000,
      'raisedAmount': 325000,
      'participantsCount': 45,
      'images': ['https://images.unsplash.com/photo-1541544537156-7627a7a4aa1c?w=800'],
      'location': 'Rural Maharashtra',
      'latitude': 19.7515,
      'longitude': 75.7139,
      'eventDate': DateTime.now().add(const Duration(days: 30)),
      'startDate': DateTime.now().subtract(const Duration(days: 15)),
      'endDate': DateTime.now().add(const Duration(days: 45)),
      'purpose': [
        'Provide safe and clean drinking water to 5,000+ rural residents',
        'Reduce waterborne diseases by 80% in target communities',
        'Empower women by eliminating long-distance water collection trips',
        'Enable children to attend school regularly without water-related illness',
        'Train local technicians for sustainable maintenance of water systems',
        'Establish community water management committees for long-term success',
        'Create awareness about water conservation and hygiene practices',
      ],
      'target': [
        'Install 10 water purification systems across 10 villages',
        'Construct 15 bore wells with advanced filtration units',
        'Build 5 rainwater harvesting structures for sustainability',
        'Train 50 local technicians in system maintenance',
        'Conduct 20 community awareness workshops on water hygiene',
        'Establish 10 village water committees with 100 trained members',
        'Achieve 95% household coverage in all target villages by project end',
      ],
    },
    {
      'title': 'Education for All',
      'description': '''Supporting underprivileged children with quality education is the cornerstone of building a brighter future for our nation. This comprehensive education initiative addresses the multiple barriers that prevent children from accessing quality education.

In India, millions of children from economically disadvantaged backgrounds are forced to drop out of school due to financial constraints, lack of resources, or family pressures. Many children who do attend school struggle with inadequate learning materials, overcrowded classrooms, and absence of proper guidance. This creates a cycle of poverty that perpetuates across generations.

Our Education for All campaign takes a holistic approach to breaking this cycle. We provide complete educational support including school supplies, uniforms, books, and digital learning tools. But we go beyond material support - we offer scholarships for deserving students, after-school tutoring programs, and mentorship from professionals in various fields.

We have established learning centers in underserved communities where children can access computers, libraries, and qualified tutors. Our weekend enrichment programs expose children to arts, sports, and life skills that traditional schools often overlook. We work closely with parents, conducting awareness sessions about the importance of education and involving them in their children's learning journey.

Special attention is given to girl child education, as we believe educating a girl transforms not just her life but her entire family and community. Our female mentorship program pairs young girls with successful women professionals who guide them through educational and career choices.

Through partnerships with schools, colleges, and corporate sponsors, we create pathways for higher education and vocational training. Every child deserves the opportunity to dream big and achieve their potential - join us in making quality education accessible to all.''',
      'category': 'Education',
      'status': 'active',
      'isActive': true,
      'targetAmount': 300000,
      'raisedAmount': 187500,
      'participantsCount': 78,
      'images': ['https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=800'],
      'location': 'Mumbai, Maharashtra',
      'latitude': 19.0760,
      'longitude': 72.8777,
      'eventDate': DateTime.now().add(const Duration(days: 14)),
      'startDate': DateTime.now().subtract(const Duration(days: 30)),
      'endDate': DateTime.now().add(const Duration(days: 60)),
      'purpose': [
        'Provide quality education access to 500+ underprivileged children',
        'Reduce school dropout rates by 70% in target communities',
        'Bridge the digital divide through technology-enabled learning',
        'Empower girl children through dedicated mentorship programs',
        'Create sustainable learning ecosystems in underserved areas',
        'Enable higher education pathways through scholarships and guidance',
        'Build life skills and confidence alongside academic excellence',
      ],
      'target': [
        'Distribute school supplies and uniforms to 500 students annually',
        'Award 100 merit-based scholarships for higher education',
        'Establish 5 community learning centers with computer facilities',
        'Conduct 200 after-school tutoring sessions per month',
        'Train 50 volunteer teachers from local communities',
        'Achieve 90% attendance rate among enrolled students',
        'Ensure 80% of supported students pass with first division grades',
      ],
    },
    {
      'title': 'Tree Plantation Drive',
      'description': '''Join our ambitious mission to plant 10,000 trees across the city and create a greener, healthier environment for current and future generations. Climate change and rapid urbanization have severely impacted our city's green cover, leading to rising temperatures, air pollution, and loss of biodiversity.

Trees are nature's most effective solution to multiple environmental challenges. They absorb carbon dioxide, produce oxygen, reduce air pollution, provide shade, prevent soil erosion, and support wildlife. A single mature tree can absorb up to 48 pounds of carbon dioxide per year and release enough oxygen for two people. Yet, we continue to lose trees at an alarming rate to development and negligence.

Our Tree Plantation Drive is more than just planting saplings - it's about creating sustainable urban forests that will thrive for decades. We carefully select native species that are well-adapted to local climate conditions, require minimal maintenance, and provide maximum ecological benefits. Each planting location is assessed for soil quality, water availability, and sunlight to ensure optimal growth.

We engage schools, colleges, corporate offices, and residential communities in our plantation activities. Every participant plants a tree and receives training on its care. We use geo-tagging technology to track each planted tree and monitor its growth through our volunteer network. Regular maintenance drives ensure saplings receive adequate water and protection during their vulnerable early years.

Beyond environmental benefits, our initiative creates green jobs for local nurseries and gardeners. We establish tree banks where communities can source saplings for their own plantation activities. Educational workshops teach children and adults about the importance of trees and simple ways to contribute to environmental conservation.

Our vision extends beyond numbers - we aim to create a culture of environmental stewardship where every citizen takes responsibility for nurturing our urban forests. Together, we can combat climate change one tree at a time.''',
      'category': 'Environment',
      'status': 'active',
      'isActive': true,
      'targetAmount': 150000,
      'raisedAmount': 98000,
      'participantsCount': 156,
      'images': ['https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=800'],
      'location': 'Pune, Maharashtra',
      'latitude': 18.5204,
      'longitude': 73.8567,
      'eventDate': DateTime.now().add(const Duration(days: 7)),
      'startDate': DateTime.now(),
      'endDate': DateTime.now().add(const Duration(days: 30)),
      'purpose': [
        'Combat climate change by increasing urban green cover by 15%',
        'Reduce air pollution levels in high-traffic areas of the city',
        'Create natural habitats for birds and beneficial insects',
        'Lower urban temperatures through strategic shade tree planting',
        'Educate 10,000 citizens about environmental conservation',
        'Build a community of environmental stewards and tree guardians',
        'Establish sustainable tree nurseries for continuous plantation',
      ],
      'target': [
        'Plant 10,000 native trees across 50 locations in the city',
        'Achieve 85% survival rate through proper maintenance programs',
        'Engage 5,000 volunteers from schools, colleges, and corporates',
        'Establish 3 community tree nurseries with 5,000 sapling capacity',
        'Conduct 30 environmental awareness workshops in schools',
        'Create 100 green jobs for local nurseries and maintenance staff',
        'Geo-tag and monitor all planted trees through mobile app tracking',
      ],
    },
    {
      'title': 'Women Empowerment Program',
      'description': '''Empowering women through comprehensive skill development and entrepreneurship training is essential for creating an equitable society. This transformative program addresses the systemic barriers that prevent women from achieving economic independence and social equality.

Despite significant progress in women's rights, millions of women in India still face limited access to education, employment opportunities, and financial resources. Many women, especially in rural and semi-urban areas, are confined to domestic roles without avenues for personal growth or income generation. Economic dependence often leads to vulnerability and limited decision-making power within families and communities.

Our Women Empowerment Program takes a multi-faceted approach to breaking these barriers. We offer vocational training in high-demand skills including tailoring, beauty services, food processing, handicrafts, computer operations, and digital marketing. Training programs are designed to be flexible, accommodating women's domestic responsibilities while ensuring comprehensive skill development.

Beyond skill training, we provide end-to-end entrepreneurship support. This includes business planning workshops, access to micro-loans and credit facilities, marketing assistance, and ongoing mentorship from successful women entrepreneurs. We help women form self-help groups that provide peer support, collective savings, and group lending opportunities.

Financial literacy is a core component of our program. We educate women about banking, savings, investments, and government schemes available for women entrepreneurs. Many women open their first bank accounts through our program, taking their first steps toward financial independence.

We address social barriers through confidence-building workshops, legal awareness sessions, and community sensitization programs. Our network of successful program graduates serves as role models and mentors for new participants. We celebrate and publicize women's success stories to inspire others and change community perceptions about women's capabilities.

Our vision is to create a ripple effect where empowered women uplift their families, inspire their daughters, and transform their communities. When women thrive, entire societies prosper.''',
      'category': 'Women Empowerment',
      'status': 'active',
      'isActive': true,
      'targetAmount': 400000,
      'raisedAmount': 280000,
      'participantsCount': 34,
      'images': ['https://images.unsplash.com/photo-1573164713714-d95e436ab8d6?w=800'],
      'location': 'Delhi NCR',
      'latitude': 28.7041,
      'longitude': 77.1025,
      'eventDate': DateTime.now().add(const Duration(days: 21)),
      'startDate': DateTime.now().subtract(const Duration(days: 45)),
      'endDate': DateTime.now().add(const Duration(days: 90)),
      'purpose': [
        'Enable 500 women to achieve financial independence through skill development',
        'Create women entrepreneurs who generate employment in their communities',
        'Break the cycle of poverty through sustainable income generation',
        'Build confidence and leadership skills in women from marginalized backgrounds',
        'Promote financial literacy and banking access among rural women',
        'Create peer support networks through self-help groups',
        'Challenge social norms and expand opportunities for women and girls',
      ],
      'target': [
        'Train 500 women in market-relevant vocational skills',
        'Help 200 women start their own micro-enterprises',
        'Facilitate micro-loans totaling ₹50 lakhs for women entrepreneurs',
        'Form 25 self-help groups with 250 active members',
        'Open 400 first-time bank accounts for program participants',
        'Conduct 50 financial literacy and legal awareness workshops',
        'Achieve 75% income increase for trained women within one year',
      ],
    },
    {
      'title': 'Food Distribution Drive',
      'description': '''Providing nutritious meals to homeless and underprivileged communities is a fundamental act of humanity that addresses one of the most basic human needs. Our Food Distribution Drive operates on the belief that no person should go hungry in a country that produces surplus food.

Hunger and malnutrition remain persistent challenges in urban India. Homeless individuals, daily wage workers, elderly without family support, and families in urban slums often struggle to afford even one nutritious meal a day. Children from these communities suffer from malnutrition that affects their physical and cognitive development, creating lifelong disadvantages.

Our comprehensive food program operates through multiple channels to maximize reach and impact. We run daily community kitchens in strategic locations serving freshly prepared, nutritious meals. Our mobile food vans reach remote urban pockets, railway stations, and areas with high concentrations of homeless individuals. During festivals and special occasions, we organize large-scale feeding events that serve thousands of meals.

Quality and nutrition are paramount in our operations. Our menus are designed by nutritionists to provide balanced meals with adequate proteins, carbohydrates, vitamins, and minerals. We source fresh ingredients from local vendors, supporting small businesses while ensuring food quality. Strict hygiene standards are maintained in food preparation and distribution.

We partner with restaurants, hotels, wedding caterers, and corporate cafeterias to rescue surplus food that would otherwise go to waste. This food is immediately collected, quality-checked, and distributed to those in need. Our food rescue program prevents food waste while feeding the hungry - a win-win solution.

Beyond immediate hunger relief, we work to address root causes of food insecurity. We connect eligible families with government food security schemes, help them obtain ration cards, and provide information about nutrition and affordable cooking. Our urban farming initiatives teach communities to grow vegetables in small spaces, creating sustainable food sources.

Every meal we serve is delivered with dignity and respect. We believe that the manner of giving is as important as the giving itself. Join us in ensuring that no one in our city sleeps hungry.''',
      'category': 'Food & Hunger',
      'status': 'active',
      'isActive': true,
      'targetAmount': 200000,
      'raisedAmount': 145000,
      'participantsCount': 89,
      'images': ['https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=800'],
      'location': 'Bangalore, Karnataka',
      'latitude': 12.9716,
      'longitude': 77.5946,
      'eventDate': DateTime.now().add(const Duration(days: 3)),
      'startDate': DateTime.now().subtract(const Duration(days: 60)),
      'endDate': DateTime.now().add(const Duration(days: 120)),
      'purpose': [
        'Ensure zero hunger among homeless and underprivileged in target areas',
        'Provide nutritionally balanced meals to combat malnutrition',
        'Rescue surplus food from waste and redirect to those in need',
        'Create dignity in food distribution through respectful service',
        'Connect food-insecure families with government welfare schemes',
        'Build sustainable community food systems through urban farming',
        'Raise awareness about food waste and hunger in urban areas',
      ],
      'target': [
        'Serve 50,000 nutritious meals monthly across all distribution points',
        'Operate 5 community kitchens in high-need neighborhoods',
        'Deploy 3 mobile food vans covering 15 locations daily',
        'Rescue 2,000 kg of surplus food monthly from partner establishments',
        'Connect 500 families with government ration card and food schemes',
        'Train 100 families in urban farming and nutrition practices',
        'Engage 200 regular volunteers in food preparation and distribution',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.ngoId != null && !widget.isVolunteerView) {
      _seedDemoCampaignsIfNeeded();
    }
  }

  Future<void> _seedDemoCampaignsIfNeeded() async {
    if (_demoDataSeeded || widget.ngoId == null) return;
    
    try {
      // Check how many campaigns exist for this NGO
      final snapshot = await FirebaseFirestore.instance
          .collection('campaigns')
          .where('ngoId', isEqualTo: widget.ngoId)
          .get();
      
      // Get NGO name
      String ngoName = 'NGO';
      try {
        final ngoDoc = await FirebaseFirestore.instance
            .collection('ngo_registrations')
            .doc(widget.ngoId)
            .get();
        if (ngoDoc.exists) {
          ngoName = ngoDoc.data()?['ngoName'] ?? 'NGO';
        }
      } catch (e) {
        debugPrint('Error getting NGO name: $e');
      }

      // First, fix any existing demo campaigns that have wrong field names (purposes -> purpose, targets -> target)
      final batch = FirebaseFirestore.instance.batch();
      int updatedCount = 0;
      int addedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        // Check if this campaign has old field names
        if (data.containsKey('purposes') || data.containsKey('targets')) {
          final updates = <String, dynamic>{};
          if (data.containsKey('purposes')) {
            updates['purpose'] = data['purposes'];
            updates['purposes'] = FieldValue.delete();
          }
          if (data.containsKey('targets')) {
            updates['target'] = data['targets'];
            updates['targets'] = FieldValue.delete();
          }
          batch.update(doc.reference, updates);
          updatedCount++;
        }
      }

      // Only seed if there are fewer than 3 campaigns (add more demo data)
      if (snapshot.docs.length < 3) {
        // Get existing campaign titles to avoid duplicates
        final existingTitles = snapshot.docs.map((doc) {
          final data = doc.data();
          return (data['title'] ?? '').toString().toLowerCase();
        }).toSet();

        // Seed demo campaigns that don't already exist
        for (final campaign in _demoCampaigns) {
          final title = (campaign['title'] ?? '').toString().toLowerCase();
          if (!existingTitles.contains(title)) {
            final docRef = FirebaseFirestore.instance.collection('campaigns').doc();
            batch.set(docRef, {
              ...campaign,
              'ngoId': widget.ngoId,
              'ngoName': ngoName,
              'createdAt': FieldValue.serverTimestamp(),
              'eventDate': campaign['eventDate'] != null ? Timestamp.fromDate(campaign['eventDate']) : null,
              'startDate': campaign['startDate'] != null ? Timestamp.fromDate(campaign['startDate']) : null,
              'endDate': campaign['endDate'] != null ? Timestamp.fromDate(campaign['endDate']) : null,
            });
            addedCount++;
          }
        }
      }
      
      if (addedCount > 0 || updatedCount > 0) {
        await batch.commit();
        debugPrint('Demo campaigns: Added $addedCount, Updated $updatedCount');
      }
      _demoDataSeeded = true;
    } catch (e) {
      debugPrint('Error seeding demo campaigns: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _getCampaignsQuery() {
    // Use simple queries without composite indexes
    if (widget.ngoId != null && !widget.isVolunteerView) {
      // NGO viewing their own campaigns - simple where query
      return FirebaseFirestore.instance
          .collection('campaigns')
          .where('ngoId', isEqualTo: widget.ngoId);
    } else if (widget.isVolunteerView) {
      // Volunteer viewing all active campaigns
      return FirebaseFirestore.instance
          .collection('campaigns')
          .where('status', isEqualTo: 'active');
    }
    
    // Default - all campaigns
    return FirebaseFirestore.instance.collection('campaigns');
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
          widget.isVolunteerView ? 'CSR Campaigns' : 'My Campaigns',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_border, color: primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search campaigns',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Campaign list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getCampaignsQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                
                // Filter by search query and sort by createdAt locally
                var campaigns = docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final description = (data['description'] ?? '').toString().toLowerCase();
                  return title.contains(_searchQuery) || description.contains(_searchQuery);
                }).toList();

                // Sort by createdAt descending (newest first)
                campaigns.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['createdAt'] as Timestamp?;
                  final bTime = bData['createdAt'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                if (campaigns.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No campaigns found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        if (!widget.isVolunteerView) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Create your first campaign!',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: campaigns.length,
                  itemBuilder: (context, index) {
                    final doc = campaigns[index];
                    final campaign = doc.data() as Map<String, dynamic>;
                    campaign['id'] = doc.id;
                    return _buildCampaignCard(campaign);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    final images = List<String>.from(campaign['images'] ?? []);
    final imageUrl = images.isNotEmpty ? images[0] : '';
    final eventDate = (campaign['eventDate'] as Timestamp?)?.toDate();
    final location = campaign['location'] as String?;
    final latitude = campaign['latitude'] as double?;
    final longitude = campaign['longitude'] as double?;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CampaignDetailScreen(
              campaign: campaign,
              isVolunteerView: widget.isVolunteerView,
              isNgoView: !widget.isVolunteerView,
            ),
          ),
        ).then((result) {
          if (result == true) {
            setState(() {});
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campaign image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 80,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 100,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.campaign, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),

              // Campaign details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign['title'] ?? 'Campaign',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      campaign['description'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Date row
                    if (eventDate != null)
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: primary),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(eventDate),
                            style: TextStyle(
                              fontSize: 11,
                              color: primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    // Location row
                    if (location != null && location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _openLocation(location, latitude, longitude),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 12, color: const Color(0xFF0099B8)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(0xFF0099B8),
                                  fontWeight: FontWeight.w500,
                                  decoration: (latitude != null && longitude != null)
                                      ? TextDecoration.underline
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (latitude != null && longitude != null)
                              Icon(Icons.open_in_new, size: 10, color: const Color(0xFF0099B8)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${campaign['participants'] ?? '0'}+ joined',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (widget.isVolunteerView && campaign['ngoName'] != null) ...[
                          const Spacer(),
                          Flexible(
                            child: Text(
                              'by ${campaign['ngoName']}',
                              style: TextStyle(
                                fontSize: 10,
                                color: primary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _openLocation(String address, double? lat, double? lng) async {
    String url;
    if (lat != null && lng != null) {
      // Use coordinates
      url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    } else {
      // Use address
      url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    }
    
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
