import 'package:flutter/foundation.dart';

class PendingMatchAcceptStore {
  static final PendingMatchAcceptStore instance = PendingMatchAcceptStore._();
  PendingMatchAcceptStore._();

  final ValueNotifier<PendingMatchAccept?> pending =
      ValueNotifier<PendingMatchAccept?>(null);

  void setPending({
    required String requestId,
    String? roomId,
    String? matchId,
  }) {
    pending.value = PendingMatchAccept(
      requestId: requestId,
      roomId: roomId,
      matchId: matchId,
    );
  }

  void clear() {
    pending.value = null;
  }
}

class PendingMatchAccept {
  const PendingMatchAccept({
    required this.requestId,
    this.roomId,
    this.matchId,
  });

  final String requestId;
  final String? roomId;
  final String? matchId;
}
