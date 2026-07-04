class CommunityComment {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final String authorPhoto;
  final String authorType;
  final DateTime createdAt;
  final bool isPinned;
  final int likesCount;

  CommunityComment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.authorPhoto,
    required this.authorType,
    required this.createdAt,
    this.isPinned = false,
    this.likesCount = 0,
  });

  factory CommunityComment.fromMap(String id, Map<String, dynamic> map) {
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

    return CommunityComment(
      id: id,
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorPhoto: map['authorPhoto'] ?? '',
      authorType: map['authorType'] ?? '',
      createdAt: parseDateTime(map['createdAt']),
      isPinned: map['isPinned'] ?? false,
      likesCount: (map['likesCount'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'content': content,
    'authorId': authorId,
    'authorName': authorName,
    'authorPhoto': authorPhoto,
    'authorType': authorType,
    'createdAt': createdAt.toIso8601String(),
    'isPinned': isPinned,
    'likesCount': likesCount,
  };
}
