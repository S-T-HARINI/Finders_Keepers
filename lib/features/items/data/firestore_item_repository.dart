import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/item_model.dart';
import 'item_repository.dart';

/// Production-ready Cloud Firestore implementation of ItemRepository.
class FirestoreItemRepository implements ItemRepository {
  FirestoreItemRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      _firestore.collection('items');

  @override
  Stream<List<ItemModel>> watchItems({
    ItemType? type,
    String? category,
    String? query,
  }) {
    Query<Map<String, dynamic>> q = _itemsRef.orderBy('reportedAt', descending: true);

    if (type != null) {
      q = q.where('type', isEqualTo: type.name);
    }
    if (category != null && category.isNotEmpty && category != 'All') {
      q = q.where('category', isEqualTo: category);
    }

    return q.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc.data(), doc.id))
          .toList();

      if (query != null && query.trim().isNotEmpty) {
        final lower = query.toLowerCase().trim();
        return list.where((item) {
          return item.title.toLowerCase().contains(lower) ||
              item.description.toLowerCase().contains(lower) ||
              item.locationLabel.toLowerCase().contains(lower);
        }).toList();
      }

      return list;
    });
  }

  @override
  Future<List<ItemModel>> getItems({
    ItemType? type,
    String? category,
    String? query,
  }) async {
    Query<Map<String, dynamic>> q = _itemsRef.orderBy('reportedAt', descending: true);

    if (type != null) {
      q = q.where('type', isEqualTo: type.name);
    }
    if (category != null && category.isNotEmpty && category != 'All') {
      q = q.where('category', isEqualTo: category);
    }

    final snapshot = await q.get();
    final list = snapshot.docs
        .map((doc) => ItemModel.fromFirestore(doc.data(), doc.id))
        .toList();

    if (query != null && query.trim().isNotEmpty) {
      final lower = query.toLowerCase().trim();
      return list.where((item) {
        return item.title.toLowerCase().contains(lower) ||
            item.description.toLowerCase().contains(lower) ||
            item.locationLabel.toLowerCase().contains(lower);
      }).toList();
    }

    return list;
  }

  @override
  Future<ItemModel?> getItemById(String id) async {
    final doc = await _itemsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ItemModel.fromFirestore(doc.data()!, doc.id);
  }

  @override
  Future<String> createItem(ItemModel item) async {
    final docRef = item.id.isNotEmpty ? _itemsRef.doc(item.id) : _itemsRef.doc();
    await docRef.set(item.toFirestore());
    return docRef.id;
  }

  @override
  Future<void> updateItem(ItemModel item) async {
    await _itemsRef.doc(item.id).update(item.toFirestore());
  }

  @override
  Future<void> deleteItem(String id) async {
    await _itemsRef.doc(id).delete();
  }

  @override
  Future<List<ItemModel>> getItemsByUser(String uid) async {
    final snapshot = await _itemsRef
        .where('reportedByUid', isEqualTo: uid)
        .orderBy('reportedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ItemModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<List<ItemModel>> getClaimedItemsByUser(String uid) async {
    final snapshot = await _itemsRef
        .where('claimedByUid', isEqualTo: uid)
        .orderBy('reportedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ItemModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }
}
