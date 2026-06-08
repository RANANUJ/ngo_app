import 'package:ngo_app/core/utils/network/network_utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class VolunteerEventsScreen extends StatefulWidget {
  const VolunteerEventsScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerEventsScreen> createState() => _VolunteerEventsScreenState();
}

class _VolunteerEventsScreenState extends State<VolunteerEventsScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _eventsMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all campaigns (remove isActive filter to get all)
      final campaignsSnapshot = await FirebaseFirestore.instance
          .collection('campaigns')
          .get();

      // Load all volunteer opportunities (remove status filter)
      final opportunitiesSnapshot = await FirebaseFirestore.instance
          .collection('opportunities')
          .get();

      // Load community events
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('community_events')
          .get();

      Map<DateTime, List<Map<String, dynamic>>> tempMap = {};

      // Process campaigns
      for (var doc in campaignsSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['type'] = 'campaign';
        
        DateTime? eventDate;
        if (data['startDate'] != null) {
          eventDate = (data['startDate'] as Timestamp).toDate();
        } else if (data['createdAt'] != null) {
          eventDate = (data['createdAt'] as Timestamp).toDate();
        }
        
        if (eventDate != null) {
          final dateKey = DateTime(eventDate.year, eventDate.month, eventDate.day);
          tempMap[dateKey] = [...(tempMap[dateKey] ?? []), data];
        }
      }

      // Process opportunities
      for (var doc in opportunitiesSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['type'] = 'opportunity';
        
        DateTime? eventDate;
        if (data['date'] != null) {
          eventDate = (data['date'] as Timestamp).toDate();
        } else if (data['createdAt'] != null) {
          eventDate = (data['createdAt'] as Timestamp).toDate();
        }
        
        if (eventDate != null) {
          final dateKey = DateTime(eventDate.year, eventDate.month, eventDate.day);
          tempMap[dateKey] = [...(tempMap[dateKey] ?? []), data];
        }
      }

      // Process community events
      for (var doc in eventsSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['type'] = 'event';
        
        DateTime? eventDate;
        if (data['eventDate'] != null) {
          eventDate = (data['eventDate'] as Timestamp).toDate();
        } else if (data['date'] != null) {
          eventDate = (data['date'] as Timestamp).toDate();
        }
        
        if (eventDate != null) {
          final dateKey = DateTime(eventDate.year, eventDate.month, eventDate.day);
          tempMap[dateKey] = [...(tempMap[dateKey] ?? []), data];
        }
      }

      setState(() {
        _eventsMap = tempMap;
        _isLoading = false;
      });
    } catch (e) {
      secureLog('Error loading events: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getEventsForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return _eventsMap[dateKey] ?? [];
  }

  List<Map<String, dynamic>> _getAllEvents() {
    List<Map<String, dynamic>> allEvents = [];
    _eventsMap.forEach((date, events) {
      allEvents.addAll(events);
    });
    // Sort by date
    allEvents.sort((a, b) {
      final aDate = _getEventDate(a);
      final bDate = _getEventDate(b);
      if (aDate == null || bDate == null) return 0;
      return aDate.compareTo(bDate);
    });
    return allEvents;
  }

  DateTime? _getEventDate(Map<String, dynamic> event) {
    if (event['startDate'] != null) return (event['startDate'] as Timestamp).toDate();
    if (event['date'] != null) return (event['date'] as Timestamp).toDate();
    if (event['eventDate'] != null) return (event['eventDate'] as Timestamp).toDate();
    if (event['createdAt'] != null) return (event['createdAt'] as Timestamp).toDate();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Events Calendar',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.today, color: primary),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
                _focusedMonth = DateTime.now();
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primary,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'All Events'),
            Tab(text: 'Campaigns'),
            Tab(text: 'Opportunities'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEvents,
              color: primary,
              child: Column(
                children: [
                  // Calendar Section
                  _buildCalendarSection(),
                  // Events List
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEventsList(null), // All events
                        _buildEventsList('campaign'),
                        _buildEventsList('opportunity'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Month Navigation
          _buildMonthNavigation(),
          // Weekday Headers
          _buildWeekdayHeaders(),
          // Calendar Grid
          _buildCalendarGrid(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chevron_left, color: primary, size: 20),
            ),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
              });
            },
          ),
          GestureDetector(
            onTap: () => _showMonthPicker(),
            child: Row(
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_focusedMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, color: primary),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chevron_right, color: primary, size: 20),
            ),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Month',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = DateTime(_focusedMonth.year, index + 1);
                  final isSelected = month.month == _focusedMonth.month;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _focusedMonth = DateTime(_focusedMonth.year, index + 1);
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? primary : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat('MMM').format(month),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekdays.map((day) {
          final isWeekend = day == 'Sun' || day == 'Sat';
          return SizedBox(
            width: 40,
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isWeekend ? Colors.red.shade400 : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;
    final totalCells = ((firstWeekday + daysInMonth) / 7).ceil() * 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
        ),
        itemCount: totalCells,
        itemBuilder: (context, index) {
          final dayOffset = index - firstWeekday;
          
          if (dayOffset < 0 || dayOffset >= daysInMonth) {
            return const SizedBox();
          }
          
          final day = dayOffset + 1;
          final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
          final isToday = _isSameDay(date, DateTime.now());
          final isSelected = _isSameDay(date, _selectedDate);
          final events = _getEventsForDate(date);
          final hasEvents = events.isNotEmpty;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? primary
                    : isToday
                        ? primary.withOpacity(0.1)
                        : null,
                borderRadius: BorderRadius.circular(10),
                border: isToday && !isSelected
                    ? Border.all(color: primary, width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? primary
                              : Colors.black87,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  if (hasEvents)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...events.take(3).map((event) {
                            Color dotColor;
                            switch (event['type']) {
                              case 'campaign':
                                dotColor = Colors.orange;
                                break;
                              case 'opportunity':
                                dotColor = Colors.green;
                                break;
                              default:
                                dotColor = Colors.purple;
                            }
                            return Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : dotColor,
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildEventsList(String? typeFilter) {
    final selectedDateEvents = _getEventsForDate(_selectedDate);
    List<Map<String, dynamic>> filteredEvents = typeFilter == null
        ? selectedDateEvents
        : selectedDateEvents.where((e) => e['type'] == typeFilter).toList();

    // If no events on selected date, show upcoming events instead
    if (filteredEvents.isEmpty) {
      final allEvents = _getAllEvents();
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      
      // Get upcoming events (today or future)
      List<Map<String, dynamic>> upcomingEvents = allEvents.where((event) {
        final eventDate = _getEventDate(event);
        if (eventDate == null) return false;
        final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
        return eventDay.isAfter(todayStart) || eventDay.isAtSameMomentAs(todayStart);
      }).toList();

      // Apply type filter if specified
      if (typeFilter != null) {
        upcomingEvents = upcomingEvents.where((e) => e['type'] == typeFilter).toList();
      }

      if (upcomingEvents.isEmpty) {
        return _buildEmptyEventsView(typeFilter);
      }

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No events on selected date. Showing upcoming ${typeFilter ?? 'events'}.',
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: upcomingEvents.length,
              itemBuilder: (context, index) {
                return _buildEventCard(upcomingEvents[index]);
              },
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        return _buildEventCard(filteredEvents[index]);
      },
    );
  }

  Widget _buildEmptyEventsView(String? typeFilter) {
    String message;
    IconData icon;
    
    switch (typeFilter) {
      case 'campaign':
        message = 'No campaigns on this date';
        icon = Icons.campaign_outlined;
        break;
      case 'opportunity':
        message = 'No opportunities on this date';
        icon = Icons.volunteer_activism_outlined;
        break;
      default:
        message = 'No events on this date';
        icon = Icons.event_busy_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              // Show all upcoming events
              _showUpcomingEvents();
            },
            icon: const Icon(Icons.calendar_month),
            label: const Text('View Upcoming Events'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpcomingEvents() {
    final allEvents = _getAllEvents();
    final now = DateTime.now();
    final upcomingEvents = allEvents.where((event) {
      final eventDate = _getEventDate(event);
      return eventDate != null && eventDate.isAfter(now);
    }).toList();

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
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Upcoming Events',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${upcomingEvents.length} events',
                      style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: upcomingEvents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No upcoming events',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: upcomingEvents.length,
                      itemBuilder: (context, index) {
                        return _buildEventCard(upcomingEvents[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final type = event['type'] ?? 'event';
    final title = event['title'] ?? event['name'] ?? 'Untitled Event';
    final description = event['description'] ?? '';
    final eventDate = _getEventDate(event);
    final location = event['location'] ?? event['address'] ?? '';
    final imageUrl = event['imageUrl'] ?? event['bannerImage'];
    
    Color typeColor;
    IconData typeIcon;
    String typeLabel;
    
    switch (type) {
      case 'campaign':
        typeColor = Colors.orange;
        typeIcon = Icons.campaign;
        typeLabel = 'Campaign';
        break;
      case 'opportunity':
        typeColor = Colors.green;
        typeIcon = Icons.volunteer_activism;
        typeLabel = 'Opportunity';
        break;
      default:
        typeColor = Colors.purple;
        typeIcon = Icons.event;
        typeLabel = 'Event';
    }

    return Container(
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
          // Image Section
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: typeColor.withOpacity(0.1),
                      child: Icon(typeIcon, size: 48, color: typeColor),
                    ),
                  ),
                  // Type Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(typeIcon, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            typeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: typeColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            typeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                // Date & Location Row
                Row(
                  children: [
                    if (eventDate != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: primary),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('MMM d, yyyy').format(eventDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (location.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.red.shade400),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _onEventTap(event),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      type == 'opportunity' ? 'Apply Now' : 'View Details',
                      style: const TextStyle(fontWeight: FontWeight.w600),
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

  void _onEventTap(Map<String, dynamic> event) {
    final type = event['type'];
    
    switch (type) {
      case 'campaign':
        // Navigate to campaign detail
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening campaign details...')),
        );
        break;
      case 'opportunity':
        // Navigate to opportunity detail
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening opportunity details...')),
        );
        break;
      default:
        // Navigate to event detail
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening event details...')),
        );
    }
  }
}
