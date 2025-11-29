import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityEventsScreen extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? userPhoto;
  final String userType;

  const CommunityEventsScreen({
    Key? key,
    this.userId,
    this.userName,
    this.userPhoto,
    required this.userType,
  }) : super(key: key);

  @override
  State<CommunityEventsScreen> createState() => _CommunityEventsScreenState();
}

class _CommunityEventsScreenState extends State<CommunityEventsScreen> {
  static const Color primary = Color(0xFF0099B8);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      color: primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Explore Events Section
            _buildSectionHeader('Explore Events', () {}),
            const SizedBox(height: 12),
            _buildEventCategories(),
            const SizedBox(height: 24),
            // Upcoming Events Section
            _buildSectionHeader('Upcoming Events', () {}),
            const SizedBox(height: 12),
            _buildUpcomingEvents(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See All',
              style: TextStyle(
                fontSize: 14,
                color: primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCategories() {
    final categories = [
      {'icon': Icons.video_call, 'label': 'Webinar'},
      {'icon': Icons.construction, 'label': 'Workshop'},
      {'icon': Icons.hub, 'label': 'Network Events'},
      {'icon': Icons.groups, 'label': 'Career Fairs'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: categories.map((category) {
          return _buildCategoryItem(
            category['icon'] as IconData,
            category['label'] as String,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primary, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingEvents() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_events')
          .where('eventDate', isGreaterThanOrEqualTo: Timestamp.now())
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Fallback to campaigns and opportunities
          return _buildCombinedEvents();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data?.docs ?? [];

        if (events.isEmpty) {
          return _buildCombinedEvents();
        }

        return SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final data = events[index].data() as Map<String, dynamic>;
              data['id'] = events[index].id;
              return _buildEventCard(data);
            },
          ),
        );
      },
    );
  }

  Widget _buildCombinedEvents() {
    return FutureBuilder(
      future: Future.wait([
        FirebaseFirestore.instance
            .collection('campaigns')
            .where('eventDate', isGreaterThanOrEqualTo: Timestamp.now())
            .limit(5)
            .get(),
        FirebaseFirestore.instance
            .collection('volunteer_opportunities')
            .where('eventDate', isGreaterThanOrEqualTo: Timestamp.now())
            .limit(5)
            .get(),
      ]),
      builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> allEvents = [];

        // Add campaigns
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          for (var doc in snapshot.data![0].docs) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            data['eventType'] = 'Campaign';
            allEvents.add(data);
          }

          // Add opportunities
          if (snapshot.data!.length > 1) {
            for (var doc in snapshot.data![1].docs) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              data['eventType'] = 'Volunteer';
              allEvents.add(data);
            }
          }
        }

        // Sort by date
        allEvents.sort((a, b) {
          final aDate = a['eventDate'] as Timestamp?;
          final bDate = b['eventDate'] as Timestamp?;
          if (aDate == null || bDate == null) return 0;
          return aDate.compareTo(bDate);
        });

        if (allEvents.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No upcoming events',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allEvents.length,
            itemBuilder: (context, index) {
              return _buildEventCard(allEvents[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final title = event['title'] ?? event['name'] ?? 'Event';
    final description = event['description'] ?? '';
    final imageUrl = event['imageUrl'] ?? (event['images'] as List?)?.firstOrNull;
    final eventDate = (event['eventDate'] as Timestamp?)?.toDate();
    final eventType = event['eventType'] ?? 'Event';

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl != null && imageUrl.toString().isNotEmpty
                    ? Image.network(
                        imageUrl.toString(),
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 100,
                          color: primary.withOpacity(0.2),
                          child: Center(
                            child: Icon(Icons.event, color: primary, size: 40),
                          ),
                        ),
                      )
                    : Container(
                        height: 100,
                        color: primary.withOpacity(0.2),
                        child: Center(
                          child: Icon(Icons.event, color: primary, size: 40),
                        ),
                      ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: eventType == 'Campaign' ? primary : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    eventType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  if (eventDate != null)
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: primary),
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
                ],
              ),
            ),
          ),
        ],
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
}
