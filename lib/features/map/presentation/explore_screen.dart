import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../core/models/item_model.dart';
import '../../../core/widgets/cs_button.dart';
import '../../../core/widgets/cs_card.dart';

/// Explore Screen — Map / List shell
///
/// Phase 1: Layout shell with map placeholder and list toggle.
/// Phase 2: Integrate flutter_map + OpenStreetMap with real item pins.
///
/// Design: Toggle between map view and list view. Map placeholder communicates
/// the future interface without fabricating data or location access.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  bool _showMap = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CSColors.paperWhite,
      appBar: AppBar(
        title: const Text('Explore'),
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
      body: _showMap ? _MapView() : _ListView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Map placeholder — communicates the future interface without fabrication.
class _MapView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map background — textured grid to suggest a map canvas
        SizedBox.expand(
          child: CustomPaint(
            painter: _MapGridPainter(),
          ),
        ),

        // Map placeholder message
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(CSSpacing.lg),
                decoration: BoxDecoration(
                  color: CSColors.paperWhite,
                  borderRadius: BorderRadius.circular(CSSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: CSColors.shadow,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: CSColors.signalLimeTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.map_outlined,
                        size: 28,
                        color: CSColors.signalLimeDark,
                      ),
                    ),
                    const SizedBox(height: CSSpacing.md),
                    Text(
                      'Campus Map',
                      style: CSTypography.headlineSmall,
                    ),
                    const SizedBox(height: CSSpacing.xs),
                    Text(
                      'OpenStreetMap integration\narrives in Phase 2.',
                      style: CSTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: CSSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CSSpacing.sm,
                        vertical: CSSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: CSColors.signalLimeTint,
                        borderRadius:
                            BorderRadius.circular(CSSpacing.radiusXs),
                      ),
                      child: Text(
                        'Architecture boundary',
                        style: CSTypography.caption.copyWith(
                          color: CSColors.signalLimeDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Sample location pins — illustrative, not real data
        ..._samplePins.map((pin) => _MapPin(pin: pin)),

        // Bottom filter strip
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _FilterStrip(),
        ),
      ],
    );
  }
}

class _ListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter row
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CSSpacing.screenPadding,
            CSSpacing.md,
            CSSpacing.screenPadding,
            0,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(label: 'All', selected: true),
                const SizedBox(width: CSSpacing.sm),
                _FilterChip(label: 'Lost', selected: false),
                const SizedBox(width: CSSpacing.sm),
                _FilterChip(label: 'Found', selected: false),
                const SizedBox(width: CSSpacing.sm),
                _FilterChip(label: 'Electronics', selected: false),
                const SizedBox(width: CSSpacing.sm),
                _FilterChip(label: 'Documents', selected: false),
                const SizedBox(width: CSSpacing.sm),
                _FilterChip(label: 'Accessories', selected: false),
              ],
            ),
          ),
        ),
        const SizedBox(height: CSSpacing.md),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: CSSpacing.screenPadding,
              vertical: CSSpacing.xs,
            ),
            itemCount: MockItems.all.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: CSSpacing.md),
            itemBuilder: (context, index) => CSItemCard(
              item: MockItems.all[index],
              onTap: () {},
            ),
          ),
        ),
      ],
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CSSpacing.md,
        vertical: CSSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: selected ? CSColors.signalLime : CSColors.paperDark,
        borderRadius: BorderRadius.circular(CSSpacing.radiusXs),
        border: Border.all(
          color: selected ? CSColors.signalLimeDark : CSColors.graphiteHairline,
        ),
      ),
      child: Text(
        label,
        style: CSTypography.labelMedium.copyWith(
          color: selected ? CSColors.inkBlack : CSColors.graphite,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _FilterStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        CSSpacing.screenPadding,
        CSSpacing.md,
        CSSpacing.screenPadding,
        CSSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: CSColors.paperWhite,
        border: const Border(
          top: BorderSide(color: CSColors.graphiteHairline, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.tune_rounded,
            size: 18,
            color: CSColors.graphite,
          ),
          const SizedBox(width: CSSpacing.sm),
          Text('Filter by area or category', style: CSTypography.bodySmall),
          const Spacer(),
          Text(
            '${MockItems.all.length} items',
            style: CSTypography.labelMedium,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PinData {
  const _PinData({
    required this.label,
    required this.type,
    required this.x,
    required this.y,
  });
  final String label;
  final ItemType type;
  final double x; // fractional position
  final double y;
}

const _samplePins = [
  _PinData(label: 'Library', type: ItemType.lost, x: 0.25, y: 0.35),
  _PinData(label: 'Cafeteria', type: ItemType.found, x: 0.6, y: 0.45),
  _PinData(label: 'Seminar Hall', type: ItemType.found, x: 0.75, y: 0.28),
  _PinData(label: 'Sports Complex', type: ItemType.lost, x: 0.4, y: 0.65),
];

class _MapPin extends StatelessWidget {
  const _MapPin({required this.pin});
  final _PinData pin;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final color =
        pin.type == ItemType.lost ? CSColors.statusLost : CSColors.statusFound;
    return Positioned(
      left: pin.x * size.width - 16,
      top: pin.y * (size.height - 120) + 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(CSSpacing.radiusXs),
            ),
            child: Text(
              pin.label,
              style: CSTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(10, 6),
            painter: _PinArrowPainter(color: color),
          ),
        ],
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

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CSColors.graphiteHairline
      ..strokeWidth = 0.5;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFEEEBE3),
    );
    // Grid lines on top
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
