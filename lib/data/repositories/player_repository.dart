import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../services/storage/storage_service.dart';
import '../../services/supabase/supabase_service.dart';
import '../../services/sync/sync_service.dart';
import '../models/player_progress.dart';

class PlayerRepository {
  final StorageService _storage;
  final SupabaseService _supabase;
  final SyncService _syncService;

  static const String _progressKey = 'player_progress_v1';
  PlayerProgress _current = const PlayerProgress();

  PlayerRepository(this._storage, this._supabase, this._syncService) {
    _loadInitial();
  }

  PlayerProgress get current => _current;

  void _loadInitial() {
    final raw = _storage.getString(_progressKey);
    if (raw != null) {
      try {
        _current = PlayerProgress.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (e) {
        debugPrint('[PlayerRepository] Parse error: $e');
      }
    }
  }

  Future<void> init() async {
    _loadInitial();
    if (_storage.getString(_progressKey) == null) {
      await save(_current);
    }
  }

  Future<void> save(PlayerProgress updated) async {
    _current = updated;
    await _storage.setString(_progressKey, jsonEncode(_current.toJson()));

    // Queue cloud sync
    if (_supabase.isAvailable) {
      await _syncService.enqueue('progress', {
        'coins': _current.coins,
        'gems': _current.gems,
        'best_classic_score': _current.bestClassicScore,
        'streak_count': _current.streakCount,
        'total_games': _current.totalGames,
        'total_lines': _current.totalLines,
        'best_combo': _current.bestCombo,
        'selected_theme': _current.selectedTheme,
        'has_remove_ads': _current.hasRemoveAds,
      });
    }
  }

  Future<void> addCoins(int amount) async {
    await save(_current.copyWith(coins: _current.coins + amount));
  }

  Future<bool> spendCoins(int amount) async {
    if (_current.coins < amount) return false;
    await save(_current.copyWith(coins: _current.coins - amount));
    return true;
  }

  Future<void> addGems(int amount) async {
    await save(_current.copyWith(gems: _current.gems + amount));
  }

  Future<bool> spendGems(int amount) async {
    if (_current.gems < amount) return false;
    await save(_current.copyWith(gems: _current.gems - amount));
    return true;
  }

  Future<void> recordGameResult({
    required String mode,
    required int score,
    required int lines,
    required int combo,
  }) async {
    int newBest = _current.bestClassicScore;
    if (mode == 'classic' && score > newBest) {
      newBest = score;
    }

    final coinsEarned = (score / 10).floor() + (lines * 2);

    await save(
      _current.copyWith(
        coins: _current.coins + coinsEarned,
        totalGames: _current.totalGames + 1,
        totalLines: _current.totalLines + lines,
        bestCombo: combo > _current.bestCombo ? combo : _current.bestCombo,
        bestClassicScore: newBest,
      ),
    );

    // Queue score submission
    if (_supabase.isAvailable) {
      await _syncService.enqueue('score', {
        'mode': mode,
        'score': score,
        'lines': lines,
        'best_combo': combo,
      });
    }
  }
}
