# Prism Blocks - Setup & Run Guide

## Prerequisites
- Flutter SDK 3.24+ (Tested on Flutter 3.44+ / Dart 3.12+)
- Android SDK 34+ / Xcode 15+ (for iOS)

## Environment Variables (`--dart-define`)
Prism Blocks requires zero hardcoded secrets. Pass the configuration via `--dart-define` parameters during run or build:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xyzcompany.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi... \
  --dart-define=ENV=dev
```

If Supabase variables are omitted, the game automatically operates in **Full Offline Mode** with local guest progress and mock cloud responses.

## Generating Sound Assets
Run the audio generation tool:
```bash
# Using Dart (built-in):
dart run tool/generate_sfx.dart

# Or using Python (if Python 3 is installed):
python tool/generate_sfx.py
```
This generates all synthesized 16-bit PCM `.wav` files into `assets/audio/`.
