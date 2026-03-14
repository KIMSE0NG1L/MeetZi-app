import 'package:flutter/material.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:nearo_app/shared/utils/photo_url.dart';

Widget buildMatchCardAvatar(
  Map<String, dynamic> profile, {
  double size = 96,
}) {
  final user = profile['user'] as Map<String, dynamic>? ?? const {};
  final displayType = (profile['boardDisplayType'] ?? user['boardDisplayType'])
      ?.toString()
      .trim()
      .toLowerCase();

  if (displayType == 'photo') {
    final photos = user['photos'] ?? profile['photos'];
    if (photos is List && photos.isNotEmpty && photos.first is Map) {
      final key = (photos.first as Map)['storageKey']?.toString();
      if (key != null && key.isNotEmpty) {
        final url = photoUrlFromStorageKey(key);
        if (url != null && url.isNotEmpty) {
          return ClipOval(
            child: Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          );
        }
      }
    }
  }

  final seed = user['avatarSeed']?.toString() ??
      profile['avatarSeed']?.toString() ??
      profile['userId']?.toString() ??
      profile['nickname']?.toString() ??
      'user';
  return DiceBearAvatar(
    style: user['avatarStyle']?.toString() ?? 'lorelei',
    seed: seed,
    size: size,
  );
}
