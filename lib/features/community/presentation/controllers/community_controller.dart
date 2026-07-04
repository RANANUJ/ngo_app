import 'package:flutter/material.dart';
import '../../domain/models/community.dart';
import '../../domain/models/community_post.dart';
import '../../domain/models/community_comment.dart';
import '../../domain/models/expert_discussion.dart';
import '../../domain/repositories/community_repository.dart';

class CommunityController extends ChangeNotifier {
  final CommunityRepository _repository;

  bool _isLoading = false;
  String? _error;

  CommunityController(this._repository);

  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<Community>> streamCommunities() {
    return _repository.streamCommunities();
  }

  Stream<Community?> streamCommunity(String communityId) {
    return _repository.streamCommunity(communityId);
  }

  Stream<List<CommunityPost>> streamCommunityPosts({String? communityId, String? userId}) {
    return _repository.streamCommunityPosts(communityId: communityId, userId: userId);
  }

  Stream<CommunityPost?> streamCommunityPost(String postId) {
    return _repository.streamCommunityPost(postId);
  }

  Stream<List<CommunityComment>> streamPostComments(String postId) {
    return _repository.streamPostComments(postId);
  }

  Stream<List<ExpertDiscussion>> streamExpertDiscussions() {
    return _repository.streamExpertDiscussions();
  }

  Stream<List<ExpertAnswer>> streamDiscussionAnswers(String discussionId) {
    return _repository.streamDiscussionAnswers(discussionId);
  }

  Stream<bool> streamMembership(String communityId, String userId) {
    return _repository.streamMembership(communityId, userId);
  }

  Stream<List<Map<String, dynamic>>> streamCommunityMembers(String communityId, {int? limit}) {
    return _repository.streamCommunityMembers(communityId, limit: limit);
  }

  Stream<bool> streamPostLikeStatus(String postId, String userId) {
    return _repository.streamPostLikeStatus(postId, userId);
  }

  Stream<bool> streamAnswerLikeStatus(String discussionId, String answerId, String userId) {
    return _repository.streamAnswerLikeStatus(discussionId, answerId, userId);
  }

  Future<bool> createCommunity({
    required String name,
    required String description,
    required String category,
    required String creatorId,
    required String creatorName,
    required String creatorLogo,
    String imageUrl = '',
    String coverUrl = '',
    List<String> rules = const [],
    bool isPublic = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final community = Community(
        id: '',
        name: name,
        description: description,
        category: category,
        creatorId: creatorId,
        creatorName: creatorName,
        creatorLogo: creatorLogo,
        memberCount: 1,
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
        coverUrl: coverUrl,
        rules: rules,
        postsCount: 0,
        isPublic: isPublic,
      );
      await _repository.createCommunity(community);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> joinCommunity({
    required String communityId,
    required String userId,
    required String userName,
    required String userLogo,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.joinCommunity(communityId, userId, userName, userLogo);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> leaveCommunity({
    required String communityId,
    required String userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.leaveCommunity(communityId, userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createPost({
    required String title,
    required String content,
    required String communityId,
    required String communityName,
    required String authorId,
    required String authorName,
    required String authorPhoto,
    required String authorType,
    String? imageUrl,
    String? videoUrl,
    String? location,
    double? latitude,
    double? longitude,
    int sharesCount = 0,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final post = CommunityPost(
        id: '',
        title: title,
        content: content,
        communityId: communityId,
        communityName: communityName,
        authorId: authorId,
        authorName: authorName,
        authorPhoto: authorPhoto,
        authorType: authorType,
        likesCount: 0,
        commentsCount: 0,
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        location: location,
        latitude: latitude,
        longitude: longitude,
        sharesCount: sharesCount,
      );
      await _repository.createPost(post);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleLikePost({
    required String postId,
    required String userId,
    required String userName,
  }) async {
    try {
      await _repository.toggleLikePost(postId, userId, userName);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> addComment({
    required String postId,
    required String content,
    required String authorId,
    required String authorName,
    required String authorPhoto,
    required String authorType,
  }) async {
    try {
      final comment = CommunityComment(
        id: '',
        content: content,
        authorId: authorId,
        authorName: authorName,
        authorPhoto: authorPhoto,
        authorType: authorType,
        createdAt: DateTime.now(),
      );
      await _repository.addComment(postId, comment);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> askExpertQuestion({
    required String title,
    required String description,
    required String userId,
    required String userName,
    required String userPhoto,
    required String userType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final discussion = ExpertDiscussion(
        id: '',
        title: title,
        description: description,
        userId: userId,
        userName: userName,
        userPhoto: userPhoto,
        userType: userType,
        commentsCount: 0,
        likesCount: 0,
        createdAt: DateTime.now(),
      );
      await _repository.askExpertQuestion(discussion);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> answerExpertQuestion({
    required String discussionId,
    required String answerText,
    required String userId,
    required String userName,
    required String userPhoto,
    required String userType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final answer = ExpertAnswer(
        id: '',
        userId: userId,
        userName: userName,
        userPhoto: userPhoto,
        userType: userType,
        answer: answerText,
        likesCount: 0,
        createdAt: DateTime.now(),
      );
      await _repository.answerExpertQuestion(discussionId, answer, userType);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleLikeAnswer({
    required String discussionId,
    required String answerId,
    required String userId,
  }) async {
    try {
      await _repository.toggleLikeAnswer(discussionId, answerId, userId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Stream<bool> streamDiscussionLikeStatus(String discussionId, String userId) {
    return _repository.streamDiscussionLikeStatus(discussionId, userId);
  }

  Future<bool> toggleLikeDiscussion({
    required String discussionId,
    required String userId,
  }) async {
    try {
      await _repository.toggleLikeDiscussion(discussionId, userId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> updateCommunity({
    required String communityId,
    required Map<String, dynamic> data,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateCommunity(communityId, data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCommunity({
    required String communityId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteCommunity(communityId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePost({
    required String postId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deletePost(postId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleSavePost({
    required String postId,
    required String userId,
    required String userType,
  }) async {
    try {
      await _repository.toggleSavePost(postId, userId, userType);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Stream<bool> streamSaveStatus(String postId, String userId, String userType) {
    return _repository.streamSaveStatus(postId, userId, userType);
  }

  Stream<List<CommunityPost>> streamSavedPosts(String userId, String userType) {
    return _repository.streamSavedPosts(userId, userType);
  }

  Stream<List<CommunityPost>> streamLikedPosts(String userId) {
    return _repository.streamLikedPosts(userId);
  }

  Future<bool> toggleLikeComment({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    try {
      await _repository.toggleLikeComment(postId, commentId, userId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> togglePinComment({
    required String postId,
    required String commentId,
    required bool currentPinState,
  }) async {
    try {
      await _repository.togglePinComment(postId, commentId, currentPinState);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Stream<bool> streamCommentLikeStatus(String postId, String commentId, String userId) {
    return _repository.streamCommentLikeStatus(postId, commentId, userId);
  }
}
