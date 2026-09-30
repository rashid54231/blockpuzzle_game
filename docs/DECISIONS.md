# Architecture and Design Decisions (Prism Blocks)

This document tracks all non-trivial technical and product decisions made during implementation.

## 1. Single Working Title Constant
- Decision: Title is unified under `GameConstants.appTitle = 'Prism Blocks'` located in `lib/shared/constants/game_constants.dart`.
- Rationale: Requirement allows changing game title in one place without touching multiple files.

## 2. Flame Game Engine + Pure Dart Core Separation
- Decision: The mathematical board model, piece catalogue, line clear evaluation, scoring calculations, and PRNG piece generation are written in `lib/core/` with ZERO imports from Flutter or Flame.
- Rationale: Guarantees 100% testability, deterministic replays, server verification feasibility, and flawless unit testing without UI dependencies.

## 3. Seedable PRNG (Mulberry32)
- Decision: Implemented a pure Dart 32-bit stateful PRNG (`Mulberry32`) instead of `dart:math.Random`.
- Rationale: Ensures cross-platform identical sequence generation on Android, iOS, Web, and backend for the Daily Challenge puzzle.

## 4. State Management and Navigation
- Decision: Used Riverpod 2 (`StateNotifier`/`Notifier` & providers) and `go_router` with declarative routes.
- Rationale: High performance, zero context-leak bugs, easy mocking and dependency injection for offline/online transitions.

## 5. Offline-First Architecture & Degraded Supabase Fallback
- Decision: Every repository reads and writes to local storage (SharedPreferences / custom JSON store) first. A background `SyncQueue` buffers scores and progress changes, syncing to Supabase when online. If Supabase keys are absent or unreachable, the app operates smoothly in full offline mode without errors.

## 6. Procedural Audio Generation
- Decision: SFX and ambient loops are procedurally generated as standard 16-bit PCM WAV files with `tool/generate_sfx.py` and `tool/generate_sfx.dart`.
- Rationale: Eliminates missing asset risks and licensing issues while fulfilling the zero-third-party-sound requirement.

## 7. Responsive Glassmorphic Dark UI & Colorblind Patterns
- Decision: Dark theme default with deep dark tones (#0F121F), neon jewel-tone prism block gradients, glassmorphism cards (backdrop filter / subtle borders), and distinct geometric pattern embossings on block faces for colorblind accessibility.
