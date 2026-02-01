import 'package:flutter/material.dart';

class RatingsScreen extends StatelessWidget {
  const RatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('평가'),
      ),
      body: const Center(
        child: Text('평가 화면'),
      ),
    );
  }
}
