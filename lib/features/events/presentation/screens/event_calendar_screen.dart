import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngo_app/features/campaigns/domain/models/campaign.dart';
import 'package:ngo_app/features/campaigns/presentation/controllers/campaign_controller.dart';
import 'package:ngo_app/features/campaigns/presentation/screens/campaign_detail_screen.dart';
import 'package:ngo_app/features/opportunities/domain/models/opportunity.dart';
import 'package:ngo_app/features/opportunities/presentation/controllers/opportunity_controller.dart';
import 'package:ngo_app/features/opportunities/presentation/screens/opportunity_detail_screen.dart';
import 'package:ngo_app/shared/widgets/skeleton_loader.dart';

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

  StreamSubscription? _campaignsSub;
  StreamSubscription? _opportunitiesSub;
  List<Campaign> _campaigns = [];
  List<Opportunity> _opportunities = [];
  bool _isLoadingCampaigns = true;
  bool _isLoadingOpportunities = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _listenToStreams();
  }

  void _listenToStreams() {
    final campaignController = context.read<CampaignController>();
    final opportunityController = context.read<OpportunityController>();

    _campaignsSub = campaignController.streamNgoCampaigns(widget.ngoId).listen((campaigns) {
      if (mounted) {
        setState(() {
          _campaigns = campaigns;
          _isLoadingCampaigns = false;
        });
      }
    });

    _opportunitiesSub = opportunityController.streamNgoOpportunities(widget.ngoId).listen((opportunities) {
      if (mounted) {
        setState(() {
          _opportunities = opportunities;
          _isLoadingOpportunities = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _campaignsSub?.cancel();
    _opportunitiesSub?.cancel();
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
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Event Calendar',
          style: const TextStyle(
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
            icon: const Icon(Icons.chevron_left, color: primary),
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: primary),
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
                                ? primary.withValues(alpha: 0.2)
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
    if (_isLoadingCampaigns && _isLoadingOpportunities) {
      return const ListSkeleton(itemCount: 4, height: 75);
    }

    final List<_EventItem> allEvents = [
      ..._campaigns.map((c) => _EventItem(id: c.id, type: 'campaign', campaign: c)),
      ..._opportunities.map((o) => _EventItem(id: o.id, type: 'opportunity', opportunity: o)),
    ];

    allEvents.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.now();
      final bDate = b.createdAt ?? DateTime.now();
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
  }

  Widget _buildCampaignsList() {
    if (_isLoadingCampaigns) {
      return const ListSkeleton(itemCount: 3, height: 75);
    }

    final campaigns = List<Campaign>.from(_campaigns);
    campaigns.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.now();
      final bDate = b.createdAt ?? DateTime.now();
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
          campaign: campaign,
        ));
      },
    );
  }

  Widget _buildOpportunitiesList() {
    if (_isLoadingOpportunities) {
      return const ListSkeleton(itemCount: 3, height: 75);
    }

    final opportunities = List<Opportunity>.from(_opportunities);
    opportunities.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.now();
      final bDate = b.createdAt ?? DateTime.now();
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
          opportunity: opportunity,
        ));
      },
    );
  }

  Widget _buildEventCard(_EventItem event) {
    final isCampaign = event.type == 'campaign';
    final title = isCampaign ? event.campaign!.title : event.opportunity!.title;
    final description = isCampaign ? event.campaign!.description : event.opportunity!.description;
    final images = isCampaign ? event.campaign!.images : event.opportunity!.images;
    final createdAt = isCampaign ? event.campaign!.createdAt : event.opportunity!.createdAt;
    final status = isCampaign ? event.campaign!.status : event.opportunity!.status;

    return GestureDetector(
      onTap: () {
        if (isCampaign) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CampaignDetailScreen(
                campaign: event.campaign!,
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
                opportunity: event.opportunity!,
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
              color: Colors.black.withValues(alpha: 0.05),
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
                            ? Colors.blue.withValues(alpha: 0.9)
                            : Colors.green.withValues(alpha: 0.9),
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
                          '${event.opportunity!.volunteersNeeded} volunteers needed',
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
                          '${event.campaign!.participantsCount} participants',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!isCampaign) ...[
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
                            event.opportunity!.location,
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
  final Campaign? campaign;
  final Opportunity? opportunity;

  DateTime? get createdAt => type == 'campaign' ? campaign?.createdAt : opportunity?.createdAt;

  _EventItem({
    required this.id,
    required this.type,
    this.campaign,
    this.opportunity,
  });
}
