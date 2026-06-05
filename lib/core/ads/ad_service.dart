import 'dart:io' show Platform;
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// iOS 14+ ATT 권한 요청 (AdMob 초기화 전에 반드시 호출)
Future<void> requestTrackingAuthorization() async {
  if (!Platform.isIOS) return;
  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status == TrackingStatus.notDetermined) {
    await Future.delayed(const Duration(milliseconds: 200));
    await AppTrackingTransparency.requestTrackingAuthorization();
  }
}

/// AdMob 초기화 - main.dart의 MobileAds.instance.initialize() 대신 이것을 호출하세요
Future<void> initializeAdMob() async {
  await requestTrackingAuthorization();
  await MobileAds.instance.initialize();
  if (kDebugMode) {
    // 디버그 모드에서 테스트 기기 설정 (실기기에서 테스트 광고가 뜨게 함)
    // 실기기의 ID는 앱 실행 후 logcat에서 "Use RequestConfiguration" 메시지를 확인하세요
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: [
          'EMULATOR', // 에뮬레이터
          '8CDBCA32BC7096A3F53357955FDD8D97', // SM S931N (실기기)
        ],
      ),
    );
  }
}

/// AdMob 광고 유닛 ID 관리
/// ⚠️ 실제 배포 전에 테스트 ID → 실제 광고 유닛 ID로 교체하세요
class AdUnitIds {
  // ── 테스트용 ID (개발 중 사용) ──────────────────────────────
  static const String _testBanner       = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewarded     = 'ca-app-pub-3940256099942544/5224354917';

  // ── Android 실제 광고 유닛 ID ──────────────────────────────
  static const String _androidBanner       = 'ca-app-pub-4896108937305290/6990287089';
  static const String _androidInterstitial = 'ca-app-pub-4896108937305290/3190868213';
  static const String _androidRewarded     = 'ca-app-pub-4896108937305290/1861563965';

  // ── iOS 실제 광고 유닛 ID ──────────────────────────────────
  static const String _iosBanner       = 'ca-app-pub-4896108937305290/9452815779';
  static const String _iosInterstitial = 'ca-app-pub-4896108937305290/8139734100';
  static const String _iosRewarded     = 'ca-app-pub-4896108937305290/7183315041';

  static String get _liveBanner       => Platform.isIOS ? _iosBanner       : _androidBanner;
  static String get _liveInterstitial => Platform.isIOS ? _iosInterstitial : _androidInterstitial;
  static String get _liveRewarded     => Platform.isIOS ? _iosRewarded     : _androidRewarded;

  static String get banner       => kDebugMode ? _testBanner       : _liveBanner;
  static String get interstitial => kDebugMode ? _testInterstitial : _liveInterstitial;
  static String get rewarded     => kDebugMode ? _testRewarded     : _liveRewarded;
}

// ═══════════════════════════════════════════════════════════
// 배너 광고
// ═══════════════════════════════════════════════════════════

/// 배너 광고 로더
class BannerAdLoader {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  BannerAd? get ad => _bannerAd;

  Future<void> load({VoidCallback? onLoaded}) async {
    _bannerAd = BannerAd(
      adUnitId: AdUnitIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _isLoaded = true;
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMob] Banner failed: $error');
          ad.dispose();
          _bannerAd = null;
          _isLoaded = false;
        },
      ),
    );
    await _bannerAd!.load();
  }

  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
  }
}

// ═══════════════════════════════════════════════════════════
// 전면 광고 (Interstitial)
// ═══════════════════════════════════════════════════════════

class InterstitialAdService {
  InterstitialAd? _ad;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    await InterstitialAd.load(
      adUnitId: AdUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoaded = true;
          debugPrint('[AdMob] Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMob] Interstitial failed: $error');
          _isLoaded = false;
        },
      ),
    );
  }

  /// 광고 표시. 표시 후 자동으로 dispose & 재로드
  Future<void> show({VoidCallback? onDismissed}) async {
    if (!_isLoaded || _ad == null) {
      debugPrint('[AdMob] Interstitial not ready');
      return;
    }
    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        _isLoaded = false;
        onDismissed?.call();
        load(); // 다음 표시를 위해 미리 로드
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMob] Interstitial show failed: $error');
        ad.dispose();
        _ad = null;
        _isLoaded = false;
        load();
      },
    );
    await _ad!.show();
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
    _isLoaded = false;
  }
}

// ═══════════════════════════════════════════════════════════
// 보상형 광고 (Rewarded)
// ═══════════════════════════════════════════════════════════

class RewardedAdService {
  RewardedAd? _ad;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    await RewardedAd.load(
      adUnitId: AdUnitIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoaded = true;
          debugPrint('[AdMob] Rewarded loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMob] Rewarded failed: $error');
          _isLoaded = false;
        },
      ),
    );
  }

  /// 광고 표시.
  /// [onRewarded]: 유저가 광고를 끝까지 봤을 때 호출 (보상 지급 로직 넣는 곳)
  Future<void> show({
    required void Function(RewardItem reward) onRewarded,
    VoidCallback? onDismissed,
  }) async {
    if (!_isLoaded || _ad == null) {
      debugPrint('[AdMob] Rewarded not ready');
      return;
    }
    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        _isLoaded = false;
        onDismissed?.call();
        load(); // 다음 표시를 위해 미리 로드
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMob] Rewarded show failed: $error');
        ad.dispose();
        _ad = null;
        _isLoaded = false;
        load();
      },
    );
    await _ad!.show(onUserEarnedReward: (_, reward) => onRewarded(reward));
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
    _isLoaded = false;
  }
}
