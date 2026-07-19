import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/features/newfeed/models/post_model.dart';
import 'package:frontend/features/newfeed/models/comment_model.dart';
import 'package:frontend/features/newfeed/services/feed_service.dart';
import 'package:frontend/features/profile/services/profile_service.dart';
import 'package:frontend/features/friends/services/friend_service.dart';

class ProfileProvider extends ChangeNotifier {
  List<PostModel> _posts = [];
  List<FriendSummaryModel> _friends = [];
  List<FriendSummaryModel> _externalFriends = [];
  bool _isLoading = false;
  bool _isLoadingExternalFriends = false;
  String? _errorMessage;
  UserProfileModel? _userProfile;
  UserProfileModel? _externalUserProfile;
  final Map<String, List<CommentModel>> _commentsMap = {};

  String? userName;
  String? birthday;
  String? gender;

  List<PostModel> get posts => List.unmodifiable(_posts);
  List<FriendSummaryModel> get friends => List.unmodifiable(_friends);
  List<FriendSummaryModel> get externalFriends => List.unmodifiable(_externalFriends);
  bool get isLoading => _isLoading;
  bool get isLoadingExternalFriends => _isLoadingExternalFriends;
  String? get errorMessage => _errorMessage;
  UserProfileModel? get userProfile => _userProfile;
  UserProfileModel? get externalUserProfile => _externalUserProfile;
  Map<String, List<CommentModel>> get commentsMap => _commentsMap;

  int get photoCount => _posts.where((p) => p.mediaUrls.isNotEmpty).length;
  int get friendCount => _friends.length;
  int get externalFriendCount => _externalFriends.length;
  int get postCount => _posts.length;

  void setExternalPosts(List<PostModel> posts) {
    _posts = posts;
    notifyListeners();
  }

  void setExternalUserProfile(UserProfileModel profile) {
    _externalUserProfile = profile;
    notifyListeners();
  }

  void setExternalFriends(List<FriendSummaryModel> friends) {
    _externalFriends = friends;
    notifyListeners();
  }

  List<CommentModel> getCommentsForPost(String postId) => _commentsMap[postId] ?? [];

  Future<void> fetchComments(String postId) async {
    try {
      final comments = await FeedService.getComments(postId);
      _commentsMap[postId] = comments;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<CommentModel?> addComment(String postId, String content, XFile? image) async {
    try {
      final comment = await FeedService.createComment(
        feedId: postId,
        content: content,
        image: image,
      );

      final currentComments = _commentsMap[postId] ?? [];
      _commentsMap[postId] = [...currentComments, comment];

      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _posts[index];
        _posts[index] = post.copyWith(commentCount: post.commentCount + 1);
      }

      notifyListeners();
      return comment;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> toggleCommentLike(String postId, String commentId) async {
    final comments = _commentsMap[postId] ?? [];
    final index = comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final comment = comments[index];
    final wasLiked = comment.isLiked;

    comments[index] = comment.copyWith(
      isLiked: !wasLiked,
      likeCount: wasLiked ? comment.likeCount - 1 : comment.likeCount + 1,
    );
    notifyListeners();

    try {
      await FeedService.toggleLikeComment(commentId);
    } catch (e) {
      comments[index] = comment;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleLike(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final wasLiked = post.isLiked;

    _posts[index] = post.copyWith(
      isLiked: !wasLiked,
      likeCount: wasLiked ? post.likeCount - 1 : post.likeCount + 1,
    );
    notifyListeners();

    try {
      await FeedService.likePost(postId);
    } catch (e) {
      _posts[index] = post;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadProfile(String userId) async {
    _posts = [];
    _friends = [];
    _userProfile = null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Run each fetch independently so a failure in one doesn't blow away
    // the others (e.g. if a single endpoint returns 500/401, posts should
    // still load and the UI should not show empty). Previously we used
    // Future.wait which aborts the whole batch on the first rejection.
    final postsFuture = ProfileService.getUserPosts(userId)
        .then<List<PostModel>>((p) => p)
        .catchError((Object e) {
      _errorMessage =
          'Không thể tải bài viết: ${e.toString().replaceFirst('Exception: ', '')}';
      return <PostModel>[];
    });
    final friendsFuture = ProfileService.getFriends(userId: userId)
        .then<List<FriendSummaryModel>>((f) => f)
        .catchError((Object e) {
      _errorMessage =
          '${_errorMessage ?? ''}\nKhông thể tải bạn bè: ${e.toString().replaceFirst('Exception: ', '')}';
      return <FriendSummaryModel>[];
    });
    final profileFuture = ProfileService.getCurrentUserProfile()
        .then<UserProfileModel?>((p) => p)
        .catchError((Object e) {
      _errorMessage =
          '${_errorMessage ?? ''}\nKhông thể tải hồ sơ: ${e.toString().replaceFirst('Exception: ', '')}';
      return null;
    });

    final results = await Future.wait([postsFuture, friendsFuture, profileFuture]);

    _posts = results[0] as List<PostModel>;
    _friends = results[1] as List<FriendSummaryModel>;
    _userProfile = results[2] as UserProfileModel?;

    userName = _userProfile?.fullName;
    if (_userProfile?.dateOfBirth != null) {
      final dob = _userProfile!.dateOfBirth!;
      birthday = '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
    } else {
      birthday = null;
    }
    _isLoading = false;

    notifyListeners();
  }

  Future<void> refreshProfile(String userId) async {
    try {
      // Independent fetches so a failure in one doesn't kill the rest.
      final postsFuture = ProfileService.getUserPosts(userId)
          .then<List<PostModel>>((p) => p)
          .catchError((Object e) {
        _errorMessage =
            'Không thể tải bài viết: ${e.toString().replaceFirst('Exception: ', '')}';
        return _posts;
      });
      final friendsFuture = ProfileService.getFriends(userId: userId)
          .then<List<FriendSummaryModel>>((f) => f)
          .catchError((Object e) {
        _errorMessage =
            'Không thể tải bạn bè: ${e.toString().replaceFirst('Exception: ', '')}';
        return _friends;
      });

      final results = await Future.wait([postsFuture, friendsFuture]);

      final fetchedPosts = results[0] as List<PostModel>;

      // Merge strategy: if the freshly fetched list is *shorter* than what
      // we already had in cache (which happens right after creating a post
      // when Firestore read-after-write hasn't caught up yet), preserve any
      // cached posts whose IDs are missing from the response. This prevents
      // the optimistic "just created" post from being wiped out by a stale
      // empty fetch.
      final fetchedIds = fetchedPosts.map((p) => p.id).toSet();
      final missingFromFetch =
          _posts.where((p) => !fetchedIds.contains(p.id)).toList();
      if (missingFromFetch.isNotEmpty) {
        _posts = [...fetchedPosts, ...missingFromFetch];
      } else {
        _posts = fetchedPosts;
      }
      _friends = results[1] as List<FriendSummaryModel>;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadExternalFriends(String targetUserId) async {
    _isLoadingExternalFriends = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _externalFriends = await FriendService.getFriendsByUserId(targetUserId);
    } catch (e) {
      _errorMessage = e.toString();
      _externalFriends = [];
    }
    _isLoadingExternalFriends = false;
    notifyListeners();
  }

  void clearExternalFriends() {
    _externalFriends = [];
    notifyListeners();
  }

  void clearExternalUserProfile() {
    _externalUserProfile = null;
    _commentsMap.clear();
    notifyListeners();
  }

  void updateUserProfile(UserProfileModel updated) {
    _userProfile = updated;
    userName = updated.fullName;
    if (updated.dateOfBirth != null) {
      final dob = updated.dateOfBirth!;
      birthday = '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
    }
    notifyListeners();
  }

  void addPost(PostModel post) {
    _posts.insert(0, post);
    notifyListeners();
  }

  void clear() {
    _posts = [];
    _friends = [];
    _isLoading = false;
    _errorMessage = null;
    _userProfile = null;
    _externalUserProfile = null;
    _commentsMap.clear();
    userName = null;
    birthday = null;
    gender = null;
    notifyListeners();
  }
}
