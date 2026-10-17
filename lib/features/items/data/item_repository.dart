import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/item_model.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/local_cache_service.dart';
import 'firestore_item_repository.dart';

abstract class ItemRepository {
  Stream<List<ItemModel>> watchItems({ItemType? type, String? category, String? query});
  Future<List<ItemModel>> getItems({ItemType? type, String? category, String? query});
  Future<ItemModel?> getItemById(String id);
  Future<String> createItem(ItemModel item);
  Future<void> updateItem(ItemModel item);
  Future<void> deleteItem(String id);
  Future<List<ItemModel>> getItemsByUser(String uid);
  Future<List<ItemModel>> getClaimedItemsByUser(String uid);
}

/// Reactive persistent implementation seeded with initial campus data
/// and durable local storage to survive process death and app restarts.
class MockItemRepository implements ItemRepository {
  MockItemRepository({LocalCacheService? cacheService}) : _cacheService = cacheService {
    _items.addAll(MockItems.all);
    _initFromCache();
  }

  final LocalCacheService? _cacheService;
  final List<ItemModel> _items = [];
  final _controller = StreamController<List<ItemModel>>.broadcast();

  Future<void> _initFromCache() async {
    if (_cacheService != null) {
      final cached = await _cacheService.loadItems();
      if (cached.isNotEmpty) {
        // Merge cached items, preserving newly added reports while keeping base mocks
        final Map<String, ItemModel> itemMap = {
          for (final item in MockItems.all) item.id: item,
        };
        for (final item in cached) {
          itemMap[item.id] = item;
        }
        _items.clear();
        _items.addAll(itemMap.values);
      }
    }
    _broadcast();
  }

  void _broadcast() {
    _controller.add(List.unmodifiable(_items));
    _cacheService?.saveItems(_items);
  }

  @override
  Stream<List<ItemModel>> watchItems({ItemType? type, String? category, String? query}) async* {
    yield _filterList(_items, type, category, query);
    yield* _controller.stream.map((list) => _filterList(list, type, category, query));
  }

  @override
  Future<List<ItemModel>> getItems({ItemType? type, String? category, String? query}) async {
    return _filterList(_items, type, category, query);
  }

  @override
  Future<ItemModel?> getItemById(String id) async {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> createItem(ItemModel item) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final String newItemId = item.id.isNotEmpty ? item.id : 'item_${DateTime.now().millisecondsSinceEpoch}';
    final savedItem = item.copyWith(id: newItemId);
    _items.insert(0, savedItem);
    _broadcast();
    return newItemId;
  }

  @override
  Future<void> updateItem(ItemModel item) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      _broadcast();
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _items.removeWhere((i) => i.id == id);
    _broadcast();
  }

  @override
  Future<List<ItemModel>> getItemsByUser(String uid) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _items.where((i) => i.reportedByUid == uid).toList();
  }

  @override
  Future<List<ItemModel>> getClaimedItemsByUser(String uid) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _items.where((i) => i.claimedByUid == uid).toList();
  }

  List<ItemModel> _filterList(List<ItemModel> list, ItemType? type, String? category, String? query) {
    var result = List<ItemModel>.from(list);
    if (type != null) {
      result = result.where((item) => item.type == type).toList();
    }
    if (category != null && category.isNotEmpty && category != 'All') {
      result = result.where((item) => item.category.toLowerCase() == category.toLowerCase()).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      result = result.where((item) {
        return item.title.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q) ||
            item.locationLabel.toLowerCase().contains(q);
      }).toList();
    }
    result.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    return result;
  }

  void dispose() {
    _controller.close();
  }
}

/// Provider for ItemRepository with automatic dual-mode resolution
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  if (FirebaseService.isFirebaseInitialized) {
    return FirestoreItemRepository();
  }
  final cache = ref.watch(localCacheServiceProvider);
  final repo = MockItemRepository(cacheService: cache);
  ref.onDispose(repo.dispose);
  return repo;
});

/// Stream provider for all items with search query and type filters
final filteredItemsStreamProvider = StreamProvider.autoDispose.family<List<ItemModel>, ({ItemType? type, String? category, String? query})>((ref, filter) {
  final repo = ref.watch(itemRepositoryProvider);
  return repo.watchItems(type: filter.type, category: filter.category, query: filter.query);
});

/// Future provider for fetching a single item by id
final itemByIdProvider = FutureProvider.autoDispose.family<ItemModel?, String>((ref, id) {
  final repo = ref.watch(itemRepositoryProvider);
  return repo.getItemById(id);
});
