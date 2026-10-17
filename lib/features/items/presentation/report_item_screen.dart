import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/item_model.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/cs_button.dart';
import '../../../core/widgets/cs_card.dart';
import '../../auth/data/auth_repository.dart';
import '../../map/presentation/campus_locations.dart';
import '../data/item_repository.dart';

class ReportItemScreen extends ConsumerStatefulWidget {
  const ReportItemScreen({
    super.key,
    this.initialType = ItemType.lost,
  });

  final ItemType initialType;

  @override
  ConsumerState<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends ConsumerState<ReportItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late ItemType _selectedType;
  late String _selectedCategory;
  late String _selectedZone;
  late DateTime _selectedDate;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _specificLocationController = TextEditingController();

  String? _pickedImagePath;
  bool _protectPrivacy = true;
  bool _isSubmitting = false;

  final List<String> _categories = const [
    'Accessories',
    'Electronics',
    'Documents',
    'Bags',
    'Keys',
    'Apparel',
    'Books',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedCategory = _categories.first;
    _selectedZone = CampusLocations.zones.first;
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _specificLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool fromCamera) async {
    final storageService = ref.read(storageServiceProvider);
    final path = await storageService.pickImage(fromCamera: fromCamera);
    if (path != null && mounted) {
      setState(() {
        _pickedImagePath = path;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: CSColors.accentLimeDark,
              onPrimary: CSColors.textPrimary,
              surface: CSColors.surfaceCard,
              onSurface: CSColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      final locationMatch = CampusLocations.all.firstWhere(
        (loc) => loc.name == _selectedZone,
        orElse: () => CampusLocations.all.first,
      );

      final fullLocationLabel = _specificLocationController.text.trim().isNotEmpty
          ? '$_selectedZone (${_specificLocationController.text.trim()})'
          : _selectedZone;

      final newItem = ItemModel(
        id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        status: ItemStatus.active,
        category: _selectedCategory,
        locationLabel: fullLocationLabel,
        reportedAt: _selectedDate,
        imageUrl: _pickedImagePath,
        lat: locationMatch.lat,
        lng: locationMatch.lng,
        reportedByUid: currentUser?.id ?? 'guest_user',
      );

      await ref.read(itemRepositoryProvider).createItem(newItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: CSColors.accentLimeDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CSSpacing.radiusSmall),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: CSColors.textPrimary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_selectedType == ItemType.lost ? "Lost report" : "Found report"} registered successfully!',
                    style: CSTypography.labelSmall.copyWith(
                      color: CSColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: CSColors.warningOrange,
            content: Text('Failed to submit report: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLost = _selectedType == ItemType.lost;

    return Scaffold(
      backgroundColor: CSColors.bgPaper,
      appBar: AppBar(
        backgroundColor: CSColors.bgPaper,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CSColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Report an Item',
          style: CSTypography.headlineSmall.copyWith(fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: CSSpacing.pageHorizontal,
              vertical: CSSpacing.spacing16,
            ),
            children: [
              // ─── Type Selector Segmented Row ───────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = ItemType.lost),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isLost ? CSColors.surfaceLostTint : CSColors.surfaceCard,
                          borderRadius: BorderRadius.circular(CSSpacing.radiusCard),
                          border: Border.all(
                            color: isLost ? CSColors.warningOrange : CSColors.dividerLight,
                            width: isLost ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_outlined,
                              color: isLost ? CSColors.warningOrange : CSColors.textMuted,
                              size: 22,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'I Lost Something',
                              style: CSTypography.labelMedium.copyWith(
                                color: isLost ? CSColors.textPrimary : CSColors.textMuted,
                                fontWeight: isLost ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: CSSpacing.spacing12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = ItemType.found),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !isLost ? CSColors.surfaceFoundTint : CSColors.surfaceCard,
                          borderRadius: BorderRadius.circular(CSSpacing.radiusCard),
                          border: Border.all(
                            color: !isLost ? CSColors.accentLimeDark : CSColors.dividerLight,
                            width: !isLost ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.volunteer_activism_outlined,
                              color: !isLost ? CSColors.textPrimary : CSColors.textMuted,
                              size: 22,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'I Found Something',
                              style: CSTypography.labelMedium.copyWith(
                                color: !isLost ? CSColors.textPrimary : CSColors.textMuted,
                                fontWeight: !isLost ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CSSpacing.spacing24),

              // ─── Section: Item Details ─────────────────────────────────────
              const CSSectionHeader(title: 'Item Details'),
              const SizedBox(height: CSSpacing.spacing12),

              TextFormField(
                controller: _titleController,
                style: CSTypography.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g., Wildcraft Black Backpack',
                  hintStyle: CSTypography.bodySmall.copyWith(color: CSColors.textMuted),
                  filled: true,
                  fillColor: CSColors.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CSSpacing.radiusInput),
                    borderSide: const BorderSide(color: CSColors.dividerLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CSSpacing.radiusInput),
                    borderSide: const BorderSide(color: CSColors.dividerLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CSSpacing.radiusInput),
                    borderSide: const BorderSide(color: CSColors.textPrimary, width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the item name';
                  }
                  if (val.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: CSSpacing.spacing16),

              // ─── Category Selection Chips ──────────────────────────────────
              Text(
                'Category',
                style: CSTypography.labelSmall.copyWith(color: CSColors.textMuted),
              ),
              const SizedBox(height: CSSpacing.spacing8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
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
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: CSSpacing.spacing16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                maxLength: AppConstants.kDescriptionMaxLength,
                style: CSTypography.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Description & Identifying Marks *',
                  hintText: 'Color, brand, distinguishing marks, stickers, dents, or contents...',
                  hintStyle: CSTypography.bodySmall.copyWith(color: CSColors.textMuted),
                  filled: true,
                  fillColor: CSColors.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CSSpacing.radiusInput),
                    borderSide: const BorderSide(color: CSColors.dividerLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CSSpacing.radiusInput),
                    borderSide: const BorderSide(color: CSColors.dividerLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CSSpacing.radiusInput),
                    borderSide: const BorderSide(color: CSColors.textPrimary, width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please describe the item';
                  }
                  if (val.trim().length < 10) {
                    return 'Please provide at least 10 characters of description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: CSSpacing.spacing20),

              // ─── Section: Location & Date ──────────────────────────────────
              const CSSectionHeader(title: 'Campus Location & Date'),
              const SizedBox(height: CSSpacing.spacing12),

              DropdownButtonFormField<String>(
                initialValue: _selectedZone,
                decoration: InputDecoration(
                  labelText: 'Campus Zone *',
                  filled: true,
                  fillColor: CSColors.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CSSpacing.radiusInput),
                    borderSide: const BorderSide(color: CSColors.dividerLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CSSpacing.radiusInput),
                    borderSide: const BorderSide(color: CSColors.dividerLight),
                  ),
                ),
                items: CampusLocations.zones.map((zone) {
                  return DropdownMenuItem(
                    value: zone,
                    child: Text(zone, style: CSTypography.bodyMedium),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedZone = val);
                  }
                },
              ),
              const SizedBox(height: CSSpacing.spacing16),

              TextFormField(
                controller: _specificLocationController,
                style: CSTypography.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Specific Room or Landmark (Optional)',
                  hintText: 'e.g., 2nd floor study table #4, Near water cooler',
                  hintStyle: CSTypography.bodySmall.copyWith(color: CSColors.textMuted),
                  filled: true,
                  fillColor: CSColors.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CSSpacing.radiusInput),
                    borderSide: const BorderSide(color: CSColors.dividerLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CSSpacing.radiusInput),
                    borderSide: const BorderSide(color: CSColors.dividerLight),
                  ),
                ),
              ),
              const SizedBox(height: CSSpacing.spacing16),

              // ─── Date Picker Row ───────────────────────────────────────────
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(CSSpacing.radiusInput),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: CSColors.surfaceCard,
                    borderRadius: BorderRadius.circular(CSSpacing.radiusInput),
                    border: Border.all(color: CSColors.dividerLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 20, color: CSColors.textMuted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLost ? 'Date Lost' : 'Date Found',
                              style: CSTypography.labelSmall.copyWith(color: CSColors.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                              style: CSTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: CSColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: CSSpacing.spacing20),

              // ─── Section: Photos ───────────────────────────────────────────
              const CSSectionHeader(title: 'Item Photo'),
              const SizedBox(height: CSSpacing.spacing12),

              if (_pickedImagePath != null)
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(CSSpacing.radiusCard),
                        border: Border.all(color: CSColors.dividerLight),
                        image: DecorationImage(
                          image: FileImage(File(_pickedImagePath!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => setState(() => _pickedImagePath = null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: CSColors.textPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: CSColors.textInverse, size: 18),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(CSSpacing.spacing20),
                  decoration: BoxDecoration(
                    color: CSColors.surfaceCard,
                    borderRadius: BorderRadius.circular(CSSpacing.radiusCard),
                    border: Border.all(
                      color: CSColors.dividerLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 36, color: CSColors.textMuted),
                      const SizedBox(height: 8),
                      Text(
                        'Upload a clear photo to help identify this item',
                        style: CSTypography.bodySmall.copyWith(color: CSColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _pickImage(true),
                            icon: const Icon(Icons.photo_camera, size: 18, color: CSColors.textPrimary),
                            label: const Text('Camera', style: TextStyle(color: CSColors.textPrimary)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: CSColors.dividerLight),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(CSSpacing.radiusButton),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => _pickImage(false),
                            icon: const Icon(Icons.photo_library_outlined, size: 18, color: CSColors.textPrimary),
                            label: const Text('Gallery', style: TextStyle(color: CSColors.textPrimary)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: CSColors.dividerLight),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(CSSpacing.radiusButton),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: CSSpacing.spacing20),

              // ─── Privacy Shield Option ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(CSSpacing.spacing16),
                decoration: BoxDecoration(
                  color: CSColors.surfaceCard,
                  borderRadius: BorderRadius.circular(CSSpacing.radiusCard),
                  border: Border.all(color: CSColors.dividerLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, color: CSColors.accentLimeDark, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mask Sensitive Details',
                            style: CSTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Keep exact location and distinguishing marks concealed until claim verification to prevent fraudulent claims.',
                            style: CSTypography.bodySmall.copyWith(color: CSColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _protectPrivacy,
                      activeThumbColor: CSColors.textPrimary,
                      activeTrackColor: CSColors.accentLime,
                      onChanged: (val) => setState(() => _protectPrivacy = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CSSpacing.spacing32),

              // ─── Submit Action Button ──────────────────────────────────────
              CSPrimaryButton(
                label: _isSubmitting
                    ? 'Submitting...'
                    : (isLost ? 'Submit Lost Item Report' : 'Submit Found Item Report'),
                icon: isLost ? Icons.campaign_outlined : Icons.check_circle_outline,
                onPressed: _isSubmitting ? null : _handleSubmit,
              ),
              const SizedBox(height: CSSpacing.spacing24),
            ],
          ),
        ),
      ),
    );
  }
}
