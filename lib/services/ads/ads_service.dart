import 'dart:async';
import 'package:flutter/foundation.dart';

abstract class AdsService {
  Future<void> init();
  Future<void> loadInterstitial();
  Future<void> loadRewarded();
  Future<bool> showInterstitial({
    required String mode,
    required bool hasRemoveAds,
  });
  Future<bool> showRewarded({required Function() onUserEarnedReward});
  void recordGameCompleted();
  bool get isRewardedLoaded;
}

/// Ads are completely disabled as requested.
/// Interstitials never show, and rewarded actions instantly grant rewards without ads.
class MockAdsService implements AdsService {
  @override
  Future<void> init() async {
    debugPrint('[AdsService] Ads are currently disabled.');
  }

  @override
  Future<void> loadInterstitial() async {}

  @override
  Future<void> loadRewarded() async {}

  @override
  void recordGameCompleted() {}

  @override
  bool get isRewardedLoaded => true;

  @override
  Future<bool> showInterstitial({
    required String mode,
    required bool hasRemoveAds,
  }) async {
    // Ads disabled: never show interstitials
    return false;
  }

  @override
  Future<bool> showRewarded({required Function() onUserEarnedReward}) async {
    // Instantly grant reward without showing any ads
    onUserEarnedReward();
    return true;
  }
}
