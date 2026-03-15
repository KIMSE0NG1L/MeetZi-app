Map<String, dynamic>? mergeProfileMaps(List<Map<String, dynamic>?> maps) {
  final merged = <String, dynamic>{};
  var hasAny = false;

  for (final map in maps) {
    if (map == null) continue;
    hasAny = true;

    map.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      merged[key] = value;
    });

    final nestedUser = map['user'];
    if (nestedUser is Map<String, dynamic>) {
      final userOut = Map<String, dynamic>.from(
        merged['user'] is Map<String, dynamic>
            ? merged['user'] as Map<String, dynamic>
            : const <String, dynamic>{},
      );
      nestedUser.forEach((key, value) {
        if (value == null) return;
        if (value is String && value.trim().isEmpty) return;
        userOut[key] = value;
      });
      merged['user'] = userOut;
    }
  }

  return hasAny ? merged : null;
}

Map<String, dynamic>? resolveReceivedRequestTargetProfile(
  Map<String, dynamic> request, {
  Map<String, dynamic>? primary,
}) {
  return mergeProfileMaps([
    primary,
    request['requesterProfile'] as Map<String, dynamic>?,
    request['requester'] as Map<String, dynamic>?,
  ]);
}

Map<String, dynamic>? resolveSentRequestTargetProfile(
  Map<String, dynamic> request, {
  Map<String, dynamic>? primary,
}) {
  return mergeProfileMaps([
    primary,
    request['profile'] as Map<String, dynamic>?,
    request['recipientProfile'] as Map<String, dynamic>?,
    request['recipient'] as Map<String, dynamic>?,
  ]);
}
