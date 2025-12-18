import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VolunteerMyEventsScreen extends StatefulWidget {
  const VolunteerMyEventsScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerMyEventsScreen> createState() => _VolunteerMyEventsScreenState();
}

class _VolunteerMyEventsScreenState extends State<VolunteerMyEventsScreen> 
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Events'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _userId == null
          ? const Center(child: Text('Please login to view your events'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEventsList('upcoming'),
                _buildEventsList('ongoing'),
                _buildEventsList('completed'),
              ],
            ),
    );
  }

  Widget _buildEventsList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('event_participants')
          .where('userId', isEqualTo: _userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final participations = snapshot.data?.docs ?? [];

        if (participations.isEmpty) {
          return _buildEmptyState(status);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: participations.length,
          itemBuilder: (context, index) {
            final participation = participations[index].data() as Map<String, dynamic>;
            final eventId = participation['eventId'] as String?;

            if (eventId == null) {
              return const SizedBox.shrink();
            }

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('events')
                  .doc(eventId)
                  .get(),
              builder: (context, eventSnapshot) {
                if (eventSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingCard();
                }

                if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                final event = eventSnapshot.data!.data() as Map<String, dynamic>;
                final eventStatus = _getEventStatus(event);

                // Filter by status
                if (eventStatus != status) {
                  return const SizedBox.shrink();
                }

                return _buildEventCard(event, participation, eventId, status);
              },
            );
          },
        );
      },
    );
  }

  String _getEventStatus(Map<String, dynamic> event) {
    final now = DateTime.now();
    final startDate = (event['startDate'] as Timestamp?)?.toDate();
    final endDate = (event['endDate'] as Timestamp?)?.toDate();
    
    if (startDate == null) return 'upcoming';
    
    if (now.isBefore(startDate)) {
      return 'upcoming';
    } else if (endDate != null && now.isAfter(endDate)) {
      return 'completed';
    } else {
      return 'ongoing';
    }
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;
    
    switch (status) {
      case 'upcoming':
        message = 'No upcoming events';
        icon = Icons.event_available;
        break;
      case 'ongoing':
        message = 'No ongoing events';
        icon = Icons.event;
        break;
      case 'completed':
        message = 'No completed events';
        icon = Icons.event_busy;
        break;
      default:
        message = 'No events found';
        icon = Icons.event_note;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join events to see them here',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
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
            width: 80,
            height: 80,
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

  Widget _buildEventCard(
    Map<String, dynamic> event,
    Map<String, dynamic> participation,
    String eventId,
    String status,
  ) {
    final title = event['title'] ?? event['name'] ?? 'Untitled Event';
    final description = event['description'] ?? '';
    final imageUrl = event['imageUrl'] as String?;
    final location = event['location'] ?? event['venue'] ?? 'Location TBD';
    final startDate = event['startDate'] as Timestamp?;
    final endDate = event['endDate'] as Timestamp?;
    final ngoName = event['ngoName'] ?? 'Unknown Organizer';

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 150,
                          color: primary.withOpacity(0.1),
                          child: Icon(Icons.event, size: 50, color: primary),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: 150,
                        color: primary.withOpacity(0.1),
                        child: Icon(Icons.event, size: 50, color: primary),
                      ),
                // Status Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Organizer
                Row(
                  children: [
                    Icon(Icons.business, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ngoName,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Description
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 12),

                // Date & Time
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatDateRange(startDate, endDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'upcoming':
        return Colors.blue;
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'upcoming':
        return 'Upcoming';
      case 'ongoing':
        return 'Ongoing';
      case 'completed':
        return 'Completed';
      default:
        return status.toUpperCase();
    }
  }

  String _formatDateRange(Timestamp? start, Timestamp? end) {
    if (start == null) return 'Date TBD';
    
    final startDate = start.toDate();
    final formatter = DateFormat('MMM dd, yyyy • hh:mm a');
    
    if (end == null) {
      return formatter.format(startDate);
    }
    
    final endDate = end.toDate();
    
    if (startDate.day == endDate.day && 
        startDate.month == endDate.month && 
        startDate.year == endDate.year) {
      return '${DateFormat('MMM dd, yyyy').format(startDate)} • ${DateFormat('hh:mm a').format(startDate)} - ${DateFormat('hh:mm a').format(endDate)}';
    }
    
    return '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}';
  }
}
