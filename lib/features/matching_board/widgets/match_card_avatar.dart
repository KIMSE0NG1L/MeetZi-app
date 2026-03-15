import 'package:flutter/material.dart';
import 'package:nearo_app/shared/utils/dicebear_avatar.dart';
import 'package:nearo_app/shared/utils/photo_url.dart';

String? _resolvePhotoUrl(Map<String, dynamic> profile) {
  final user = profile['user'] as Map<String, dynamic>? ?? const {};
  final directKey = profile['photoStorageKey'] ??
      profile['primaryPhotoStorageKey'] ??
      user['photoStorageKey'] ??
      user['primaryPhotoStorageKey'];
  final directKeyString = directKey?.toString().trim();
  if (directKeyString != null && directKeyString.isNotEmpty) {
    return photoUrlFromStorageKey(directKeyString);
  }

  final photos = user['photos'] ?? profile['photos'];
  if (photos is List && photos.isNotEmpty) {
    final first = photos.first;
    if (first is Map) {
      final rawKey = first['storageKey'] ?? first['storage_key'] ?? first['key'];
      final key = rawKey?.toString().trim();
      if (key != null && key.isNotEmpty) {
        return photoUrlFromStorageKey(key);
      }
    }
    if (first is String && first.trim().isNotEmpty) {
      return photoUrlFromStorageKey(first.trim());
    }
  }

  final rawUrl = profile['photoUrl'] ?? user['photoUrl'];
  final photoUrl = rawUrl?.toString().trim();
  if (photoUrl != null && photoUrl.isNotEmpty) {
    return photoUrlFromStorageKey(photoUrl);
  }

  return null;
}

Widget buildMatchCardAvatar(
  Map<String, dynamic> profile, {
  double size = 96,
}) {
  final user = profile['user'] as Map<String, dynamic>? ?? const {};
  final photoUrl = _resolvePhotoUrl(profile);
  if (photoUrl != null && photoUrl.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }

  final rawOptions = user['avatarOptions'] ?? profile['avatarOptions'];
  final options = parseAvatarOptions(rawOptions);
  final seed = user['avatarSeed']?.toString() ??
      profile['avatarSeed']?.toString() ??
      user['id']?.toString() ??
      profile['id']?.toString() ??
      profile['userId']?.toString() ??
      profile['nickname']?.toString() ??
      'user';
  return DiceBearAvatar(
    style: user['avatarStyle']?.toString() ?? 'lorelei',
    seed: seed,
    options: options.isNotEmpty ? options : null,
    size: size,
  );
}
