import 'package:flutter/foundation.dart';

/// 포그라운드에서 받은 가져가기 요청 — 앱 사용 중 화면에 바로 띄우기 위해 사용
class PendingTakeNoteStore {
  static final PendingTakeNoteStore instance = PendingTakeNoteStore._();
  PendingTakeNoteStore._();

  final ValueNotifier<PendingTakeNoteRequest?> pending = ValueNotifier<PendingTakeNoteRequest?>(null);

  void setPending(String requestId, [Map<String, dynamic>? requesterProfile]) {
    pending.value = PendingTakeNoteRequest(
      requestId: requestId,
      requesterProfile: requesterProfile,
    );
  }

  void clear() {
    pending.value = null;
  }
}

class PendingTakeNoteRequest {
  const PendingTakeNoteRequest({
    required this.requestId,
    this.requesterProfile,
  });
  final String requestId;
  final Map<String, dynamic>? requesterProfile;
}
