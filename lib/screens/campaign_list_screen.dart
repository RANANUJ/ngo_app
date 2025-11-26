import 'package:flutter/material.dart';
import 'campaign_detail_screen.dart';

class CampaignListScreen extends StatefulWidget {
  const CampaignListScreen({Key? key}) : super(key: key);

  @override
  State<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends State<CampaignListScreen> {
  static const Color primary = Color(0xFF0099B8);
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> campaigns = [
    {
      'title': 'Yoga camp',
      'description': 'A community yoga camp designed to promote physical wellness, mental peace, and healthy living.',
      'participants': '250+',
      'images': [
        'https://images.unsplash.com/photo-1599901860904-17e6ed7083a0?w=800',
        'https://images.unsplash.com/photo-1545205597-3d9d02c29597?w=800',
      ],
      'purpose': [
        'To encourage people to adopt yoga as a daily habit for overall well-being.',
        'To build community bonding through shared health activities.',
      ],
      'target': [
        'Local residents of all age groups (youth, adults, elderly).',
        'Special focus on individuals dealing with stress, anxiety, or sedentary lifestyles.',
      ],
    },
    {
      'title': 'Yoga camp',
      'description': 'A community yoga camp designed to promote physical wellness, mental peace, and healthy living.',
      'participants': '250+',
      'images': [
        'https://images.unsplash.com/photo-1599901860904-17e6ed7083a0?w=800',
      ],
      'purpose': [
        'To encourage people to adopt yoga as a daily habit for overall well-being.',
        'To build community bonding through shared health activities.',
      ],
      'target': [
        'Local residents of all age groups (youth, adults, elderly).',
        'Special focus on individuals dealing with stress.',
      ],
    },
    {
      'title': 'Yoga camp',
      'description': 'A community yoga camp designed to promote physical wellness, mental peace, and healthy living.',
      'participants': '250+',
      'images': [
        'https://images.unsplash.com/photo-1599901860904-17e6ed7083a0?w=800',
      ],
      'purpose': [
        'To encourage people to adopt yoga as a daily habit for overall well-being.',
        'To build community bonding through shared health activities.',
      ],
      'target': [
        'Local residents of all age groups (youth, adults, elderly).',
        'Special focus on individuals dealing with stress.',
      ],
    },
    {
      'title': 'Yoga camp',
      'description': 'A community yoga camp designed to promote physical wellness, mental peace, and healthy living.',
      'participants': '250+',
      'images': [
        'https://images.unsplash.com/photo-1599901860904-17e6ed7083a0?w=800',
      ],
      'purpose': [
        'To encourage people to adopt yoga as a daily habit for overall well-being.',
        'To build community bonding through shared health activities.',
      ],
      'target': [
        'Local residents of all age groups (youth, adults, elderly).',
        'Special focus on individuals dealing with stress.',
      ],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Campaign',
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
              decoration: InputDecoration(
                hintText: 'Search',
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: campaigns.length + 1, // +1 for "See more" button
              itemBuilder: (context, index) {
                if (index == campaigns.length) {
                  // See more button
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {},
                          icon: Text(
                            'See more',
                            style: TextStyle(color: primary, fontWeight: FontWeight.w500),
                          ),
                          label: Icon(Icons.keyboard_arrow_down, color: primary),
                        ),
                      ],
                    ),
                  );
                }

                final campaign = campaigns[index];
                return _buildCampaignCard(campaign);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CampaignDetailScreen(campaign: campaign),
          ),
        );
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
                child: Image.network(
                  campaign['images'][0],
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Campaign details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign['title'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      campaign['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${campaign['participants']} people joined',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
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
}
