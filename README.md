# Prism Blocks

A production-quality, responsive single-player block puzzle mobile game developed in Flutter with Flame engine integration, Riverpod state management, offline-first local storage, and Supabase cloud sync.

## ✨ Highlights & Features

- **Endless Classic Mode**: Endless score attack with quadratic line clearing bonuses, rolling score counter, and best record persistence.
- **Daily Challenge**: Worldwide deterministic daily seed sequence (`Mulberry32` PRNG) with global daily leaderboard and ranked attempts.
- **Zen Mode**: Relaxed, endless play where full boards auto-clear instead of causing game over.
- **Fair Piece Generator**: Intelligent placement guarantee, progressive difficulty curve, and full-board rescue bias.
- **Tactile Game Feel**: Finger-offset drag anchor, grid snap with ghost preview, projected line clear highlight, block shattering particle bursts, screen shake, and escalating combo chimes.
- **Themes & Cosmetics**: 6 custom jewel themes (Neon, Ocean, Sunset, Forest, Candy, Monochrome) with colorblind geometric shape marks.
- **Meta Economy & Streaks**: 7-day login reward calendar, streak tracking, achievements system (20 achievements with coin rewards), and career stats with custom painter score charts.
- **Monetization & GDPR**: Preloaded rewarded revive ads, frequency-capped interstitials, In-App Purchases (Gem Packs & Remove Ads), and UMP consent support.
- **Internationalization**: Full localization for English, Urdu (`ur`), Hindi (`hi`), and Arabic (`ar`) with bidirectional RTL layout support.
- **Offline-First**: Operates seamlessly offline with local saves; background retry queue synchronizes scores and progress when online.

---

## 🚀 Quick Start

### 1. Generate Procedural Audio Assets
```bash
dart run tool/generate_sfx.dart
```

### 2. Run Tests & Lints
```bash
flutter analyze
flutter test
```

### 3. Run Application
```bash
# Run in full offline/local mode:
flutter run

# Or with Supabase cloud backend enabled:
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi... \
  --dart-define=ENV=dev
```

---

## 📁 Project Structure

```
lib/
  main.dart
  app/                 # App widget, router, theme, Riverpod DI providers
  core/                # Pure Dart mathematical game logic (ZERO Flutter/Flame imports)
    board/             # Board, Cell, placement checks, simultaneous line clearing
    pieces/            # Piece catalog (29 unrotatable shapes), PieceShape
    generator/         # FairPieceGenerator, Mulberry32 PRNG
    scoring/           # ScoringRules (quadratic line points, combo multipliers, perfect clear)
    engine/            # GameEngine state machine, undo, revive, deterministic replay
    models/            # GameState, MoveRecord, RunResult, GameMode
  game/                # Flame engine layer: PrismFlameGame, particle manager, screen shake, block painter
  features/            # Home, Play, Daily, Shop, Themes, Stats, Achievements, Settings, Tutorial, Leaderboard
  services/            # Audio, Haptics, Ads, IAP, Analytics, Storage, Supabase, Sync, Consent, Notifications
  data/                # PlayerRepository, PlayerProgress model
  l10n/                # ARB files for en, ur, hi, ar
  shared/              # Design system: GlassCard, GradientButton, AnimatedCounter, PulseGlow, Theme tokens
supabase/
  schema.sql           # Idempotent database schema, RLS policies, triggers, and RPC functions
```
