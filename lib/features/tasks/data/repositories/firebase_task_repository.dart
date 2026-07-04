import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/quick_task.dart';
import '../../domain/repositories/task_repository.dart';

class FirebaseTaskRepository implements TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<QuickTask>> streamTasks(String ngoId, {String? status, String? priority}) {
    Query query = _firestore
        .collection('quick_tasks')
        .where('ngoId', isEqualTo: ngoId);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    if (priority != null && priority != 'All') {
      query = query.where('priority', isEqualTo: priority.toLowerCase());
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => QuickTask.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      // Sort by due date
      list.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

      return list;
    });
  }

  @override
  Future<void> createTask(QuickTask task) async {
    final data = task.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    if (task.dueDate != null) {
      data['dueDate'] = Timestamp.fromDate(task.dueDate!);
    }
    await _firestore.collection('quick_tasks').add(data);
  }

  @override
  Future<void> updateTask(QuickTask task) async {
    final data = task.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    if (task.dueDate != null) {
      data['dueDate'] = Timestamp.fromDate(task.dueDate!);
    } else {
      data['dueDate'] = null;
    }
    await _firestore.collection('quick_tasks').doc(task.id).update(data);
  }

  @override
  Future<void> updateTaskStatus(String taskId, String status) async {
    final updates = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == 'completed') {
      updates['completedAt'] = FieldValue.serverTimestamp();
    }
    await _firestore.collection('quick_tasks').doc(taskId).update(updates);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('quick_tasks').doc(taskId).delete();
  }

  @override
  Future<void> seedDemoTasksIfNeeded(String ngoId, String ngoName) async {
    final snapshot = await _firestore
        .collection('quick_tasks')
        .where('ngoId', isEqualTo: ngoId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return; // Already has tasks
    }

    final demoTasks = [
      {
        'title': 'Review volunteer applications',
        'description': 'Review and approve pending volunteer applications for the upcoming food drive campaign.',
        'priority': 'high',
        'category': 'Volunteer Management',
        'assignedTo': 'Admin',
        'status': 'pending',
        'dueDate': DateTime.now().add(const Duration(days: 2)),
      },
      {
        'title': 'Prepare donation report',
        'description': 'Compile monthly donation report for stakeholders and board meeting.',
        'priority': 'high',
        'category': 'Reports',
        'assignedTo': 'Finance Team',
        'status': 'pending',
        'dueDate': DateTime.now().add(const Duration(days: 1)),
      },
      {
        'title': 'Update social media',
        'description': 'Post updates about recent campaign success and upcoming events on social media platforms.',
        'priority': 'medium',
        'category': 'Marketing',
        'assignedTo': 'Social Media Manager',
        'status': 'pending',
        'dueDate': DateTime.now().add(const Duration(days: 3)),
      },
      {
        'title': 'Contact corporate sponsors',
        'description': 'Follow up with potential corporate sponsors for the annual charity gala.',
        'priority': 'medium',
        'category': 'Fundraising',
        'assignedTo': 'Partnerships Team',
        'status': 'in_progress',
        'dueDate': DateTime.now().add(const Duration(days: 5)),
      },
      {
        'title': 'Organize volunteer training',
        'description': 'Schedule and organize training session for new volunteers joining next month.',
        'priority': 'low',
        'category': 'Training',
        'assignedTo': 'HR Team',
        'status': 'in_progress',
        'dueDate': DateTime.now().add(const Duration(days: 7)),
      },
      {
        'title': 'Update beneficiary database',
        'description': 'Update the beneficiary records with latest contact information and needs assessment.',
        'priority': 'medium',
        'category': 'Data Management',
        'assignedTo': 'Operations Team',
        'status': 'in_progress',
        'dueDate': DateTime.now().add(const Duration(days: 4)),
      },
      {
        'title': 'Submit grant application',
        'description': 'Complete and submit the government grant application for community development project.',
        'priority': 'high',
        'category': 'Grants',
        'assignedTo': 'Grant Writer',
        'status': 'completed',
        'completedDate': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'title': 'Inventory check - supplies',
        'description': 'Complete inventory check of all supplies in the warehouse.',
        'priority': 'low',
        'category': 'Logistics',
        'assignedTo': 'Warehouse Manager',
        'status': 'completed',
        'completedDate': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'title': 'Partner meeting notes',
        'description': 'Document and share meeting notes from the partner organization collaboration meeting.',
        'priority': 'medium',
        'category': 'Partnerships',
        'assignedTo': 'Admin',
        'status': 'completed',
        'completedDate': DateTime.now().subtract(const Duration(days: 3)),
      },
    ];

    final batch = _firestore.batch();
    for (final task in demoTasks) {
      final docRef = _firestore.collection('quick_tasks').doc();
      batch.set(docRef, {
        ...task,
        'ngoId': ngoId,
        'ngoName': ngoName,
        'createdAt': FieldValue.serverTimestamp(),
        'dueDate': task['dueDate'] != null ? Timestamp.fromDate(task['dueDate'] as DateTime) : null,
        'completedDate': task['completedDate'] != null ? Timestamp.fromDate(task['completedDate'] as DateTime) : null,
      });
    }

    await batch.commit();
  }
}
