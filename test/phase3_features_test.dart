import 'package:finders_keepers/core/models/item_model.dart';
import 'package:finders_keepers/core/services/local_cache_service.dart';
import 'package:finders_keepers/core/services/notification_service.dart';
import 'package:finders_keepers/core/services/similarity_service.dart';
import 'package:finders_keepers/core/services/sync_queue_service.dart';
import 'package:finders_keepers/features/claims/data/claim_model.dart';
import 'package:finders_keepers/features/claims/data/claim_repository.dart';
import 'package:finders_keepers/features/items/data/item_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 3 — Local Storage & Persistence Service', () {
    test('Saves and restores items across cache instances', () async {
      final cache1 = LocalCacheService();
      final testItem = ItemModel(
        id: 'test_persist_1',
        title: 'Blue Water Bottle',
        description: 'Hydro flask left at study pod',
        type: ItemType.lost,
        status: ItemStatus.active,
        category: 'Accessories',
        locationLabel: 'Central Library',
        reportedAt: DateTime(2026, 10, 17, 10, 30),
      );

      await cache1.saveItems([testItem]);

      // Create new cache instance (simulating app restart)
      final cache2 = LocalCacheService();
      final loaded = await cache2.loadItems();

      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals('test_persist_1'));
      expect(loaded.first.title, equals('Blue Water Bottle'));
      expect(loaded.first.locationLabel, equals('Central Library'));
    });

    test('Saves, loads, and clears draft reports to prevent data loss', () async {
      final cache = LocalCacheService();

      final draft = ReportDraft(
        type: ItemType.lost,
        category: 'Electronics',
        zone: 'Engineering Quad',
        title: 'Silver ThinkPad',
        description: 'Left on bench outside lab',
        specificLocation: 'Bench near entrance',
        reportedAt: DateTime(2026, 10, 17, 11),
      );

      expect(draft.isEmpty, isFalse);
      await cache.saveDraft(draft);

      final loadedDraft = await cache.loadDraft();
      expect(loadedDraft, isNotNull);
      expect(loadedDraft!.title, equals('Silver ThinkPad'));
      expect(loadedDraft.category, equals('Electronics'));
      expect(loadedDraft.specificLocation, equals('Bench near entrance'));

      await cache.clearDraft();
      final clearedDraft = await cache.loadDraft();
      expect(clearedDraft, isNull);
    });
  });

  group('Phase 3 — Offline Sync Queue & Backoff Engine', () {
    test('Enqueues operations with idempotency keys and prevents duplicates', () async {
      final cache = LocalCacheService();
      final syncQueue = SyncQueueService(cacheService: cache);

      await syncQueue.enqueue(
        idempotencyKey: 'op_report_101',
        actionType: 'create_item',
        payload: {'id': 'item_101', 'title': 'Keys'},
      );

      expect(syncQueue.currentQueue.length, equals(1));
      expect(syncQueue.currentQueue.first.status, equals(SyncStatus.pending));

      // Re-enqueuing with the same idempotency key should not create duplicates
      await syncQueue.enqueue(
        idempotencyKey: 'op_report_101',
        actionType: 'create_item',
        payload: {'id': 'item_101', 'title': 'Keys updated'},
      );
      expect(syncQueue.currentQueue.length, equals(1));

      // Mark synced
      await syncQueue.markSynced('op_report_101');
      expect(syncQueue.currentQueue.first.status, equals(SyncStatus.synced));
    });

    test('Computes bounded exponential backoff for failed sync retries', () async {
      final cache = LocalCacheService();
      final syncQueue = SyncQueueService(cacheService: cache);

      await syncQueue.enqueue(
        idempotencyKey: 'op_claim_55',
        actionType: 'submit_claim',
        payload: {'claimId': '55'},
      );

      await syncQueue.markFailed('op_claim_55', 'Network unreachable');

      final op = syncQueue.currentQueue.first;
      expect(op.status, equals(SyncStatus.failed));
      expect(op.retryCount, equals(1));
      expect(op.errorMessage, equals('Network unreachable'));
      expect(op.nextBackoff.inSeconds, equals(4)); // 2 * (1 << 1) = 4s
    });
  });

  group('Phase 3 — Multi-Factor Similarity & Matching Engine', () {
    test('Tokenizes keywords and removes campus stop words', () {
      const text = 'I found a lost black AirPods Pro case near the campus library!';
      final tokens = SimilarityService.tokenize(text);

      expect(tokens.contains('airpods'), isTrue);
      expect(tokens.contains('pro'), isTrue);
      expect(tokens.contains('black'), isTrue);
      // Stop words removed
      expect(tokens.contains('the'), isFalse);
      expect(tokens.contains('a'), isFalse);
      expect(tokens.contains('near'), isFalse);
    });

    test('Correctly computes high similarity for matching items', () {
      final lostItem = ItemModel(
        id: 'lost_1',
        title: 'AirPods Pro Case',
        description: 'White wireless charging case with red carabiner',
        type: ItemType.lost,
        status: ItemStatus.active,
        category: 'Electronics',
        locationLabel: 'Central Library',
        reportedAt: DateTime(2026, 10, 17, 12),
        lat: 37.4275,
        lng: -122.1697,
      );

      final foundItem = ItemModel(
        id: 'found_1',
        title: 'Found Apple AirPods Case',
        description: 'White case with a red carabiner clip',
        type: ItemType.found,
        status: ItemStatus.active,
        category: 'Electronics',
        locationLabel: 'Central Library',
        reportedAt: DateTime(2026, 10, 17, 13),
        lat: 37.4276,
        lng: -122.1698,
      );

      final match = SimilarityService.evaluate(lostItem, foundItem);

      expect(match.categoryMatch, isTrue);
      expect(match.percentage, greaterThanOrEqualTo(70));
      expect(match.explanation, contains('Same category'));
      expect(match.explanation, contains('Keywords match'));
      expect(match.explanation, contains('Nearby location'));
    });

    test('Finds opposite-type matches using SimilarityService.findMatches', () {
      final lostItem = ItemModel(
        id: 'lost_10',
        title: 'Hydro Flask Blue',
        description: 'Wide mouth 32oz bottle with stickers',
        type: ItemType.lost,
        status: ItemStatus.active,
        category: 'Accessories',
        locationLabel: 'Engineering Quad',
        reportedAt: DateTime.now(),
      );

      final matchingFoundItem = ItemModel(
        id: 'found_10',
        title: 'Blue Hydro Flask Bottle',
        description: 'Water bottle with sticker labels',
        type: ItemType.found,
        status: ItemStatus.active,
        category: 'Accessories',
        locationLabel: 'Engineering Quad',
        reportedAt: DateTime.now(),
      );

      final nonMatchingFoundItem = ItemModel(
        id: 'found_20',
        title: 'Calculus Textbook',
        description: 'Stewart calculus 8th edition',
        type: ItemType.found,
        status: ItemStatus.active,
        category: 'Books',
        locationLabel: 'Student Center',
        reportedAt: DateTime.now(),
      );

      final service = SimilarityService();
      final results = service.findMatches(
        target: lostItem,
        allItems: [lostItem, matchingFoundItem, nonMatchingFoundItem],
        minThreshold: 0.35,
      );

      expect(results.length, equals(1));
      expect(results.first.item.id, equals('found_10'));
      expect(results.first.percentage, greaterThan(60));
    });
  });

  group('Phase 3 — Item Lifecycle State Machine & Claim Handover', () {
    test('Transitions item cleanly from active to claimed to returned', () async {
      final cache = LocalCacheService();
      final itemRepo = MockItemRepository(cacheService: cache);
      final claimRepo = MockClaimRepository(cacheService: cache);

      // 1. Create active item
      final itemId = await itemRepo.createItem(
        ItemModel(
          id: 'item_lifecycle_1',
          title: 'Graphing Calculator TI-84',
          description: 'Left in Math Hall',
          type: ItemType.found,
          status: ItemStatus.active,
          category: 'Electronics',
          locationLabel: 'Science Complex',
          reportedAt: DateTime.now(),
          reportedByUid: 'finder_uid_1',
        ),
      );

      var item = await itemRepo.getItemById(itemId);
      expect(item!.status, equals(ItemStatus.active));

      // 2. Submit claim -> status transitions to claimed
      final claimId = await claimRepo.submitClaim(
        ClaimModel(
          id: 'claim_lifecycle_1',
          itemId: itemId,
          itemTitle: 'Graphing Calculator TI-84',
          claimantUid: 'claimant_uid_2',
          claimantName: 'Jordan Lee',
          claimantEmail: 'jordan@campus.edu',
          verificationEvidence: 'Serial ending in 9812 with initials JL on battery cover',
          createdAt: DateTime.now(),
        ),
      );

      await itemRepo.updateItem(item.copyWith(
        status: ItemStatus.claimed,
        claimedByUid: 'claimant_uid_2',
      ));

      item = await itemRepo.getItemById(itemId);
      expect(item!.status, equals(ItemStatus.claimed));
      expect(item.claimedByUid, equals('claimant_uid_2'));

      // 3. Finder approves claim -> atomic handover to returned
      await claimRepo.updateClaimStatus(claimId, ClaimStatus.approved, notes: 'Verified battery cover initials.');
      await itemRepo.updateItem(item.copyWith(status: ItemStatus.returned));

      item = await itemRepo.getItemById(itemId);
      expect(item!.status, equals(ItemStatus.returned));

      final claims = await claimRepo.getClaimsForItem(itemId);
      expect(claims.first.status, equals(ClaimStatus.approved));
    });
  });

  group('Phase 3 — In-App Notifications & Alerts', () {
    test('Dispatches match alert and claim status alerts', () async {
      final notifService = NotificationService();

      await notifService.sendMatchAlert(
        itemId: 'item_99',
        itemTitle: 'Leather Wallet',
        matchPercentage: 88,
      );

      await notifService.sendClaimStatusAlert(
        claimId: 'clm_12',
        itemTitle: 'Keys',
        status: 'Approved',
      );

      final notifs = notifService.currentNotifications;
      expect(notifs.length, greaterThanOrEqualTo(3)); // Initial welcome + 2 alerts
      expect(notifs.any((n) => n.title.contains('88%')), isTrue);
      expect(notifs.any((n) => n.title.contains('Claim Update: Approved')), isTrue);

      // Mark all read
      notifService.markAllAsRead();
      expect(notifService.currentNotifications.every((n) => n.isRead), isTrue);
    });
  });
}
