import 'package:flutter/material.dart';

class VersionOverlay extends StatelessWidget {
  final String version;
  const VersionOverlay({super.key, this.version = "1.0.0.2"});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      top: 40,
      child: Text(
        version,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
