class Resource {
  final String id;
  final String title;
  final String description;
  final int quantity;
  final String category;
  final String ngoId;
  final String ngoName;
  final List<String> images;
  final String status;
  final DateTime createdAt;

  Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.quantity,
    required this.category,
    required this.ngoId,
    required this.ngoName,
    required this.images,
    required this.status,
    required this.createdAt,
  });

  factory Resource.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      // Handles both Timestamp and String/DateTime
      if (value.runtimeType.toString() == 'Timestamp') {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      if (value is DateTime) {
        return value;
      }
      return DateTime.now();
    }

    return Resource(
      id: id,
      title: map['title'] ?? map['name'] ?? 'Resource',
      description: map['description'] ?? '',
      quantity: (map['quantity'] ?? 0).toInt(),
      category: map['category'] ?? 'Other',
      ngoId: map['ngoId'] ?? '',
      ngoName: map['ngoName'] ?? map['donorName'] ?? 'NGO',
      images: List<String>.from(map['images'] ?? []),
      status: map['status'] ?? 'available',
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'ngoId': ngoId,
    'ngoName': ngoName,
    'title': title,
    'description': description,
    'quantity': quantity,
    'category': category,
    'images': images,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };
}
