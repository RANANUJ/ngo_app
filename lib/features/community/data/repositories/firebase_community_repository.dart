import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/community.dart';
import '../../domain/models/community_post.dart';
import '../../domain/models/community_comment.dart';
import '../../domain/models/expert_discussion.dart';
import '../../domain/repositories/community_repository.dart';

class FirebaseCommunityRepository implements CommunityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Community>> streamCommunities() {
    return _firestore
        .collection('communities')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Community.fromMap(doc.id, doc.data()))
              .toList();
          list.sort((a, b) => b.memberCount.compareTo(a.memberCount));
          return list;
        });
  }

  @override
  Stream<Community?> streamCommunity(String communityId) {
    return _firestore
        .collection('communities')
        .doc(communityId)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null ? Community.fromMap(doc.id, doc.data()!) : null);
  }

  @override
  Stream<List<CommunityPost>> streamCommunityPosts({String? communityId, String? userId}) {
    Query query = _firestore.collection('community_posts');
    if (communityId != null) {
      query = query.where('communityId', isEqualTo: communityId);
    }
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CommunityPost.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Stream<CommunityPost?> streamCommunityPost(String postId) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null ? CommunityPost.fromMap(doc.id, doc.data()!) : null);
  }

  @override
  Stream<List<CommunityComment>> streamPostComments(String postId) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('comments')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => CommunityComment.fromMap(doc.id, doc.data()))
              .toList();
          list.sort((a, b) {
            if (a.isPinned && !b.isPinned) return -1;
            if (!a.isPinned && b.isPinned) return 1;
            return b.createdAt.compareTo(a.createdAt);
          });
          return list;
        });
  }

  @override
  Stream<List<ExpertDiscussion>> streamExpertDiscussions() {
    return _firestore
        .collection('expert_discussions')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => ExpertDiscussion.fromMap(doc.id, doc.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  @override
  Stream<List<ExpertAnswer>> streamDiscussionAnswers(String discussionId) {
    return _firestore
        .collection('expert_discussions')
        .doc(discussionId)
        .collection('answers')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => ExpertAnswer.fromMap(doc.id, doc.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  @override
  Stream<bool> streamMembership(String communityId, String userId) {
    return _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  @override
  Stream<List<Map<String, dynamic>>> streamCommunityMembers(String communityId, {int? limit}) {
    Query query = _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members');
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  @override
  Stream<bool> streamPostLikeStatus(String postId, String userId) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  @override
  Stream<bool> streamAnswerLikeStatus(String discussionId, String answerId, String userId) {
    return _firestore
        .collection('expert_discussions')
        .doc(discussionId)
        .collection('answers')
        .doc(answerId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  @override
  Future<void> createCommunity(Community community) async {
    final ref = await _firestore.collection('communities').add({
      ...community.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await ref.collection('members').doc(community.creatorId).set({
      'joinedAt': FieldValue.serverTimestamp(),
      'role': 'creator',
      'memberName': community.creatorName,
      'memberLogo': community.creatorLogo,
      'userId': community.creatorId,
    });
  }

  @override
  Future<void> joinCommunity(String communityId, String userId, String userName, String userLogo) async {
    await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(userId)
        .set({
      'joinedAt': FieldValue.serverTimestamp(),
      'role': 'member',
      'memberName': userName,
      'memberLogo': userLogo,
      'userId': userId,
    });
    
    await _firestore.collection('communities').doc(communityId).update({
      'memberCount': FieldValue.increment(1),
    });
  }

  @override
  Future<void> leaveCommunity(String communityId, String userId) async {
    await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .doc(userId)
        .delete();
        
    await _firestore.collection('communities').doc(communityId).update({
      'memberCount': FieldValue.increment(-1),
    });
  }

  @override
  Future<void> createPost(CommunityPost post) async {
    await _firestore.collection('community_posts').add({
      ...post.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> toggleLikePost(String postId, String userId, String userName) async {
    final postRef = _firestore.collection('community_posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);
    final likeDoc = await likeRef.get();

    String userColl = 'volunteers';
    String userPhoto = '';
    try {
      final volDoc = await _firestore.collection('volunteers').doc(userId).get();
      if (volDoc.exists) {
        userPhoto = volDoc.data()?['photoUrl'] ?? volDoc.data()?['profileImageUrl'] ?? '';
      } else {
        final ngoDoc = await _firestore.collection('ngo_registrations').doc(userId).get();
        if (ngoDoc.exists) {
          userColl = 'ngo_registrations';
          userPhoto = ngoDoc.data()?['photoUrl'] ?? ngoDoc.data()?['ngoLogo'] ?? '';
        }
      }
    } catch (_) {}

    final userLikeRef = _firestore
        .collection(userColl)
        .doc(userId)
        .collection('liked_posts')
        .doc(postId);

    if (likeDoc.exists) {
      await likeRef.delete();
      await userLikeRef.delete();
      await postRef.update({'likesCount': FieldValue.increment(-1)});
    } else {
      await likeRef.set({
        'likedAt': FieldValue.serverTimestamp(),
        'userName': userName,
        'userPhoto': userPhoto,
        'userId': userId,
      });
      await userLikeRef.set({
        'likedAt': FieldValue.serverTimestamp(),
      });
      await postRef.update({'likesCount': FieldValue.increment(1)});
    }
  }

  @override
  Future<void> addComment(String postId, CommunityComment comment) async {
    final postRef = _firestore.collection('community_posts').doc(postId);
    await postRef.collection('comments').add({
      ...comment.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await postRef.update({'commentsCount': FieldValue.increment(1)});
  }

  @override
  Future<void> askExpertQuestion(ExpertDiscussion discussion) async {
    await _firestore.collection('expert_discussions').add({
      ...discussion.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> answerExpertQuestion(String discussionId, ExpertAnswer answer, String userType) async {
    final discussionRef = _firestore.collection('expert_discussions').doc(discussionId);
    await discussionRef.collection('answers').add({
      ...answer.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await discussionRef.update({'commentsCount': FieldValue.increment(1)});
  }

  @override
  Future<void> toggleLikeAnswer(String discussionId, String answerId, String userId) async {
    final answerRef = _firestore
        .collection('expert_discussions')
        .doc(discussionId)
        .collection('answers')
        .doc(answerId);
    final likeRef = answerRef.collection('likes').doc(userId);
    final likeDoc = await likeRef.get();
    
    if (likeDoc.exists) {
      await likeRef.delete();
      await answerRef.update({'likesCount': FieldValue.increment(-1)});
    } else {
      await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
      await answerRef.update({'likesCount': FieldValue.increment(1)});
    }
  }

  @override
  Stream<bool> streamDiscussionLikeStatus(String discussionId, String userId) {
    return _firestore
        .collection('expert_discussions')
        .doc(discussionId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  @override
  Future<void> toggleLikeDiscussion(String discussionId, String userId) async {
    final docRef = _firestore.collection('expert_discussions').doc(discussionId);
    final likeRef = docRef.collection('likes').doc(userId);
    final likeDoc = await likeRef.get();

    if (likeDoc.exists) {
      await likeRef.delete();
      await docRef.update({'likesCount': FieldValue.increment(-1)});
    } else {
      await likeRef.set({
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await docRef.update({'likesCount': FieldValue.increment(1)});
    }
  }

  @override
  Future<void> updateCommunity(String communityId, Map<String, dynamic> data) async {
    await _firestore.collection('communities').doc(communityId).update(data);
  }

  @override
  Future<void> deleteCommunity(String communityId) async {
    // Delete all members subcollection
    final membersSnapshot = await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .get();
    
    for (var doc in membersSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete the community itself
    await _firestore.collection('communities').doc(communityId).delete();
  }

  @override
  Future<void> deletePost(String postId) async {
    // Delete comments
    final comments = await _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('comments')
        .get();
    
    for (var doc in comments.docs) {
      await doc.reference.delete();
    }

    // Delete likes
    final likes = await _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('likes')
        .get();

    for (var doc in likes.docs) {
      await doc.reference.delete();
    }

    // Delete the post
    await _firestore.collection('community_posts').doc(postId).delete();
  }

  @override
  Future<void> toggleSavePost(String postId, String userId, String userType) async {
    final saveRef = _firestore
        .collection(userType == 'ngo' ? 'ngo_registrations' : 'volunteers')
        .doc(userId)
        .collection('saved_posts')
        .doc(postId);
    final doc = await saveRef.get();
    if (doc.exists) {
      await saveRef.delete();
    } else {
      await saveRef.set({
        'savedAt': FieldValue.serverTimestamp(),
        'postId': postId,
      });
    }
  }

  @override
  Stream<bool> streamSaveStatus(String postId, String userId, String userType) {
    return _firestore
        .collection(userType == 'ngo' ? 'ngo_registrations' : 'volunteers')
        .doc(userId)
        .collection('saved_posts')
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  @override
  Stream<List<CommunityPost>> streamSavedPosts(String userId, String userType) {
    return _firestore
        .collection(userType == 'ngo' ? 'ngo_registrations' : 'volunteers')
        .doc(userId)
        .collection('saved_posts')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final postIds = snapshot.docs.map((doc) => doc.id).toList();
          if (postIds.isEmpty) return <CommunityPost>[];

          final postsSnapshot = await _firestore
              .collection('community_posts')
              .where(FieldPath.documentId, whereIn: postIds)
              .get();

          final list = postsSnapshot.docs
              .map((doc) => CommunityPost.fromMap(doc.id, doc.data()))
              .toList();

          list.sort((a, b) => postIds.indexOf(a.id).compareTo(postIds.indexOf(b.id)));
          return list;
        });
  }

  @override
  Stream<List<CommunityPost>> streamLikedPosts(String userId) {
    return _firestore.collection('volunteers').doc(userId).snapshots().asyncExpand((volSnap) {
      final userColl = volSnap.exists ? 'volunteers' : 'ngo_registrations';

      return _firestore
          .collection(userColl)
          .doc(userId)
          .collection('liked_posts')
          .orderBy('likedAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            final postIds = snapshot.docs.map((doc) => doc.id).toList();
            if (postIds.isEmpty) return <CommunityPost>[];

            final postsSnapshot = await _firestore
                .collection('community_posts')
                .where(FieldPath.documentId, whereIn: postIds)
                .get();

            final list = postsSnapshot.docs
                .map((doc) => CommunityPost.fromMap(doc.id, doc.data()))
                .toList();

            list.sort((a, b) => postIds.indexOf(a.id).compareTo(postIds.indexOf(b.id)));
            return list;
          });
    });
  }

  @override
  Future<void> toggleLikeComment(String postId, String commentId, String userId) async {
    final commentRef = _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    final likeRef = commentRef.collection('likes').doc(userId);
    final likeDoc = await likeRef.get();

    if (likeDoc.exists) {
      await likeRef.delete();
      await commentRef.update({'likesCount': FieldValue.increment(-1)});
    } else {
      await likeRef.set({
        'likedAt': FieldValue.serverTimestamp(),
      });
      await commentRef.update({'likesCount': FieldValue.increment(1)});
    }
  }

  @override
  Future<void> togglePinComment(String postId, String commentId, bool currentPinState) async {
    final commentRef = _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    await commentRef.update({
      'isPinned': !currentPinState,
    });
  }

  @override
  Stream<bool> streamCommentLikeStatus(String postId, String commentId, String userId) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
