import 'package:equatable/equatable.dart';

/// Item type — whether the item is reported as lost or found
enum ItemType { lost, found }

/// Current status of an item in the system
enum ItemStatus {
  /// Reported but no match yet
  active,

  /// A claim has been submitted
  claimed,

  /// Item has been returned to owner
  returned,
}

/// Represents a lost or found item in the system.
///
/// In Phase 1 this is used for mock/display data only.
/// In Phase 2 this will be hydrated from Firestore.
class ItemModel extends Equatable {
  const ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.category,
    required this.locationLabel,
    required this.reportedAt,
    this.imageUrl,
    this.lat,
    this.lng,
    this.reportedByUid,
    this.claimedByUid,
  });

  final String id;
  final String title;
  final String description;
  final ItemType type;
  final ItemStatus status;
  final String category;

  /// Human-readable location label (e.g., "Near Library Block B")
  /// — never exact coordinates for privacy
  final String locationLabel;

  final DateTime reportedAt;

  /// Optional thumbnail URL (Firebase Storage or placeholder)
  final String? imageUrl;

  /// Approximate latitude — rounded to ~100m precision
  final double? lat;

  /// Approximate longitude — rounded to ~100m precision
  final double? lng;

  /// UID of the user who reported this item (Firebase Auth UID)
  final String? reportedByUid;

  /// UID of the user who claimed this item
  final String? claimedByUid;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        status,
        category,
        locationLabel,
        reportedAt,
        imageUrl,
        lat,
        lng,
        reportedByUid,
        claimedByUid,
      ];

  ItemModel copyWith({
    String? id,
    String? title,
    String? description,
    ItemType? type,
    ItemStatus? status,
    String? category,
    String? locationLabel,
    DateTime? reportedAt,
    String? imageUrl,
    double? lat,
    double? lng,
    String? reportedByUid,
    String? claimedByUid,
  }) {
    return ItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      category: category ?? this.category,
      locationLabel: locationLabel ?? this.locationLabel,
      reportedAt: reportedAt ?? this.reportedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      reportedByUid: reportedByUid ?? this.reportedByUid,
      claimedByUid: claimedByUid ?? this.claimedByUid,
    );
  }

  /// Serialize to Firestore document map — Phase 2
  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'type': type.name,
        'status': status.name,
        'category': category,
        'locationLabel': locationLabel,
        'reportedAt': reportedAt.toIso8601String(),
        'imageUrl': imageUrl,
        'lat': lat,
        'lng': lng,
        'reportedByUid': reportedByUid,
        'claimedByUid': claimedByUid,
      };

  /// Deserialize from Firestore document — Phase 2
  factory ItemModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ItemModel(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: ItemType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ItemType.lost,
      ),
      status: ItemStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ItemStatus.active,
      ),
      category: data['category'] as String? ?? 'Other',
      locationLabel: data['locationLabel'] as String? ?? 'Campus',
      reportedAt: data['reportedAt'] != null
          ? DateTime.parse(data['reportedAt'] as String)
          : DateTime.now(),
      imageUrl: data['imageUrl'] as String?,
      lat: data['lat'] as double?,
      lng: data['lng'] as double?,
      reportedByUid: data['reportedByUid'] as String?,
      claimedByUid: data['claimedByUid'] as String?,
    );
  }
}

/// Mock data for Phase 1 visual development.
/// Clearly labeled — replace with real Firestore data in Phase 2.
final class MockItems {
  static final List<ItemModel> all = [
    ItemModel(
      id: 'mock-001',
      title: 'Blue Water Bottle',
      description:
          'Stainless steel Hydro Flask, dent on the side, initials "RS" scratched near the base.',
      type: ItemType.lost,
      status: ItemStatus.active,
      category: 'Accessories',
      locationLabel: 'Near Library, Block B',
      reportedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ItemModel(
      id: 'mock-002',
      title: 'Student ID Card',
      description: 'Belongs to someone in the CS department. Found near the cafeteria.',
      type: ItemType.found,
      status: ItemStatus.active,
      category: 'Documents',
      locationLabel: 'Main Cafeteria',
      reportedAt: DateTime.now().subtract(const Duration(hours: 7)),
    ),
    ItemModel(
      id: 'mock-003',
      title: 'Laptop Charger',
      description: 'Dell 65W charger, USB-C, black cable.',
      type: ItemType.found,
      status: ItemStatus.active,
      category: 'Electronics',
      locationLabel: 'Seminar Hall 3',
      reportedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ItemModel(
      id: 'mock-004',
      title: 'Black Backpack',
      description:
          'Large Wildcraft backpack, has a small tear on the right strap. Contains notebooks.',
      type: ItemType.lost,
      status: ItemStatus.active,
      category: 'Bags',
      locationLabel: 'Sports Complex',
      reportedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ItemModel(
      id: 'mock-005',
      title: 'Glasses — Round Frame',
      description: 'Brown tortoiseshell round glasses. Prescription lenses.',
      type: ItemType.lost,
      status: ItemStatus.claimed,
      category: 'Accessories',
      locationLabel: 'Lab Block, 2nd Floor',
      reportedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  static List<ItemModel> get lost =>
      all.where((i) => i.type == ItemType.lost).toList();

  static List<ItemModel> get found =>
      all.where((i) => i.type == ItemType.found).toList();

  static List<ItemModel> get recent =>
      all..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
}
