import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/constants/app_env.dart';

abstract class SupabaseService {
  Future<void> init();
  bool get isAvailable;
  SupabaseClient? get client;
  String? get currentUserId;
  Future<bool> signInAnonymously();
  Future<bool> linkEmail(String email, String password);
  Future<void> signOut();
}

class AppSupabaseService implements SupabaseService {
  bool _initialized = false;

  @override
  bool get isAvailable => _initialized && AppEnv.isConfigured;

  @override
  SupabaseClient? get client {
    if (!isAvailable) return null;
    return Supabase.instance.client;
  }

  @override
  String? get currentUserId {
    return client?.auth.currentUser?.id;
  }

  @override
  Future<void> init() async {
    if (!AppEnv.isConfigured) {
      debugPrint('[SupabaseService] Not configured; using offline mode.');
      return;
    }
    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: AppEnv.supabaseAnonKey,
      );
      _initialized = true;
      debugPrint('[SupabaseService] Initialized successfully.');
    } catch (e) {
      debugPrint('[SupabaseService] Init failed: $e');
      _initialized = false;
    }
  }

  @override
  Future<bool> signInAnonymously() async {
    if (!isAvailable) return false;
    try {
      final response = await client?.auth.signInAnonymously();
      return response?.user != null;
    } catch (e) {
      debugPrint('[SupabaseService] Anon sign in failed: $e');
      return false;
    }
  }

  @override
  Future<bool> linkEmail(String email, String password) async {
    if (!isAvailable) return false;
    try {
      final res = await client?.auth.updateUser(
        UserAttributes(email: email, password: password),
      );
      return res?.user != null;
    } catch (e) {
      debugPrint('[SupabaseService] Link email failed: $e');
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    if (!isAvailable) return;
    try {
      await client?.auth.signOut();
    } catch (_) {}
  }
}
