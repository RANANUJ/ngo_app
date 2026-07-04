import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({Key? key}) : super(key: key);

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  static const Color primaryColor = Color(0xFF0099B8);

  void _showAddAnnouncementSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddAnnouncementSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Announcements',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: _showAddAnnouncementSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('publishedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No Announcements Published Yet',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Announcement';
              final message = data['message'] ?? '';
              final target = data['targetAudience'] ?? 'All';
              final priority = data['priority'] ?? 'Medium';
              final dateStamp = data['publishedAt'] as Timestamp?;
              final date = dateStamp?.toDate() ?? DateTime.now();
              final dateText = '${date.day}/${date.month}/${date.year}';

              Color priorityColor;
              switch (priority.toLowerCase()) {
                case 'high':
                  priorityColor = Colors.red;
                  break;
                case 'low':
                  priorityColor = Colors.green;
                  break;
                default:
                  priorityColor = Colors.orange;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              priority.toUpperCase(),
                              style: TextStyle(color: priorityColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            dateText,
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.group_outlined, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            'Audience: $target',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AddAnnouncementSheet extends StatefulWidget {
  const _AddAnnouncementSheet({Key? key}) : super(key: key);

  @override
  State<_AddAnnouncementSheet> createState() => _AddAnnouncementSheetState();
}

class _AddAnnouncementSheetState extends State<_AddAnnouncementSheet> {
  static const Color primaryColor = Color(0xFF0099B8);
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _priority = 'Medium';
  String _audience = 'All';
  DateTime _publishDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _publish() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and message')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': title,
        'message': message,
        'priority': _priority,
        'targetAudience': _audience,
        'publishedAt': Timestamp.fromDate(_publishDate),
      });

      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement Published successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'New Announcement',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Announcement Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Message Body',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _audience,
                  decoration: const InputDecoration(labelText: 'Audience', border: OutlineInputBorder()),
                  items: ['All', 'Volunteers', 'NGOs'].map((a) {
                    return DropdownMenuItem(value: a, child: Text(a));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _audience = val);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                  items: ['High', 'Medium', 'Low'].map((p) {
                    return DropdownMenuItem(value: p, child: Text(p));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _priority = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _publishDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _publishDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Publish Date: ${_publishDate.day}/${_publishDate.month}/${_publishDate.year}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const Icon(Icons.calendar_month, color: primaryColor, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isLoading ? null : _publish,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Publish Announcement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
