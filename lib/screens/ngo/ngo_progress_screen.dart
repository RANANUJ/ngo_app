import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NgoProgressScreen extends StatefulWidget {
  final String ngoId;
  final String ngoName;

  const NgoProgressScreen({
    Key? key,
    required this.ngoId,
    required this.ngoName,
  }) : super(key: key);

  @override
  State<NgoProgressScreen> createState() => _NgoProgressScreenState();
}

class _NgoProgressScreenState extends State<NgoProgressScreen> {
  static const Color primary = Color(0xFF0099B8);
  static const Color primaryDark = Color(0xFF007A94);
  static const Color bgColor = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: StreamBuilder<_NgoStats>(
        stream: _getStatsStream(),
        builder: (context, snapshot) {
          final stats = snapshot.data ?? _NgoStats();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(stats),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildQuickStats(stats),
                    const SizedBox(height: 20),
                    _buildFundraisingSection(stats),
                    const SizedBox(height: 20),
                    _buildCampaignsSection(),
                    const SizedBox(height: 20),
                    _buildEventsSection(),
                    const SizedBox(height: 20),
                    _buildVolunteersSection(),
                    const SizedBox(height: 20),
                    _buildMilestonesSection(stats),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Stream that combines all NGO statistics
  Stream<_NgoStats> _getStatsStream() async* {
    while (true) {
      try {
        // Get campaigns
        final campaignsSnap = await FirebaseFirestore.instance
            .collection('campaigns')
            .where('ngoId', isEqualTo: widget.ngoId)
            .get();

        int totalRaised = 0;
        int totalTarget = 0;
        int activeCampaigns = 0;
        List<Map<String, dynamic>> campaignsList = [];

        for (var doc in campaignsSnap.docs) {
          final data = doc.data();
          totalRaised += (data['amountRaised'] ?? 0) as int;
          totalTarget += (data['targetAmount'] ?? 0) as int;
          if (data['isActive'] == true) activeCampaigns++;
          campaignsList.add({...data, 'id': doc.id});
        }

        // Get volunteers (accepted requests)
        final volunteersSnap = await FirebaseFirestore.instance
            .collection('volunteer_requests')
            .where('ngoId', isEqualTo: widget.ngoId)
            .where('status', isEqualTo: 'accepted')
            .get();

        // Get events
        final eventsSnap = await FirebaseFirestore.instance
            .collection('volunteer_opportunities')
            .where('ngoId', isEqualTo: widget.ngoId)
            .get();

        // Get posts
        final postsSnap = await FirebaseFirestore.instance
            .collection('community_posts')
            .where('userId', isEqualTo: widget.ngoId)
            .get();

        // Calculate people impacted
        int peopleImpacted = 0;
        for (var doc in campaignsSnap.docs) {
          final data = doc.data();
          peopleImpacted += (data['peopleImpacted'] ?? 0) as int;
        }
        for (var doc in eventsSnap.docs) {
          final data = doc.data();
          peopleImpacted += (data['peopleImpacted'] ?? 0) as int;
        }

        yield _NgoStats(
          campaigns: campaignsSnap.docs.length,
          activeCampaigns: activeCampaigns,
          volunteers: volunteersSnap.docs.length,
          events: eventsSnap.docs.length,
          posts: postsSnap.docs.length,
          totalRaised: totalRaised,
          totalTarget: totalTarget,
          peopleImpacted: peopleImpacted,
          campaignsList: campaignsList,
        );
      } catch (e) {
        yield _NgoStats();
      }

      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Widget _buildAppBar(_NgoStats stats) {
    String level = _getLevel(stats.impactScore);
    int progress = _getLevelProgress(stats.impactScore);

    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      backgroundColor: primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, primaryDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.ngoName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getLevelIcon(level),
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    level,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${stats.impactScore} pts',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                children: [
                                  Container(
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: progress / 100,
                                    child: Container(
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$progress% to ${_getNextLevel(level)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(_NgoStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.campaign_rounded,
          iconColor: const Color(0xFF10B981),
          value: stats.campaigns.toString(),
          label: 'Campaigns',
          subtitle: '${stats.activeCampaigns} active',
        ),
        _StatCard(
          icon: Icons.people_rounded,
          iconColor: const Color(0xFF3B82F6),
          value: stats.volunteers.toString(),
          label: 'Volunteers',
          subtitle: 'Team members',
        ),
        _StatCard(
          icon: Icons.event_rounded,
          iconColor: const Color(0xFFF59E0B),
          value: stats.events.toString(),
          label: 'Events',
          subtitle: 'Organized',
        ),
        _StatCard(
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFEF4444),
          value: _formatNumber(stats.peopleImpacted),
          label: 'Lives Impacted',
          subtitle: 'People helped',
        ),
      ],
    );
  }

  Widget _buildFundraisingSection(_NgoStats stats) {
    double progress = stats.totalTarget > 0
        ? (stats.totalRaised / stats.totalTarget).clamp(0.0, 1.0)
        : 0;

    return _SectionCard(
      title: 'Fundraising',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: const Color(0xFF10B981),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${_formatAmount(stats.totalRaised)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'of ₹${_formatAmount(stats.totalTarget)} goal',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
          if (stats.campaignsList.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            ...stats.campaignsList.take(3).map((c) => _CampaignProgressTile(
                  name: c['title'] ?? 'Campaign',
                  raised: (c['amountRaised'] ?? 0) as int,
                  target: (c['targetAmount'] ?? 1) as int,
                  isActive: c['isActive'] ?? false,
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildCampaignsSection() {
    return _SectionCard(
      title: 'Recent Campaigns',
      icon: Icons.campaign_rounded,
      iconColor: const Color(0xFF10B981),
      onViewAll: () {},
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('campaigns')
            .where('ngoId', isEqualTo: widget.ngoId)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.error_outline,
              message: 'Error loading campaigns',
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _EmptyState(
              icon: Icons.campaign_outlined,
              message: 'No campaigns yet',
            );
          }

          return Column(
            children: snapshot.data!.docs.take(3).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _CampaignTile(data: data);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildEventsSection() {
    return _SectionCard(
      title: 'Recent Events',
      icon: Icons.event_rounded,
      iconColor: const Color(0xFFF59E0B),
      onViewAll: () {},
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('volunteer_opportunities')
            .where('ngoId', isEqualTo: widget.ngoId)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.error_outline,
              message: 'Error loading events',
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _EmptyState(
              icon: Icons.event_outlined,
              message: 'No events yet',
            );
          }

          return Column(
            children: snapshot.data!.docs.take(3).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _EventTile(data: data);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildVolunteersSection() {
    return _SectionCard(
      title: 'Team Members',
      icon: Icons.people_rounded,
      iconColor: const Color(0xFF3B82F6),
      onViewAll: () {},
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('volunteer_requests')
            .where('ngoId', isEqualTo: widget.ngoId)
            .where('status', isEqualTo: 'accepted')
            .limit(6)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _EmptyState(
              icon: Icons.people_outline,
              message: 'No volunteers yet',
            );
          }

          final volunteers = snapshot.data!.docs;

          return Row(
            children: [
              // Avatar stack
              SizedBox(
                width: 120,
                height: 44,
                child: Stack(
                  children: List.generate(
                    volunteers.length.clamp(0, 4),
                    (index) {
                      final data = volunteers[index].data() as Map<String, dynamic>;
                      return Positioned(
                        left: index * 28.0,
                        child: _VolunteerAvatar(
                          name: data['volunteerName'] ?? 'V',
                          photoUrl: data['volunteerPhoto'],
                          index: index,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${volunteers.length} volunteer${volunteers.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D1E),
                      ),
                    ),
                    Text(
                      'Supporting your mission',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios, color: primary, size: 16),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMilestonesSection(_NgoStats stats) {
    final milestones = _getMilestones(stats);
    int achieved = milestones.where((m) => m['achieved'] == true).length;

    return _SectionCard(
      title: 'Milestones',
      icon: Icons.emoji_events_rounded,
      iconColor: const Color(0xFFF59E0B),
      trailing: Text(
        '$achieved/${milestones.length}',
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: milestones.map((m) => _MilestoneChip(milestone: m)).toList(),
      ),
    );
  }

  // Helper methods
  String _getLevel(int score) {
    if (score >= 5000) return 'Champion';
    if (score >= 2500) return 'Leader';
    if (score >= 1000) return 'Established';
    if (score >= 400) return 'Growing';
    if (score >= 100) return 'Rising';
    return 'Starter';
  }

  String _getNextLevel(String level) {
    switch (level) {
      case 'Starter':
        return 'Rising';
      case 'Rising':
        return 'Growing';
      case 'Growing':
        return 'Established';
      case 'Established':
        return 'Leader';
      case 'Leader':
        return 'Champion';
      default:
        return 'Max';
    }
  }

  int _getLevelProgress(int score) {
    if (score >= 5000) return 100;
    if (score >= 2500) return ((score - 2500) / 2500 * 100).toInt().clamp(0, 100);
    if (score >= 1000) return ((score - 1000) / 1500 * 100).toInt().clamp(0, 100);
    if (score >= 400) return ((score - 400) / 600 * 100).toInt().clamp(0, 100);
    if (score >= 100) return ((score - 100) / 300 * 100).toInt().clamp(0, 100);
    return (score / 100 * 100).toInt().clamp(0, 100);
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'Champion':
        return Icons.emoji_events_rounded;
      case 'Leader':
        return Icons.military_tech_rounded;
      case 'Established':
        return Icons.verified_rounded;
      case 'Growing':
        return Icons.trending_up_rounded;
      case 'Rising':
        return Icons.rocket_launch_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  String _formatAmount(int amount) {
    if (amount >= 10000000) return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toString();
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }

  List<Map<String, dynamic>> _getMilestones(_NgoStats stats) {
    return [
      {
        'name': 'First Campaign',
        'icon': Icons.campaign,
        'color': const Color(0xFF10B981),
        'achieved': stats.campaigns >= 1,
      },
      {
        'name': '5 Campaigns',
        'icon': Icons.emoji_events,
        'color': const Color(0xFFF59E0B),
        'achieved': stats.campaigns >= 5,
      },
      {
        'name': '10 Volunteers',
        'icon': Icons.people,
        'color': const Color(0xFF3B82F6),
        'achieved': stats.volunteers >= 10,
      },
      {
        'name': '50 Volunteers',
        'icon': Icons.groups,
        'color': const Color(0xFF8B5CF6),
        'achieved': stats.volunteers >= 50,
      },
      {
        'name': 'Event Host',
        'icon': Icons.event,
        'color': const Color(0xFFEC4899),
        'achieved': stats.events >= 1,
      },
      {
        'name': '₹10K Raised',
        'icon': Icons.savings,
        'color': const Color(0xFF10B981),
        'achieved': stats.totalRaised >= 10000,
      },
      {
        'name': '₹1L Raised',
        'icon': Icons.monetization_on,
        'color': const Color(0xFFF59E0B),
        'achieved': stats.totalRaised >= 100000,
      },
    ];
  }
}

// Data class for NGO statistics
class _NgoStats {
  final int campaigns;
  final int activeCampaigns;
  final int volunteers;
  final int events;
  final int posts;
  final int totalRaised;
  final int totalTarget;
  final int peopleImpacted;
  final List<Map<String, dynamic>> campaignsList;

  _NgoStats({
    this.campaigns = 0,
    this.activeCampaigns = 0,
    this.volunteers = 0,
    this.events = 0,
    this.posts = 0,
    this.totalRaised = 0,
    this.totalTarget = 0,
    this.peopleImpacted = 0,
    this.campaignsList = const [],
  });

  int get impactScore =>
      (campaigns * 100) + (volunteers * 50) + (events * 75) + (posts * 10);
}

// Reusable Widget Components

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1D1E),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1D1E),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final VoidCallback? onViewAll;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
    this.onViewAll,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1D1E),
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View all',
                    style: TextStyle(
                      color: const Color(0xFF0099B8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CampaignProgressTile extends StatelessWidget {
  final String name;
  final int raised;
  final int target;
  final bool isActive;

  const _CampaignProgressTile({
    required this.name,
    required this.raised,
    required this.target,
    required this.isActive,
  });

  String _formatAmount(int amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return '₹$amount';
  }

  @override
  Widget build(BuildContext context) {
    double progress = target > 0 ? (raised / target).clamp(0.0, 1.0) : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isActive ? 'Active' : 'Ended',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isActive ? const Color(0xFF10B981) : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF0099B8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_formatAmount(raised)} / ${_formatAmount(target)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CampaignTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _CampaignTile({required this.data});

  String _formatAmount(int amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toString();
  }

  @override
  Widget build(BuildContext context) {
    int raised = (data['amountRaised'] ?? 0) as int;
    int target = (data['targetAmount'] ?? 1) as int;
    double progress = (raised / target).clamp(0.0, 1.0);
    bool isActive = data['isActive'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Color(0xFF10B981),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data['title'] ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Ended',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color:
                              isActive ? const Color(0xFF10B981) : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF0099B8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '₹${_formatAmount(raised)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0099B8),
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
}

class _EventTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _EventTile({required this.data});

  String _getMonthShort(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final eventDate = (data['eventDate'] as Timestamp?)?.toDate();
    final current = (data['currentVolunteers'] ?? 0) as int;
    final max = (data['maxVolunteers'] ?? 0) as int;
    final spotsLeft = max - current;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  eventDate != null ? '${eventDate.day}' : '--',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF59E0B),
                    height: 1,
                  ),
                ),
                Text(
                  eventDate != null ? _getMonthShort(eventDate.month) : '',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'Untitled Event',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '$current joined',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    if (spotsLeft > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$spotsLeft spots left',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
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
    );
  }
}

class _VolunteerAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final int index;

  const _VolunteerAvatar({
    required this.name,
    this.photoUrl,
    required this.index,
  });

  Color _getColor(int index) {
    const colors = [
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFFEF4444),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        color: _getColor(index),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  final Map<String, dynamic> milestone;

  const _MilestoneChip({required this.milestone});

  @override
  Widget build(BuildContext context) {
    bool achieved = milestone['achieved'] as bool;
    Color color = milestone['color'] as Color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: achieved ? color.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: achieved ? color.withOpacity(0.3) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            milestone['icon'] as IconData,
            size: 16,
            color: achieved ? color : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            milestone['name'] as String,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: achieved ? color : Colors.grey,
            ),
          ),
          if (achieved) ...[
            const SizedBox(width: 4),
            Icon(Icons.check_circle, size: 14, color: color),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
