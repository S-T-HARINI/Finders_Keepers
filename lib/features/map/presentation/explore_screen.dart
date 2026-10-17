import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../core/models/item_model.dart';
import '../../../core/widgets/cs_button.dart';
import '../../../core/widgets/cs_card.dart';
import '../../items/data/item_repository.dart';
import 'campus_locations.dart';

/// Explore Screen — Interactive OpenStreetMap & List view
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  bool _showMap = true;
  String _selectedCategory = 'All';
  ItemType? _selectedType;
  ItemModel? _selectedItemPreview;

  final MapController _mapController = MapController();

  final List<String> _filters = const [
    'All',
    'Lost',
    'Found',
    'Accessories',
    'Electronics',
    'Documents',
    'Bags',
    'Keys',
  ];

  void _onFilterTap(String filter) {
    setState(() {
      _selectedCategory = filter;
      if (filter == 'Lost') {
        _selectedType = ItemType.lost;
      } else if (filter == 'Found') {
        _selectedType = ItemType.found;
      } else {
        _selectedType = null;
      }
      _selectedItemPreview = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = (
      type: _selectedType,
      category: (_selectedCategory != 'All' && _selectedCategory != 'Lost' && _selectedCategory != 'Found')
          ? _selectedCategory
          : null,
      query: '',
    );

    final itemsAsync = ref.watch(filteredItemsStreamProvider(filter));

    return Scaffold(
      backgroundColor: CSColors.paperWhite,
      appBar: AppBar(
        backgroundColor: CSColors.paperWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Explore Campus'),
        actions: [
          // Map / List toggle
          Container(
            margin: const EdgeInsets.only(right: CSSpacing.md),
            decoration: BoxDecoration(
              color: CSColors.paperDark,
              borderRadius: BorderRadius.circular(CSSpacing.radiusSm),
              border: Border.all(color: CSColors.graphiteHairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToggleTab(
                  icon: Icons.map_outlined,
                  label: 'Map',
                  selected: _showMap,
                  onTap: () => setState(() => _showMap = true),
                ),
                _ToggleTab(
                  icon: Icons.list_rounded,
                  label: 'List',
                  selected: !_showMap,
                  onTap: () => setState(() => _showMap = false),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            color: CSColors.paperWhite,
            padding: const EdgeInsets.symmetric(horizontal: CSSpacing.screenPadding, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filterName) {
                  final isSelected = _selectedCategory == filterName;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filterName),
                      selected: isSelected,
                      selectedColor: CSColors.accentLime,
                      backgroundColor: CSColors.surfaceCard,
                      labelStyle: CSTypography.labelSmall.copyWith(
                        color: isSelected ? CSColors.textPrimary : CSColors.textMuted,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: isSelected ? CSColors.accentLimeDark : CSColors.dividerLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(CSSpacing.radiusChip),
                      ),
                      onSelected: (_) => _onFilterTap(filterName),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: CSColors.dividerLight),

          // Content
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: CSColors.textPrimary),
              ),
              error: (err, _) => Center(
                child: Text('Error loading map items: $err'),
              ),
              data: (items) {
                return _showMap
                    ? _buildInteractiveMap(items)
                    : _buildListView(items);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMap(List<ItemModel> items) {
    // Generate markers from items that have approximate coordinates
    final markers = items.map((item) {
      final lat = item.lat ?? CampusLocations.centerLat;
      final lng = item.lng ?? CampusLocations.centerLng;
      final isLost = item.type == ItemType.lost;
      final color = isLost ? CSColors.statusLost : CSColors.statusFound;

      return Marker(
        point: LatLng(lat, lng),
        width: 120,
        height: 60,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedItemPreview = item;
            });
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(CSSpacing.radiusXs),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CSTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              CustomPaint(
                size: const Size(8, 5),
                painter: _PinArrowPainter(color: color),
              ),
            ],
          ),
        ),
      );
    }).toList();

    // Privacy Circles: 100m approximate radius circles around items
    final circles = items.map((item) {
      final lat = item.lat ?? CampusLocations.centerLat;
      final lng = item.lng ?? CampusLocations.centerLng;
      final isLost = item.type == ItemType.lost;
      return CircleMarker(
        point: LatLng(lat, lng),
        radius: 40,
        useRadiusInMeter: true,
        color: (isLost ? CSColors.statusLost : CSColors.accentLime).withValues(alpha: 0.15),
        borderColor: (isLost ? CSColors.statusLost : CSColors.accentLimeDark).withValues(alpha: 0.4),
        borderStrokeWidth: 1.5,
      );
    }).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(CampusLocations.centerLat, CampusLocations.centerLng),
            initialZoom: 16.2,
            minZoom: 14.0,
            maxZoom: 18.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.campustech.finders_keepers',
            ),
            CircleLayer(circles: circles),
            MarkerLayer(markers: markers),
          ],
        ),

        // Approximate Location Privacy Badge
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CSColors.surfaceCard.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(CSSpacing.radiusSmall),
              border: Border.all(color: CSColors.dividerLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.privacy_tip_outlined, size: 16, color: CSColors.accentLimeDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Approximate ~100m zones shown to protect privacy',
                    style: CSTypography.caption.copyWith(color: CSColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Selected Pin Bottom Preview Card
        if (_selectedItemPreview != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: GestureDetector(
              onTap: () {
                context.push('/items/${_selectedItemPreview!.id}');
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CSColors.surfaceCard,
                  borderRadius: BorderRadius.circular(CSSpacing.radiusCard),
                  border: Border.all(
                    color: _selectedItemPreview!.type == ItemType.lost
                        ? CSColors.warningOrange
                        : CSColors.accentLimeDark,
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              CSStatusLabel(
                                text: _selectedItemPreview!.type == ItemType.lost ? 'LOST' : 'FOUND',
                                color: _selectedItemPreview!.type == ItemType.lost
                                    ? CSColors.warningOrange
                                    : CSColors.accentLimeDark,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedItemPreview!.category,
                                style: CSTypography.caption.copyWith(color: CSColors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedItemPreview!.title,
                            style: CSTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _selectedItemPreview!.locationLabel,
                            style: CSTypography.bodySmall.copyWith(color: CSColors.textMuted),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: CSColors.textPrimary),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListView(List<ItemModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Text('No items match selected filter', style: CSTypography.bodyMedium),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(CSSpacing.screenPadding),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: CSSpacing.md),
      itemBuilder: (context, index) => CSItemCard(
        item: items[index],
        onTap: () {
          context.push('/items/${items[index].id}');
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: CSSpacing.md,
          vertical: CSSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? CSColors.signalLime : Colors.transparent,
          borderRadius: BorderRadius.circular(CSSpacing.radiusSm - 2),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? CSColors.inkBlack : CSColors.graphite,
            ),
            const SizedBox(width: CSSpacing.xs),
            Text(
              label,
              style: CSTypography.labelMedium.copyWith(
                color: selected ? CSColors.inkBlack : CSColors.graphite,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinArrowPainter extends CustomPainter {
  const _PinArrowPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
