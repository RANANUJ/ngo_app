import '../../domain/models/community.dart';
import '../../domain/models/community_post.dart';
import '../../domain/models/community_comment.dart';
import '../../domain/models/expert_discussion.dart';

abstract class CommunityRepository {
  Stream<List<Community>> streamCommunities();
  Stream<Community?> streamCommunity(String communityId);
  Stream<List<CommunityPost>> streamCommunityPosts({String? communityId, String? userId});
  Stream<CommunityPost?> streamCommunityPost(String postId);
  Stream<List<CommunityComment>> streamPostComments(String postId);
  Stream<List<ExpertDiscussion>> streamExpertDiscussions();
  Stream<List<ExpertAnswer>> streamDiscussionAnswers(String discussionId);
  
  Stream<bool> streamMembership(String communityId, String userId);
  Stream<List<Map<String, dynamic>>> streamCommunityMembers(String communityId, {int? limit});
  Stream<bool> streamPostLikeStatus(String postId, String userId);
  Stream<bool> streamAnswerLikeStatus(String discussionId, String answerId, String userId);
  Stream<bool> streamDiscussionLikeStatus(String discussionId, String userId);

  Future<void> createCommunity(Community community);
  Future<void> joinCommunity(String communityId, String userId, String userName, String userLogo);
  Future<void> leaveCommunity(String communityId, String userId);
  
  Future<void> createPost(CommunityPost post);
  Future<void> toggleLikePost(String postId, String userId, String userName);
  Future<void> deletePost(String postId);
  Future<void> addComment(String postId, CommunityComment comment);
  
  Future<void> askExpertQuestion(ExpertDiscussion discussion);
  Future<void> answerExpertQuestion(String discussionId, ExpertAnswer answer, String userType);
  Future<void> toggleLikeAnswer(String discussionId, String answerId, String userId);
  Future<void> toggleLikeDiscussion(String discussionId, String userId);
  Future<void> updateCommunity(String communityId, Map<String, dynamic> data);
  Future<void> deleteCommunity(String communityId);
  Future<void> toggleSavePost(String postId, String userId, String userType);
  Stream<bool> streamSaveStatus(String postId, String userId, String userType);
  Stream<List<CommunityPost>> streamSavedPosts(String userId, String userType);
  Stream<List<CommunityPost>> streamLikedPosts(String userId);
  Future<void> toggleLikeComment(String postId, String commentId, String userId);
  Future<void> togglePinComment(String postId, String commentId, bool currentPinState);
  Stream<bool> streamCommentLikeStatus(String postId, String commentId, String userId);
}
