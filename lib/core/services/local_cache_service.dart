import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/user_model.dart';
import '../../features/claims/data/claim_model.dart';
import '../models/item_model.dart';

/// Representation of an in-progress draft report to prevent work loss
/// across app interruptions, phone calls, or process termination.
class ReportDraft {
  const ReportDraft({
    required this.type,
    required this.category,
    required this.zone,
    required this.title,
    required this.description,
    required this.specificLocation,
    required this.reportedAt,
    this.imagePath,
    this.protectPrivacy = true,
  });

  final ItemType type;
  final String category;
  final String zone;
  final String title;
  final String description;
  final String specificLocation;
  final DateTime reportedAt;
  final String? imagePath;
  final bool protectPrivacy;

  bool get isEmpty =>
      title.trim().isEmpty &&
      description.trim().isEmpty &&
      specificLocation.trim().isEmpty &&
      imagePath == null;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'category': category,
        'zone': zone,
        'title': title,
        'description': description,
        'specificLocation': specificLocation,
        'reportedAt': reportedAt.toIso8601String(),
        'imagePath': imagePath,
        'protectPrivacy': protectPrivacy,
      };

  factory ReportDraft.fromJson(Map<String, dynamic> json) => ReportDraft(
        type: ItemType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => ItemType.lost,
        ),
        category: json['category'] as String? ?? 'Other',
        zone: json['zone'] as String? ?? 'Central Library',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        specificLocation: json['specificLocation'] as String? ?? '',
        reportedAt: json['reportedAt'] != null
            ? DateTime.parse(json['reportedAt'] as String)
            : DateTime.now(),
        imagePath: json['imagePath'] as String?,
        protectPrivacy: json['protectPrivacy'] as bool? ?? true,
      );
}

/// Durable local persistence service using SharedPreferences
/// to guarantee data survival across cold app restarts and offline sessions.
class LocalCacheService {
  LocalCacheService([SharedPreferences? prefs]) : _prefsInstance = prefs;

  SharedPreferences? _prefsInstance;

  static const String _kItemsKey = 'finders_keepers_persisted_items';
  static const String _kClaimsKey = 'finders_keepers_persisted_claims';
  static const String _kCurrentUserKey = 'finders_keepers_current_user';
  static const String _kDraftKey = 'finders_keepers_report_draft';
  static const String _kSyncQueueKey = 'finders_keepers_sync_queue';

  Future<SharedPreferences> _getPrefs() async {
    _prefsInstance ??= await SharedPreferences.getInstance();
    return _prefsInstance!;
  }

  // ── Items Persistence ──────────────────────────────────────────────────────

  Future<List<ItemModel>> loadItems() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_kItemsKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ItemModel.fromFirestore(e as Map<String, dynamic>, e['id'] as String? ?? ''))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveItems(List<ItemModel> items) async {
    try {
      final prefs = await _getPrefs();
      final data = items.map((item) {
        final map = item.toFirestore();
        map['id'] = item.id;
        return map;
      }).toList();
      await prefs.setString(_kItemsKey, jsonEncode(data));
    } catch (_) {}
  }

  // ── Claims Persistence ─────────────────────────────────────────────────────

  Future<List<ClaimModel>> loadClaims() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_kClaimsKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ClaimModel.fromFirestore(e as Map<String, dynamic>, e['id'] as String? ?? ''))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveClaims(List<ClaimModel> claims) async {
    try {
      final prefs = await _getPrefs();
      final data = claims.map((c) => c.toFirestore()).toList();
      await prefs.setString(_kClaimsKey, jsonEncode(data));
    } catch (_) {}
  }

  // ── User Session Persistence ───────────────────────────────────────────────

  Future<UserModel?> loadCurrentUser() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_kCurrentUserKey);
      if (raw == null || raw.isEmpty) return null;
      final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromFirestore(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCurrentUser(UserModel? user) async {
    try {
      final prefs = await _getPrefs();
      if (user == null) {
        await prefs.remove(_kCurrentUserKey);
      } else {
        await prefs.setString(_kCurrentUserKey, jsonEncode(user.toFirestore()));
      }
    } catch (_) {}
  }

  // ── Report Draft Persistence ───────────────────────────────────────────────

  Future<ReportDraft?> loadDraft() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_kDraftKey);
      if (raw == null || raw.isEmpty) return null;
      final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
      return ReportDraft.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDraft(ReportDraft draft) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_kDraftKey, jsonEncode(draft.toJson()));
    } catch (_) {}
  }

  Future<void> clearDraft() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_kDraftKey);
    } catch (_) {}
  }

  // ── Sync Queue Persistence ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> loadSyncQueue() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_kSyncQueueKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSyncQueue(List<Map<String, dynamic>> queue) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_kSyncQueueKey, jsonEncode(queue));
    } catch (_) {}
  }
}

/// Riverpod provider for LocalCacheService
final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService();
});
