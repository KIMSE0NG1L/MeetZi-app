import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nearo_app/core/ads/ad_service.dart';

/// 배너 광고 위젯 - 원하는 곳에 바로 삽입 가능
///
/// 사용 예시:
/// ```dart
/// const BannerAdWidget()
/// ```
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  final BannerAdLoader _loader = BannerAdLoader();
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loader.load(onLoaded: () {
      if (mounted) setState(() => _isLoaded = true);
    });
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _loader.ad == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _loader.ad!.size.width.toDouble(),
      height: _loader.ad!.size.height.toDouble(),
      child: AdWidget(ad: _loader.ad!),
    );
  }
}
