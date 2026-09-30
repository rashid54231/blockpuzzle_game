# Prism Blocks - Store Submission Checklist

## 1. Google Play Console & Apple App Store Guidelines
- [ ] Working Title: Prism Blocks
- [ ] Package Name: `com.prismblocks.game` / `blockpuzzle_game`
- [ ] Version code & build number in `pubspec.yaml`
- [ ] Privacy Policy URL hosted and compliant with GDPR/CCPA
- [ ] UMP / ATT Consent Flow integrated before ad initialization
- [ ] Data Safety / App Privacy declarations:
  - AdMob: Device or Other IDs (Advertising ID), Analytics
  - Supabase Auth / Leaderboards: User ID, High Scores, Game Progress

## 2. In-App Purchases (IAP) Configured
- `com.prismblocks.remove_ads` (Non-consumable)
- `com.prismblocks.gems_tier1` (100 Gems consumable)
- `com.prismblocks.gems_tier2` (500 Gems consumable)
- `com.prismblocks.gems_tier3` (1200 Gems consumable)
- `com.prismblocks.undo_pack` (5 Undos consumable)

## 3. AdMob Production IDs
- Replace test App IDs and Unit IDs in `lib/shared/constants/ad_constants.dart` with live IDs.
