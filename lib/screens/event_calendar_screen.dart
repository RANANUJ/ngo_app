import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'campaign_detail_screen.dart';
import 'opportunity_detail_screen.dart';

class EventCalendarScreen extends StatefulWidget {
  final String ngoId;
  final String ngoName;

  const EventCalendarScreen({
    Key? key,
    required this.ngoId,
    required this.ngoName,
  }) : super(key: key);

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper method to format month and year
  String _formatMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Event Calendar',
          style: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'All Events'),
            Tab(text: 'Campaigns'),
            Tab(text: 'Opportunities'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Calendar Header
          _buildCalendarHeader(),
          // Calendar Grid
          _buildCalendarGrid(),
          const Divider(height: 1),
          // Events List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllEventsList(),
                _buildCampaignsList(),
                _buildOpportunitiesList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: primary),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month - 1,
                );
              });
            },
          ),
          Text(
            _formatMonthYear(_focusedMonth),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: primary),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month + 1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Column(
        children: [
          // Day names row
          Row(
            children: dayNames.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Calendar days
          ...List.generate(6, (weekIndex) {
            return Row(
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - startingWeekday + 1;
                final isValidDay = dayNumber >= 1 && dayNumber <= daysInMonth;
                final date = isValidDay
                    ? DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber)
                    : null;
                final isSelected = date != null &&
                    date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;
                final isToday = date != null &&
                    date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;

                return Expanded(
                  child: GestureDetector(
                    onTap: isValidDay
                        ? () => setState(() => _selectedDate = date!)
                        : null,
                    child: Container(
                      height: 36,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary
                            : isToday
                                ? primary.withOpacity(0.2)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday && !isSelected
                            ? Border.all(color: primary, width: 1)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          isValidDay ? dayNumber.toString() : '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? primary
                                    : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAllEventsList() {
    return StreamBuilder<List<QuerySnapshot>>(
      stream: _getCombinedEventsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return _buildEmptyState('No events found');
        }

        final campaigns = snapshot.data![0].docs;
        final opportunities = snapshot.data![1].docs;

        // Combine and sort by date
        final allEvents = [
          ...campaigns.map((doc) => _EventItem(
                id: doc.id,
                type: 'campaign',
                data: doc.data() as Map<String, dynamic>,
              )),
          ...opportunities.map((doc) => _EventItem(
                id: doc.id,
                type: 'opportunity',
                data: doc.data() as Map<String, dynamic>,
              )),
        ];

        allEvents.sort((a, b) {
          final aDate = (a.data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bDate = (b.data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bDate.compareTo(aDate);
        });

        if (allEvents.isEmpty) {
          return _buildEmptyState('No events found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allEvents.length,
          itemBuilder: (context, index) {
            final event = allEvents[index];
            return _buildEventCard(event);
          },
        );
      },
    );
  }

  Stream<List<QuerySnapshot>> _getCombinedEventsStream() {
    final campaignsStream = FirebaseFirestore.instance
        .collection('campaigns')
        .where('ngoId', isEqualTo: widget.ngoId)
        .snapshots();

    final opportunitiesStream = FirebaseFirestore.instance
        .collection('volunteer_opportunities')
        .where('ngoId', isEqualTo: widget.ngoId)
        .snapshots();

    return campaignsStream.asyncMap((campaigns) async {
      final opportunities = await opportunitiesStream.first;
      return [campaigns, opportunities];
    });
  }

  Widget _buildCampaignsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaigns')
          .where('ngoId', isEqualTo: widget.ngoId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final campaignDocs = snapshot.data?.docs ?? [];
        
        // Create a modifiable copy and sort by createdAt descending
        final campaigns = List<QueryDocumentSnapshot>.from(campaignDocs);
        campaigns.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aDate = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bDate = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bDate.compareTo(aDate);
        });

        if (campaigns.isEmpty) {
          return _buildEmptyState('No campaigns found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: campaigns.length,
          itemBuilder: (context, index) {
            final campaign = campaigns[index];
            return _buildEventCard(_EventItem(
              id: campaign.id,
              type: 'campaign',
              data: campaign.data() as Map<String, dynamic>,
            ));
          },
        );
      },
    );
  }

  Widget _buildOpportunitiesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('volunteer_opportunities')
          .where('ngoId', isEqualTo: widget.ngoId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final opportunityDocs = snapshot.data?.docs ?? [];
        
        // Create a modifiable copy and sort by createdAt descending
        final opportunities = List<QueryDocumentSnapshot>.from(opportunityDocs);
        opportunities.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aDate = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bDate = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bDate.compareTo(aDate);
        });

        if (opportunities.isEmpty) {
          return _buildEmptyState('No volunteer opportunities found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: opportunities.length,
          itemBuilder: (context, index) {
            final opportunity = opportunities[index];
            return _buildEventCard(_EventItem(
              id: opportunity.id,
              type: 'opportunity',
              data: opportunity.data() as Map<String, dynamic>,
            ));
          },
        );
      },
    );
  }

  Widget _buildEventCard(_EventItem event) {
    final data = event.data;
    final title = data['title'] ?? 'Untitled';
    final description = data['description'] ?? '';
    final images = List<String>.from(data['images'] ?? []);
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final status = data['status'] ?? 'active';
    final isCampaign = event.type == 'campaign';

    return GestureDetector(
      onTap: () {
        // Add the id to the data for the detail screens
        final dataWithId = Map<String, dynamic>.from(data);
        dataWithId['id'] = event.id;
        
        if (isCampaign) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CampaignDetailScreen(
                campaign: dataWithId,
                isNgoView: true,
              ),
            ),
          ).then((deleted) {
            if (deleted == true) {
              setState(() {});
            }
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OpportunityDetailScreen(
                opportunity: dataWithId,
                isNgoView: true,
              ),
            ),
          ).then((deleted) {
            if (deleted == true) {
              setState(() {});
            }
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  images.isNotEmpty
                      ? Image.network(
                          images.first,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 150,
                            color: Colors.grey.shade200,
                            child: Icon(
                              isCampaign ? Icons.campaign : Icons.volunteer_activism,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          height: 150,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(
                              isCampaign ? Icons.campaign : Icons.volunteer_activism,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                  // Type Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isCampaign
                            ? Colors.blue.withOpacity(0.9)
                            : Colors.green.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCampaign ? Icons.campaign : Icons.volunteer_activism,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCampaign ? 'Campaign' : 'Opportunity',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Status Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'active'
                            ? Colors.green
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        createdAt != null
                            ? _formatDate(createdAt)
                            : 'Date not available',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const Spacer(),
                      if (!isCampaign) ...[
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${data['volunteersNeeded'] ?? 0} volunteers needed',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.group,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${data['participants'] ?? 0} participants',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!isCampaign && data['location'] != null) ...[
                    const SizedBox(height: 8),
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
                            data['location'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create campaigns or volunteer opportunities\nto see them here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventItem {
  final String id;
  final String type; // 'campaign' or 'opportunity'
  final Map<String, dynamic> data;

  _EventItem({
    required this.id,
    required this.type,
    required this.data,
  });
}
