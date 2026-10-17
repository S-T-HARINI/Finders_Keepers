import 'package:finders_keepers/core/models/item_model.dart';
import 'package:finders_keepers/features/auth/data/auth_repository.dart';
import 'package:finders_keepers/features/auth/data/user_model.dart';
import 'package:finders_keepers/features/claims/data/claim_model.dart';
import 'package:finders_keepers/features/claims/data/claim_repository.dart';
import 'package:finders_keepers/features/items/data/item_repository.dart';
import 'package:finders_keepers/features/items/presentation/item_detail_screen.dart';
import 'package:finders_keepers/features/items/presentation/report_item_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 2 — Auth Repository & UserModel', () {
    test('UserModel guest factory sets anonymous role and ID', () {
      final guest = UserModel.guest();
      expect(guest.isAnonymous, isTrue);
      expect(guest.id, 'guest_user');
      expect(guest.role, UserRole.student);
    });

    test('UserModel Firestore serialization roundtrip', () {
      final now = DateTime.now();
      final user = UserModel(
        id: 'user_123',
        email: 'alex@campus.edu',
        displayName: 'Alex Rivers',
        campusId: 'STU-9921',
        createdAt: now,
        role: UserRole.admin,
      );

      final map = user.toFirestore();
      final reconstituted = UserModel.fromFirestore(map);

      expect(reconstituted.id, user.id);
      expect(reconstituted.email, user.email);
      expect(reconstituted.displayName, user.displayName);
      expect(reconstituted.campusId, user.campusId);
      expect(reconstituted.role, UserRole.admin);
    });

    test('MockAuthRepository sign in and sign out', () async {
      final authRepo = MockAuthRepository();

      final user = await authRepo.signInWithEmailAndPassword('maya@campus.edu', 'secret123');
      expect(user.email, 'maya@campus.edu');
      expect(authRepo.currentUser, isNotNull);

      await authRepo.signOut();
      expect(authRepo.currentUser, isNull);
    });
  });

  group('Phase 2 — Item Repository & Filters', () {
    test('MockItemRepository filters by item type', () async {
      final repo = MockItemRepository();

      final lostItems = await repo.getItems(type: ItemType.lost);
      expect(lostItems.every((item) => item.type == ItemType.lost), isTrue);

      final foundItems = await repo.getItems(type: ItemType.found);
      expect(foundItems.every((item) => item.type == ItemType.found), isTrue);
    });

    test('MockItemRepository creates and retrieves new item', () async {
      final repo = MockItemRepository();
      final newItem = ItemModel(
        id: 'test_item_99',
        title: 'Blue Hydroflask',
        description: 'Contains stickers on side',
        category: 'Accessories',
        type: ItemType.lost,
        status: ItemStatus.active,
        locationLabel: 'Sports Complex',
        lat: 12.972,
        lng: 77.595,
        reportedByUid: 'guest_user',
        reportedAt: DateTime.now(),
      );

      final id = await repo.createItem(newItem);
      expect(id, 'test_item_99');

      final fetched = await repo.getItemById('test_item_99');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Blue Hydroflask');
    });

    test('MockItemRepository filters by query', () async {
      final repo = MockItemRepository();
      final results = await repo.getItems(query: 'Charger');
      expect(results.any((i) => i.title.contains('Charger')), isTrue);
    });
  });

  group('Phase 2 — Claims Repository & Verification', () {
    test('MockClaimRepository submits and updates claim status', () async {
      final repo = MockClaimRepository();
      final claim = ClaimModel(
        id: 'claim_1',
        itemId: 'item_1',
        itemTitle: 'Sony WH-1000XM4 Headphones',
        claimantUid: 'student_1',
        claimantName: 'Rohan Sharma',
        claimantEmail: 'rohan@campus.edu',
        verificationEvidence: 'Serial number ends in 4821 and left cup has scratch',
        createdAt: DateTime.now(),
      );

      final claimId = await repo.submitClaim(claim);
      expect(claimId, 'claim_1');

      final userClaims = await repo.getClaimsByUser('student_1');
      expect(userClaims.length, 1);
      expect(userClaims.first.status, ClaimStatus.pending);

      await repo.updateClaimStatus('claim_1', ClaimStatus.approved, notes: 'Matches serial number');
      final updatedClaims = await repo.getClaimsByUser('student_1');
      expect(updatedClaims.first.status, ClaimStatus.approved);
      expect(updatedClaims.first.reviewNotes, 'Matches serial number');
    });
  });

  group('Phase 2 — Report & Detail Screen Widget Tests', () {
    testWidgets('ReportItemScreen renders type switcher and fields', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ReportItemScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Report an Item'), findsOneWidget);
      expect(find.text('I Lost Something'), findsOneWidget);
      expect(find.text('I Found Something'), findsOneWidget);
      expect(find.text('Item Name *'), findsOneWidget);
      expect(find.text('Mask Sensitive Details'), findsOneWidget);
      expect(find.text('Submit Lost Item Report'), findsOneWidget);
    });

    testWidgets('ItemDetailScreen renders item information and claim button for found item', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final foundItem = ItemModel(
        id: 'found_umbrella_101',
        title: 'Black Knirps Umbrella',
        description: 'Found near cafeteria bench',
        category: 'Accessories',
        type: ItemType.found,
        status: ItemStatus.active,
        locationLabel: 'Main Cafeteria',
        lat: 12.9716,
        lng: 77.5946,
        reportedByUid: 'other_user',
        reportedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemByIdProvider('found_umbrella_101').overrideWith((ref) async => foundItem),
          ],
          child: const MaterialApp(
            home: ItemDetailScreen(itemId: 'found_umbrella_101'),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Black Knirps Umbrella'), findsOneWidget);
      expect(find.text('Main Cafeteria'), findsOneWidget);
      expect(find.text('Claim This Item'), findsOneWidget);
    });
  });
}
