import 'dart:io';

abstract final class AdConstants {
  // Official Google AdMob Test Ad Unit IDs
  static const String androidBannerTestId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String androidInterstitialTestId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String androidRewardedTestId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String iosBannerTestId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String iosInterstitialTestId =
      'ca-app-pub-3940256099942544/4411468910';
  static const String iosRewardedTestId =
      'ca-app-pub-3940256099942544/1712485313';

  static String get bannerAdUnitId {
    if (Platform.isIOS) {
      return iosBannerTestId;
    }
    return androidBannerTestId;
  }

  static String get interstitialAdUnitId {
    if (Platform.isIOS) {
      return iosInterstitialTestId;
    }
    return androidInterstitialTestId;
  }

  static String get rewardedAdUnitId {
    if (Platform.isIOS) {
      return iosRewardedTestId;
    }
    return androidRewardedTestId;
  }
}
