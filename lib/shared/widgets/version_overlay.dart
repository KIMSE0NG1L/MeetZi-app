import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionOverlay extends StatelessWidget {
  const VersionOverlay({super.key});

  Future<String> _getVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      top: 40,
      child: FutureBuilder<String>(
        future: _getVersion(),
        builder: (context, snapshot) {
          final version = snapshot.data ?? '';
          return Text(
            version,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          );
        },
      ),
    );
  }
}
