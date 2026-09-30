# Prism Blocks - System Architecture

## Overview
Prism Blocks is a high-performance, single-player block puzzle mobile game developed in Flutter with Flame engine integration, Riverpod state management, offline-first local storage, and Supabase cloud sync.

```
+-------------------------------------------------------------+
|                      Flutter UI Layer                       |
|   (Features: Home, Play, Daily, Shop, Leaderboard, etc.)    |
|                      Glassmorphism Theme                    |
+------------------------------+------------------------------+
                               |
                               v
+-------------------------------------------------------------+
|                     Flame Engine Layer                      |
| (PrismFlameGame, BoardComponent, TrayComponent, Particles)  |
+------------------------------+------------------------------+
                               |
                               v
+-------------------------------------------------------------+
|                     Pure Dart Core Engine                   |
|     (GameEngine, Board, Pieces, FairGenerator, Scoring)     |
|              * ZERO Flutter or Flame Imports *              |
+-------------------------------------------------------------+
                               |
                               v
+-------------------------------------------------------------+
|                   Services & Repositories                   |
|   (Audio, Haptics, Storage, SupabaseSync, Ads, IAP, Consent)|
+-------------------------------------------------------------+
```

## Key Layers
1. **`lib/core/`**: Mathematical logic, 8x8 matrix computations, piece shapes catalogue, scoring constants, seedable PRNG (Mulberry32), and deterministic game engine.
2. **`lib/game/`**: Flame components handling 60fps rendering, custom shaders/paints, particle bursts, screen shake, and drag-and-drop hit tests.
3. **`lib/features/`**: Feature-first Flutter widgets with glassmorphism design, animations, and Riverpod state controllers.
4. **`lib/services/`**: Pluggable interfaces for Ads, IAP, Audio, Haptics, Local Notifications, and Supabase client with offline queuing.
