import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../storage/storage_service.dart';
import '../supabase/supabase_service.dart';

class SyncItem {
  final String id;
  final String type; // 'score', 'progress', 'purchase'
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;

  SyncItem({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
  };

  factory SyncItem.fromJson(Map<String, dynamic> json) => SyncItem(
    id: json['id'] as String,
    type: json['type'] as String,
    data: Map<String, dynamic>.from(json['data'] as Map),
    createdAt: DateTime.parse(json['createdAt'] as String),
    retryCount: json['retryCount'] as int? ?? 0,
  );
}

class SyncService {
  final StorageService _storage;
  final SupabaseService _supabase;
  static const String _queueKey = 'sync_queue_items';
  final List<SyncItem> _queue = [];
  bool _isSyncing = false;

  SyncService(this._storage, this._supabase);

  Future<void> init() async {
    final list = _storage.getStringList(_queueKey);
    if (list != null) {
      _queue.clear();
      for (final raw in list) {
        try {
          _queue.add(
            SyncItem.fromJson(jsonDecode(raw) as Map<String, dynamic>),
          );
        } catch (_) {}
      }
    }
  }

  Future<void> enqueue(String type, Map<String, dynamic> data) async {
    final item = SyncItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_queue.length}',
      type: type,
      data: data,
      createdAt: DateTime.now(),
    );
    _queue.add(item);
    await _persist();
    unawaited(processQueue());
  }

  Future<void> _persist() async {
    final list = _queue.map((item) => jsonEncode(item.toJson())).toList();
    await _storage.setStringList(_queueKey, list);
  }

  Future<void> processQueue() async {
    if (_isSyncing || !_supabase.isAvailable || _queue.isEmpty) return;
    _isSyncing = true;

    try {
      final itemsToProcess = List<SyncItem>.from(_queue);
      for (final item in itemsToProcess) {
        bool success = false;
        try {
          if (item.type == 'score') {
            await _supabase.client?.rpc('submit_score', params: item.data);
            success = true;
          } else if (item.type == 'progress') {
            await _supabase.client?.rpc('sync_progress', params: item.data);
            success = true;
          } else if (item.type == 'daily_reward') {
            await _supabase.client?.rpc(
              'claim_daily_reward',
              params: item.data,
            );
            success = true;
          } else if (item.type == 'purchase') {
            await _supabase.client?.rpc('grant_purchase', params: item.data);
            success = true;
          } else {
            success = true;
          }
        } catch (e) {
          debugPrint('[SyncService] Failed item ${item.id}: $e');
          item.retryCount++;
          if (item.retryCount > 5) {
            // Drop after max retries
            success = true;
          }
        }

        if (success) {
          _queue.removeWhere((i) => i.id == item.id);
          await _persist();
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
