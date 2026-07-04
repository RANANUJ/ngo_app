class QuickTask {
  final String id;
  final String title;
  final String description;
  final String priority;
  final String category;
  final String assignedTo;
  final String status;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final String ngoId;
  final String ngoName;
  final DateTime createdAt;

  QuickTask({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.assignedTo,
    required this.status,
    this.dueDate,
    this.completedDate,
    required this.ngoId,
    required this.ngoName,
    required this.createdAt,
  });

  factory QuickTask.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value.runtimeType.toString() == 'Timestamp') {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      if (value is DateTime) {
        return value;
      }
      return null;
    }

    return QuickTask(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      priority: map['priority'] ?? 'medium',
      category: map['category'] ?? 'General',
      assignedTo: map['assignedTo'] ?? '',
      status: map['status'] ?? 'pending',
      dueDate: parseDateTime(map['dueDate']),
      completedDate: parseDateTime(map['completedDate']),
      ngoId: map['ngoId'] ?? '',
      ngoName: map['ngoName'] ?? '',
      createdAt: parseDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'priority': priority,
    'category': category,
    'assignedTo': assignedTo,
    'status': status,
    if (dueDate != null) 'dueDate': dueDate,
    if (completedDate != null) 'completedDate': completedDate,
    'ngoId': ngoId,
    'ngoName': ngoName,
    'createdAt': createdAt.toIso8601String(),
  };
}
