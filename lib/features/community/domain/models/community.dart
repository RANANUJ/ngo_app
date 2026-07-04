class Community {
  final String id;
  final String name;
  final String description;
  final String category;
  final String creatorId;
  final String creatorName;
  final String creatorLogo;
  final int memberCount;
  final bool isPublic;
  final DateTime createdAt;
  final String imageUrl;
  final String coverUrl;
  final List<String> rules;
  final int postsCount;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.creatorId,
    required this.creatorName,
    required this.creatorLogo,
    required this.memberCount,
    required this.isPublic,
    required this.createdAt,
    this.imageUrl = '',
    this.coverUrl = '',
    this.rules = const [],
    this.postsCount = 0,
  });

  factory Community.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
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

    return Community(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      creatorLogo: map['creatorLogo'] ?? map['imageUrl'] ?? '', // Fallback to imageUrl for displayImage consistency
      memberCount: (map['memberCount'] ?? map['membersCount'] ?? 0).toInt(),
      isPublic: map['isPublic'] ?? true,
      createdAt: parseDateTime(map['createdAt']),
      imageUrl: map['imageUrl'] ?? '',
      coverUrl: map['coverUrl'] ?? '',
      rules: List<String>.from(map['rules'] ?? []),
      postsCount: (map['postsCount'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'category': category,
    'creatorId': creatorId,
    'creatorName': creatorName,
    'creatorLogo': creatorLogo,
    'memberCount': memberCount,
    'membersCount': memberCount, // Write both for safety
    'isPublic': isPublic,
    'createdAt': createdAt.toIso8601String(),
    'imageUrl': imageUrl,
    'coverUrl': coverUrl,
    'rules': rules,
    'postsCount': postsCount,
  };
}
