class ExpertDiscussion {
  final String id;
  final String title;
  final String description;
  final String userId;
  final String userName;
  final String userPhoto;
  final String userType;
  final int commentsCount;
  final int likesCount;
  final DateTime createdAt;

  ExpertDiscussion({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.userType,
    required this.commentsCount,
    required this.likesCount,
    required this.createdAt,
  });

  factory ExpertDiscussion.fromMap(String id, Map<String, dynamic> map) {
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

    return ExpertDiscussion(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? map['question'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhoto: map['userPhoto'] ?? '',
      userType: map['userType'] ?? '',
      commentsCount: (map['commentsCount'] ?? map['repliesCount'] ?? 0).toInt(),
      likesCount: (map['likesCount'] ?? 0).toInt(),
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'question': description, // write both for compatibility
    'userId': userId,
    'userName': userName,
    'userPhoto': userPhoto,
    'userType': userType,
    'commentsCount': commentsCount,
    'likesCount': likesCount,
    'createdAt': createdAt.toIso8601String(),
  };
}

class ExpertAnswer {
  final String id;
  final String userId;
  final String userName;
  final String userPhoto;
  final String userType;
  final String answer;
  final int likesCount;
  final DateTime createdAt;

  ExpertAnswer({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.userType,
    required this.answer,
    required this.likesCount,
    required this.createdAt,
  });

  factory ExpertAnswer.fromMap(String id, Map<String, dynamic> map) {
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

    return ExpertAnswer(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhoto: map['userPhoto'] ?? '',
      userType: map['userType'] ?? '',
      answer: map['answer'] ?? '',
      likesCount: (map['likesCount'] ?? 0).toInt(),
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'userPhoto': userPhoto,
    'userType': userType,
    'answer': answer,
    'likesCount': likesCount,
    'createdAt': createdAt.toIso8601String(),
  };
}
