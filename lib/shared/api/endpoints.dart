class ApiEndpoints {
  static const String authKakao = '/auth/kakao';
  static const String authKakaoCallback = '/auth/kakao/callback';
  static const String authProfile = '/auth/profile';
  static const String authRefresh = '/auth/refresh';
  static const String avatarInit = '/users/me/avatar/init';
  static const String accountDelete = '/users/me';
  static const String matchingRequest = '/matching/request';
  static const String matchingCancel = '/matching/cancel';
  static const String matchingActive = '/matching/active';
  static String matchingConsent(String matchId) => '/matching/$matchId/consent';
  static String matchingConsentStatus(String matchId) =>
      '/matching/$matchId/consent-status';
  static const String chatsRooms = '/chats/rooms';
  static String chatsRoom(String roomId) => '/chats/rooms/$roomId';
  static String chatsRoomMute(String roomId) => '/chats/rooms/$roomId/mute';
  static String chatsMessages(String roomId) => '/chats/rooms/$roomId/messages';
  static String chatsMessageRead(String roomId, String messageId) =>
      '/chats/rooms/$roomId/messages/$messageId/read';
  static String chatsMessagesReadAll(String roomId) =>
      '/chats/rooms/$roomId/messages/read-all';
  static const String sharedChatPosts = '/shared-chat-posts';
  static const String sharedChatMine = '/shared-chat-posts/me';
  static String sharedChatPost(String id) => '/shared-chat-posts/$id';
  static String sharedChatConsent(String id) =>
      '/shared-chat-posts/$id/consent';
  static const String photos = '/photos';
  static const String photosUpload = '/photos/upload';
  static String photoById(String photoId) => '/photos/$photoId';
  static String photoVisibility(String photoId) =>
      '/photos/$photoId/visibility';
  static String photoPrimary(String photoId) => '/photos/$photoId/primary';
  static String emailVerificationRequest(String environmentId) =>
      '/environments/$environmentId/email-verifications/request';
  static String emailVerificationConfirm(String environmentId) =>
      '/environments/$environmentId/email-verifications/confirm';
  static String userBlock(String userId) => '/users/block/$userId';

  static String community(String environmentId) => '/communities/$environmentId';
  static String communityPosts(String environmentId) =>
      '/communities/$environmentId/posts';
  static String communityPost(String environmentId, String postId) =>
      '/communities/$environmentId/posts/$postId';
  static String communityPostDelete(String environmentId, String postId) =>
      '/communities/$environmentId/posts/$postId';
  static String communityPostComments(String environmentId, String postId) =>
      '/communities/$environmentId/posts/$postId/comments';
  static String communityPostLike(String environmentId, String postId) =>
      '/communities/$environmentId/posts/$postId/like';
  static String communityPostCommentLike(
    String environmentId,
    String postId,
    String commentId,
  ) =>
      '/communities/$environmentId/posts/$postId/comments/$commentId/like';
  static String communityPostCommentDelete(
    String environmentId,
    String postId,
    String commentId,
  ) =>
      '/communities/$environmentId/posts/$postId/comments/$commentId';
  static String communityPostVote(String environmentId, String postId) =>
      '/communities/$environmentId/posts/$postId/vote';

  static const String communityGlobalPosts = '/communities/global/posts';
  static String communityGlobalPost(String postId) =>
      '/communities/global/posts/$postId';
  static String communityGlobalPostDelete(String postId) =>
      '/communities/global/posts/$postId';
  static String communityGlobalPostComments(String postId) =>
      '/communities/global/posts/$postId/comments';
  static String communityGlobalPostLike(String postId) =>
      '/communities/global/posts/$postId/like';
  static String communityGlobalPostCommentLike(
    String postId,
    String commentId,
  ) =>
      '/communities/global/posts/$postId/comments/$commentId/like';
  static String communityGlobalPostCommentDelete(
    String postId,
    String commentId,
  ) =>
      '/communities/global/posts/$postId/comments/$commentId';
  static String communityGlobalPostVote(String postId) =>
      '/communities/global/posts/$postId/vote';

  static const String reportCommunityPost = '/report/community-post';
  static const String reportCommunityComment = '/report/community-comment';
  static const String notices = '/notices';

  // Event (출석체크 + 친구초대)
  static const String eventAttendance = '/events/attendance';
  static const String eventAttendanceStatus = '/events/attendance/status';
  static const String eventReferralMyCode = '/events/referral/my-code';
  static const String eventReferralApply = '/events/referral/apply';
  static const String eventReferralStatus = '/events/referral/status';

  // Ad Reward (리워드 광고 시청 → 매칭권 지급)
  static const String adRewardClaim = '/ad-reward/claim';
  static const String adRewardStatus = '/ad-reward/status';
}
