class ApiEndpoints {
  static const String authKakao = '/auth/kakao';
  static const String authKakaoCallback = '/auth/kakao/callback';
  static const String authProfile = '/auth/profile';
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
  static const String photos = '/photos';
  static const String photosUpload = '/photos/upload';
  static String photoById(String photoId) => '/photos/$photoId';
  static String photoVisibility(String photoId) =>
      '/photos/$photoId/visibility';
  static String photoPrimary(String photoId) => '/photos/$photoId/primary';
  static const String subscription = '/subscription';
  static const String subscriptionCancel = '/subscription/cancel';
  static const String subscriptionPause = '/subscription/pause';
  static const String subscriptionResume = '/subscription/resume';
  static const String subscriptionIsActive = '/subscription/is-active';
  static String emailVerificationRequest(String environmentId) =>
      '/environments/$environmentId/email-verifications/request';
  static String emailVerificationConfirm(String environmentId) =>
      '/environments/$environmentId/email-verifications/confirm';
  static const String health = '/health';
  static String userBlock(String userId) => '/users/block/$userId';

  // 커뮤니티 (학교별, 누구나 진입 가능)
  static String community(String environmentId) => '/communities/$environmentId';
  static String communityPosts(String environmentId) => '/communities/$environmentId/posts';
  static String communityPost(String environmentId, String postId) =>
      '/communities/$environmentId/posts/$postId';
  static String communityPostComments(String environmentId, String postId) =>
      '/communities/$environmentId/posts/$postId/comments';
  static String communityPostLike(String environmentId, String postId) =>
      '/communities/$environmentId/posts/$postId/like';
}
