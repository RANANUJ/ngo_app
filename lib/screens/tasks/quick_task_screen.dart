import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngo_app/features/ngo/data/services/ngo_registration_service.dart';

class QuickTaskScreen extends StatefulWidget {
  final NgoRegistrationRequest ngoData;

  const QuickTaskScreen({Key? key, required this.ngoData}) : super(key: key);

  @override
  State<QuickTaskScreen> createState() => _QuickTaskScreenState();
}

class _QuickTaskScreenState extends State<QuickTaskScreen> with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF0099B8);
  late TabController _tabController;
  String _selectedFilter = 'All';
  bool _demoDataSeeded = false;

  // Demo/Sample tasks data
  final List<Map<String, dynamic>> _demoTasks = [
    {
      'id': 'demo_1',
      'title': 'Review volunteer applications',
      'description': 'Review and approve pending volunteer applications for the upcoming food drive campaign.',
      'priority': 'high',
      'category': 'Volunteer Management',
      'assignedTo': 'Admin',
      'status': 'pending',
      'dueDate': DateTime.now().add(const Duration(days: 2)),
    },
    {
      'id': 'demo_2',
      'title': 'Prepare donation report',
      'description': 'Compile monthly donation report for stakeholders and board meeting.',
      'priority': 'high',
      'category': 'Reports',
      'assignedTo': 'Finance Team',
      'status': 'pending',
      'dueDate': DateTime.now().add(const Duration(days: 1)),
    },
    {
      'id': 'demo_3',
      'title': 'Update social media',
      'description': 'Post updates about recent campaign success and upcoming events on social media platforms.',
      'priority': 'medium',
      'category': 'Marketing',
      'assignedTo': 'Social Media Manager',
      'status': 'pending',
      'dueDate': DateTime.now().add(const Duration(days: 3)),
    },
    {
      'id': 'demo_4',
      'title': 'Contact corporate sponsors',
      'description': 'Follow up with potential corporate sponsors for the annual charity gala.',
      'priority': 'medium',
      'category': 'Fundraising',
      'assignedTo': 'Partnerships Team',
      'status': 'in_progress',
      'dueDate': DateTime.now().add(const Duration(days: 5)),
    },
    {
      'id': 'demo_5',
      'title': 'Organize volunteer training',
      'description': 'Schedule and organize training session for new volunteers joining next month.',
      'priority': 'low',
      'category': 'Training',
      'assignedTo': 'HR Team',
      'status': 'in_progress',
      'dueDate': DateTime.now().add(const Duration(days: 7)),
    },
    {
      'id': 'demo_6',
      'title': 'Update beneficiary database',
      'description': 'Update the beneficiary records with latest contact information and needs assessment.',
      'priority': 'medium',
      'category': 'Data Management',
      'assignedTo': 'Operations Team',
      'status': 'in_progress',
      'dueDate': DateTime.now().add(const Duration(days: 4)),
    },
    {
      'id': 'demo_7',
      'title': 'Submit grant application',
      'description': 'Complete and submit the government grant application for community development project.',
      'priority': 'high',
      'category': 'Grants',
      'assignedTo': 'Grant Writer',
      'status': 'completed',
      'completedDate': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'id': 'demo_8',
      'title': 'Inventory check - supplies',
      'description': 'Complete inventory check of all supplies in the warehouse.',
      'priority': 'low',
      'category': 'Logistics',
      'assignedTo': 'Warehouse Manager',
      'status': 'completed',
      'completedDate': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': 'demo_9',
      'title': 'Partner meeting notes',
      'description': 'Document and share meeting notes from the partner organization collaboration meeting.',
      'priority': 'medium',
      'category': 'Partnerships',
      'assignedTo': 'Admin',
      'status': 'completed',
      'completedDate': DateTime.now().subtract(const Duration(days: 3)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _seedDemoDataIfNeeded();
  }

  Future<void> _seedDemoDataIfNeeded() async {
    if (_demoDataSeeded) return;
    
    try {
      // Check if there are any tasks for this NGO
      final snapshot = await FirebaseFirestore.instance
          .collection('quick_tasks')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        // Seed demo data
        final batch = FirebaseFirestore.instance.batch();
        
        for (final task in _demoTasks) {
          final docRef = FirebaseFirestore.instance.collection('quick_tasks').doc();
          batch.set(docRef, {
            ...task,
            'ngoId': widget.ngoData.id,
            'createdAt': FieldValue.serverTimestamp(),
            'dueDate': task['dueDate'] != null ? Timestamp.fromDate(task['dueDate']) : null,
            'completedDate': task['completedDate'] != null ? Timestamp.fromDate(task['completedDate']) : null,
          });
        }
        
        await batch.commit();
        _demoDataSeeded = true;
      }
    } catch (e) {
      debugPrint('Error seeding demo data: $e');
    }
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quick Tasks',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primary,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterSection(),
          // Task list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList('pending'),
                _buildTaskList('in_progress'),
                _buildTaskList('completed'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTaskDialog(),
        backgroundColor: primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Task', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildFilterSection() {
    final filters = ['All', 'High', 'Medium', 'Low'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            'Priority:',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                      },
                      selectedColor: primary.withOpacity(0.2),
                      checkmarkColor: primary,
                      labelStyle: TextStyle(
                        color: isSelected ? primary : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quick_tasks')
          .where('ngoId', isEqualTo: widget.ngoData.id)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(status);
        }

        var docs = snapshot.data!.docs;
        
        // Apply priority filter
        if (_selectedFilter != 'All') {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['priority'] == _selectedFilter.toLowerCase();
          }).toList();
        }

        // Sort by due date
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aDate = aData['dueDate'] as Timestamp?;
          final bDate = bData['dueDate'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        });

        if (docs.isEmpty) {
          return _buildEmptyState(status);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildTaskCard(data, docs[index].id, status);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;
    
    switch (status) {
      case 'pending':
        message = 'No pending tasks';
        icon = Icons.inbox_outlined;
        break;
      case 'in_progress':
        message = 'No tasks in progress';
        icon = Icons.hourglass_empty;
        break;
      case 'completed':
        message = 'No completed tasks yet';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'No tasks found';
        icon = Icons.task_alt;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create a new task',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> data, String docId, String currentStatus) {
    final title = data['title'] ?? 'Untitled Task';
    final description = data['description'] ?? '';
    final priority = data['priority'] ?? 'medium';
    final category = data['category'] ?? 'General';
    final assignedTo = data['assignedTo'] ?? '';
    final dueDate = data['dueDate'] as Timestamp?;

    Color priorityColor;
    switch (priority) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    String dueDateStr = '';
    bool isOverdue = false;
    if (dueDate != null) {
      final date = dueDate.toDate();
      dueDateStr = '${date.day}/${date.month}/${date.year}';
      isOverdue = date.isBefore(DateTime.now()) && currentStatus != 'completed';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: priorityColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      decoration: currentStatus == 'completed'
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                  onSelected: (value) => _handleMenuAction(value, docId, data),
                  itemBuilder: (context) => [
                    if (currentStatus == 'pending')
                      const PopupMenuItem(value: 'start', child: Text('Start Task')),
                    if (currentStatus == 'in_progress')
                      const PopupMenuItem(value: 'complete', child: Text('Mark Complete')),
                    if (currentStatus == 'completed')
                      const PopupMenuItem(value: 'reopen', child: Text('Reopen Task')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Priority badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    priority.toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: priorityColor,
                    ),
                  ),
                ),
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                // Due date
                if (dueDateStr.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOverdue ? Colors.red.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 10,
                          color: isOverdue ? Colors.red : Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dueDateStr,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isOverdue ? Colors.red : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (assignedTo.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned to: $assignedTo',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, String docId, Map<String, dynamic> data) async {
    switch (action) {
      case 'start':
        await _updateTaskStatus(docId, 'in_progress');
        break;
      case 'complete':
        await _updateTaskStatus(docId, 'completed');
        break;
      case 'reopen':
        await _updateTaskStatus(docId, 'pending');
        break;
      case 'edit':
        _showCreateTaskDialog(existingData: data, docId: docId);
        break;
      case 'delete':
        await _deleteTask(docId);
        break;
    }
  }

  Future<void> _updateTaskStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('quick_tasks')
          .doc(docId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        if (newStatus == 'completed') 'completedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task moved to ${newStatus.replaceAll('_', ' ')}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteTask(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('quick_tasks').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _showCreateTaskDialog({Map<String, dynamic>? existingData, String? docId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateTaskForm(
        ngoData: widget.ngoData,
        existingData: existingData,
        docId: docId,
      ),
    );
  }
}

class _CreateTaskForm extends StatefulWidget {
  final NgoRegistrationRequest ngoData;
  final Map<String, dynamic>? existingData;
  final String? docId;

  const _CreateTaskForm({
    Key? key,
    required this.ngoData,
    this.existingData,
    this.docId,
  }) : super(key: key);

  @override
  State<_CreateTaskForm> createState() => _CreateTaskFormState();
}

class _CreateTaskFormState extends State<_CreateTaskForm> {
  static const Color primary = Color(0xFF0099B8);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _assignedToController = TextEditingController();

  String _priority = 'medium';
  String _category = 'General';
  DateTime? _dueDate;
  bool _isLoading = false;

  final List<String> _categories = [
    'General',
    'Field Work',
    'Documentation',
    'Outreach',
    'Event Planning',
    'Fundraising',
    'Volunteer Coordination',
    'Administration',
    'Communication',
    'Research',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _titleController.text = widget.existingData!['title'] ?? '';
      _descriptionController.text = widget.existingData!['description'] ?? '';
      _assignedToController.text = widget.existingData!['assignedTo'] ?? '';
      _priority = widget.existingData!['priority'] ?? 'medium';
      _category = widget.existingData!['category'] ?? 'General';
      if (widget.existingData!['dueDate'] != null) {
        _dueDate = (widget.existingData!['dueDate'] as Timestamp).toDate();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assignedToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingData != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  isEditing ? 'Edit Task' : 'Create New Task',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Task Title *',
                        hintText: 'Enter task title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a task title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter task description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Priority
                    const Text(
                      'Priority',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPriorityOption('high', 'High', Colors.red),
                        const SizedBox(width: 12),
                        _buildPriorityOption('medium', 'Medium', Colors.orange),
                        const SizedBox(width: 12),
                        _buildPriorityOption('low', 'Low', Colors.green),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primary, width: 2),
                        ),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _category = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Due Date
                    GestureDetector(
                      onTap: _selectDueDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Due Date',
                            hintText: _dueDate != null
                                ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                : 'Select due date',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          controller: TextEditingController(
                            text: _dueDate != null
                                ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                : '',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Assigned To
                    TextFormField(
                      controller: _assignedToController,
                      decoration: InputDecoration(
                        labelText: 'Assign To (Optional)',
                        hintText: 'Enter volunteer name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primary, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEditing ? 'Update Task' : 'Create Task',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityOption(String value, String label, Color color) {
    final isSelected = _priority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final taskData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'priority': _priority,
        'category': _category,
        'assignedTo': _assignedToController.text.trim(),
        'dueDate': _dueDate != null ? Timestamp.fromDate(_dueDate!) : null,
        'ngoId': widget.ngoData.id,
        'ngoName': widget.ngoData.ngoName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.docId != null) {
        // Update existing task
        await FirebaseFirestore.instance
            .collection('quick_tasks')
            .doc(widget.docId)
            .update(taskData);
      } else {
        // Create new task
        taskData['status'] = 'pending';
        taskData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('quick_tasks').add(taskData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.docId != null ? 'Task updated!' : 'Task created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
