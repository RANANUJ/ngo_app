class CommunityPost {
  final String id;
  final String title;
  final String content;
  final String communityId;
  final String communityName;
  final String authorId;
  final String authorName;
  final String authorPhoto;
  final String authorType;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final DateTime createdAt;
  final String? imageUrl;
  final String? videoUrl;
  final String? location;
  final double? latitude;
  final double? longitude;
  final int sharesCount;

  CommunityPost({
    required this.id,
    required this.title,
    required this.content,
    required this.communityId,
    required this.communityName,
    required this.authorId,
    required this.authorName,
    required this.authorPhoto,
    required this.authorType,
    required this.likesCount,
    required this.commentsCount,
    this.viewsCount = 0,
    required this.createdAt,
    this.imageUrl,
    this.videoUrl,
    this.location,
    this.latitude,
    this.longitude,
    this.sharesCount = 0,
  });

  factory CommunityPost.fromMap(String id, Map<String, dynamic> map) {
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

    return CommunityPost(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      communityId: map['communityId'] ?? '',
      communityName: map['communityName'] ?? '',
      authorId: map['authorId'] ?? map['userId'] ?? '',
      authorName: map['authorName'] ?? map['userName'] ?? '',
      authorPhoto: map['authorPhoto'] ?? map['userPhoto'] ?? '',
      authorType: map['authorType'] ?? map['userType'] ?? '',
      likesCount: (map['likesCount'] ?? 0).toInt(),
      commentsCount: (map['commentsCount'] ?? 0).toInt(),
      viewsCount: (map['viewsCount'] ?? 0).toInt(),
      createdAt: parseDateTime(map['createdAt']),
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],
      location: map['location'],
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      sharesCount: (map['sharesCount'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'content': content,
    'communityId': communityId,
    'communityName': communityName,
    'authorId': authorId,
    'userId': authorId, // write both for compatibility
    'authorName': authorName,
    'userName': authorName, // write both for compatibility
    'authorPhoto': authorPhoto,
    'userPhoto': authorPhoto, // write both for compatibility
    'authorType': authorType,
    'userType': authorType, // write both for compatibility
    'likesCount': likesCount,
    'commentsCount': commentsCount,
    'viewsCount': viewsCount,
    'createdAt': createdAt.toIso8601String(),
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (videoUrl != null) 'videoUrl': videoUrl,
    if (location != null) 'location': location,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    'sharesCount': sharesCount,
  };
}
