import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PointsHistorySheet extends StatelessWidget {
  final String userId;
  final int currentPoints;

  const PointsHistorySheet({
    Key? key,
    required this.userId,
    required this.currentPoints,
  }) : super(key: key);

  static const Color primary = Color(0xFF0099B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pull Bar
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Volunteer Points',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$currentPoints pts',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Point Rules Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0F2FE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How Points Are Gained',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                ),
                const SizedBox(height: 12),
                _buildRuleItem('🌟 Join a Campaign', '30 Points', Icons.campaign_rounded),
                const SizedBox(height: 8),
                _buildRuleItem('🗓️ Attend an Event', '20 Points', Icons.event_available_rounded),
                const SizedBox(height: 8),
                _buildRuleItem('⏱️ Hours Volunteered', '10 Points / hr', Icons.alarm_rounded),
                const SizedBox(height: 8),
                _buildRuleItem('💳 Donate Funds', '1 Point / \$100', Icons.volunteer_activism_rounded),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Activity & Point History',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),

          // Point History List
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchPointsHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 150,
                  child: Center(
                    child: CircularProgressIndicator(color: primary),
                  ),
                );
              }

              final history = snapshot.data ?? [];

              if (history.isEmpty) {
                return const SizedBox(
                  height: 150,
                  child: Center(
                    child: Text(
                      'No points activities recorded yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                );
              }

              return Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final title = item['title'] as String;
                      final date = item['date'] as DateTime;
                      final points = item['points'] as int;
                      final icon = item['icon'] as IconData;
                      final color = item['color'] as Color;

                      final formattedDate = '${date.day}/${date.month}/${date.year}';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        subtitle: Text(
                          formattedDate,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+$points pts',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String label, String points, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF0284C7)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: const Color(0xFF0369A1), fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          points,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)),
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPointsHistory() async {
    final List<Map<String, dynamic>> list = [];

    // Query events (index-free)
    try {
      final eventsSnap = await FirebaseFirestore.instance
          .collection('event_registrations')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in eventsSnap.docs) {
        final data = doc.data();
        list.add({
          'title': 'Attended: ${data['eventTitle'] ?? 'Event'}',
          'date': (data['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'points': 20,
          'icon': Icons.event_available_rounded,
          'color': Colors.blue,
        });
      }
    } catch (_) {}

    // Query campaigns (index-free)
    try {
      final campaignsSnap = await FirebaseFirestore.instance
          .collection('campaign_participants')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in campaignsSnap.docs) {
        final data = doc.data();
        list.add({
          'title': 'Joined Campaign: ${data['campaignName'] ?? 'Campaign'}',
          'date': (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'points': 30,
          'icon': Icons.campaign_rounded,
          'color': Colors.green,
        });
      }
    } catch (_) {}

    // Sort combined list in memory by date descending
    list.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return list;
  }
}
