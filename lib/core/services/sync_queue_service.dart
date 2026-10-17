import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_cache_service.dart';

enum SyncStatus { pending, synced, failed }

class SyncOperation {
  const SyncOperation({
    required this.idempotencyKey,
    required this.actionType,
    required this.payload,
    required this.createdAt,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    this.lastAttemptAt,
    this.errorMessage,
  });

  final String idempotencyKey;
  final String actionType; // e.g. 'create_item', 'submit_claim', 'update_item_status'
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final SyncStatus status;
  final int retryCount;
  final DateTime? lastAttemptAt;
  final String? errorMessage;

  SyncOperation copyWith({
    String? idempotencyKey,
    String? actionType,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    SyncStatus? status,
    int? retryCount,
    DateTime? lastAttemptAt,
    String? errorMessage,
  }) {
    return SyncOperation(
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      actionType: actionType ?? this.actionType,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'idempotencyKey': idempotencyKey,
        'actionType': actionType,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'retryCount': retryCount,
        'lastAttemptAt': lastAttemptAt?.toIso8601String(),
        'errorMessage': errorMessage,
      };

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
        idempotencyKey: json['idempotencyKey'] as String,
        actionType: json['actionType'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: SyncStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => SyncStatus.pending,
        ),
        retryCount: json['retryCount'] as int? ?? 0,
        lastAttemptAt: json['lastAttemptAt'] != null
            ? DateTime.tryParse(json['lastAttemptAt'] as String)
            : null,
        errorMessage: json['errorMessage'] as String?,
      );

  Duration get nextBackoff {
    final exp = min(retryCount, 6);
    return Duration(seconds: 2 * (1 << exp));
  }
}

class SyncQueueService {
  SyncQueueService({required LocalCacheService cacheService})
      : _cacheService = cacheService {
    _initFuture = _init();
  }

  final LocalCacheService _cacheService;
  late final Future<void> _initFuture;
  final List<SyncOperation> _queue = [];
  final _controller = StreamController<List<SyncOperation>>.broadcast();

  Stream<List<SyncOperation>> get queueStream => _controller.stream;
  List<SyncOperation> get currentQueue => List.unmodifiable(_queue);

  Future<void> _init() async {
    final loaded = await _cacheService.loadSyncQueue();
    for (final item in loaded) {
      try {
        final op = SyncOperation.fromJson(item);
        if (!_queue.any((existing) => existing.idempotencyKey == op.idempotencyKey)) {
          _queue.add(op);
        }
      } catch (_) {}
    }
    _controller.add(List.unmodifiable(_queue));
  }

  void _broadcast() {
    _controller.add(List.unmodifiable(_queue));
    _persist();
  }

  Future<void> _persist() async {
    await _cacheService.saveSyncQueue(_queue.map((op) => op.toJson()).toList());
  }

  Future<void> enqueue({
    required String idempotencyKey,
    required String actionType,
    required Map<String, dynamic> payload,
  }) async {
    await _initFuture;
    // Prevent duplicate operations with the same idempotency key
    final existingIndex = _queue.indexWhere((op) => op.idempotencyKey == idempotencyKey);
    if (existingIndex != -1) {
      final existing = _queue[existingIndex];
      if (existing.status == SyncStatus.synced) {
        return; // Already completed
      }
      // Re-enqueue as pending
      _queue[existingIndex] = existing.copyWith(
        status: SyncStatus.pending,
        payload: payload,
      );
    } else {
      _queue.add(
        SyncOperation(
          idempotencyKey: idempotencyKey,
          actionType: actionType,
          payload: payload,
          createdAt: DateTime.now(),
        ),
      );
    }
    _broadcast();
  }

  Future<void> markSynced(String idempotencyKey) async {
    await _initFuture;
    final index = _queue.indexWhere((op) => op.idempotencyKey == idempotencyKey);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        status: SyncStatus.synced,
        lastAttemptAt: DateTime.now(),
      );
      _broadcast();
    }
  }

  Future<void> markFailed(String idempotencyKey, String error) async {
    await _initFuture;
    final index = _queue.indexWhere((op) => op.idempotencyKey == idempotencyKey);
    if (index != -1) {
      final current = _queue[index];
      _queue[index] = current.copyWith(
        status: SyncStatus.failed,
        retryCount: current.retryCount + 1,
        lastAttemptAt: DateTime.now(),
        errorMessage: error,
      );
      _broadcast();
    }
  }

  List<SyncOperation> get pendingOperations =>
      _queue.where((op) => op.status == SyncStatus.pending).toList();

  void dispose() {
    _controller.close();
  }
}

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  final cache = ref.watch(localCacheServiceProvider);
  final service = SyncQueueService(cacheService: cache);
  ref.onDispose(service.dispose);
  return service;
});
