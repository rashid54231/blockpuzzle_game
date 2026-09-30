abstract class ConsentService {
  Future<void> requestConsent();
  Future<void> showPrivacyOptions();
  bool get canRequestAds;
}

class AppConsentService implements ConsentService {
  bool _canRequestAds = true;

  @override
  bool get canRequestAds => _canRequestAds;

  @override
  Future<void> requestConsent() async {
    // In production UMP handles consent form if in EEA/UK
    _canRequestAds = true;
  }

  @override
  Future<void> showPrivacyOptions() async {
    // Reopens UMP privacy options dialog
  }
}
