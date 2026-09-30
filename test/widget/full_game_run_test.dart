import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blockpuzzle_game/core/board/board_point.dart';
import 'package:blockpuzzle_game/core/engine/game_engine.dart';
import 'package:blockpuzzle_game/core/models/game_mode.dart';
import 'package:blockpuzzle_game/data/repositories/player_repository.dart';
import 'package:blockpuzzle_game/services/storage/storage_service.dart';
import 'package:blockpuzzle_game/services/supabase/supabase_service.dart';
import 'package:blockpuzzle_game/services/sync/sync_service.dart';

void main() {
  test(
    'Full game run integration: engine play, score, game over, and persistence',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SharedPreferencesStorageService(prefs);
      final supabase = AppSupabaseService();
      final syncService = SyncService(storage, supabase);
      final repo = PlayerRepository(storage, supabase, syncService);
      await repo.init();

      // Start engine
      final engine = GameEngine(mode: GameMode.classic, seed: 777);
      expect(engine.state.score, equals(0));

      // Place a piece
      final shape = engine.state.tray[0]!;
      final placed = engine.placePiece(
        trayIndex: 0,
        origin: const BoardPoint(0, 0),
      );
      expect(placed, isTrue);
      expect(engine.state.score, equals(shape.cellCount));

      // End run and record with score and lines cleared
      await repo.recordGameResult(
        mode: 'classic',
        score: 50,
        lines: 1,
        combo: 1,
      );

      // Verify progress updated
      expect(repo.current.totalGames, equals(1));
      expect(repo.current.bestClassicScore, equals(50));
      expect(
        repo.current.coins,
        equals(107),
      ); // Started with 100 + 7 coins earned
    },
  );
}
