import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../core/models/item_model.dart';
import '../../../core/services/local_cache_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/sync_queue_service.dart';
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

  ReportDraft? _cachedDraft;
  bool _showDraftBanner = false;

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

    _titleController.addListener(_autoSaveDraft);
    _descriptionController.addListener(_autoSaveDraft);
    _specificLocationController.addListener(_autoSaveDraft);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForDraft();
    });
  }

  Future<void> _checkForDraft() async {
    final draft = await ref.read(localCacheServiceProvider).loadDraft();
    if (draft != null && !draft.isEmpty && mounted) {
      setState(() {
        _cachedDraft = draft;
        _showDraftBanner = true;
      });
    }
  }

  void _restoreDraft() {
    if (_cachedDraft == null) return;
    setState(() {
      _selectedType = _cachedDraft!.type;
      _selectedCategory = _categories.contains(_cachedDraft!.category)
          ? _cachedDraft!.category
          : _categories.first;
      _selectedZone = CampusLocations.zones.contains(_cachedDraft!.zone)
          ? _cachedDraft!.zone
          : CampusLocations.zones.first;
      _selectedDate = _cachedDraft!.reportedAt;
      _titleController.text = _cachedDraft!.title;
      _descriptionController.text = _cachedDraft!.description;
      _specificLocationController.text = _cachedDraft!.specificLocation;
      _pickedImagePath = _cachedDraft!.imagePath;
      _protectPrivacy = _cachedDraft!.protectPrivacy;
      _showDraftBanner = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft restored successfully.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _discardDraft() async {
    await ref.read(localCacheServiceProvider).clearDraft();
    if (mounted) {
      setState(() {
        _cachedDraft = null;
        _showDraftBanner = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft discarded.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _autoSaveDraft() {
    if (_isSubmitting) return;
    final draft = ReportDraft(
      type: _selectedType,
      category: _selectedCategory,
      zone: _selectedZone,
      title: _titleController.text,
      description: _descriptionController.text,
      specificLocation: _specificLocationController.text,
      reportedAt: _selectedDate,
      imagePath: _pickedImagePath,
      protectPrivacy: _protectPrivacy,
    );
    if (!draft.isEmpty) {
      ref.read(localCacheServiceProvider).saveDraft(draft);
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_autoSaveDraft);
    _descriptionController.removeListener(_autoSaveDraft);
    _specificLocationController.removeListener(_autoSaveDraft);
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
      _autoSaveDraft();
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
      _autoSaveDraft();
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

      // Save item to repository (persisting to local storage or Firestore)
      await ref.read(itemRepositoryProvider).createItem(newItem);

      // Track in offline sync queue
      await ref.read(syncQueueServiceProvider).enqueue(
            idempotencyKey: 'item_${newItem.id}',
            actionType: 'create_item',
            payload: newItem.toFirestore(),
          );
      await ref.read(syncQueueServiceProvider).markSynced('item_${newItem.id}');

      // Clear draft after successful creation
      await ref.read(localCacheServiceProvider).clearDraft();

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
              // ─── Draft Recovery Banner ────────────────────────────────────
              if (_showDraftBanner && _cachedDraft != null) ...[
                Container(
                  padding: const EdgeInsets.all(CSSpacing.spacing16),
                  margin: const EdgeInsets.only(bottom: CSSpacing.spacing16),
                  decoration: BoxDecoration(
                    color: CSColors.surfaceCard,
                    borderRadius: BorderRadius.circular(CSSpacing.radiusCard),
                    border: Border.all(color: CSColors.accentLimeDark, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history_outlined, color: CSColors.accentLimeDark, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Unsaved Report Draft',
                            style: CSTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'You have an unsaved draft from ${DateFormat('MMM d, h:mm a').format(_cachedDraft!.reportedAt)}${_cachedDraft!.title.isNotEmpty ? ": \"${_cachedDraft!.title}\"" : ""}.',
                        style: CSTypography.bodySmall.copyWith(color: CSColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _restoreDraft,
                            icon: const Icon(Icons.restore, size: 16),
                            label: const Text('Restore Draft'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CSColors.accentLimeDark,
                              foregroundColor: CSColors.textPrimary,
                              textStyle: CSTypography.labelSmall.copyWith(fontWeight: FontWeight.w700),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(CSSpacing.radiusButton),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _discardDraft,
                            child: Text(
                              'Discard',
                              style: CSTypography.labelSmall.copyWith(color: CSColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // ─── Type Selector Segmented Row ───────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedType = ItemType.lost);
                        _autoSaveDraft();
                      },
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
                      onTap: () {
                        setState(() => _selectedType = ItemType.found);
                        _autoSaveDraft();
                      },
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
                              color: !isLost ? CSColors.accentLimeDark : CSColors.textMuted,
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

              // ─── Item Details Header ───────────────────────────────────────
              const CSSectionHeader(title: 'Item Details'),
              const SizedBox(height: CSSpacing.spacing12),

              // Title Field
              TextFormField(
                controller: _titleController,
                style: CSTypography.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g. Blue Hydro Flask, Silver AirPods Pro',
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
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a title for the item.';
                  }
                  if (val.trim().length < 3) {
                    return 'Title must be at least 3 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: CSSpacing.spacing16),

              // Category Selector
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                style: CSTypography.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Category *',
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
                items: _categories.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c, style: CSTypography.bodyMedium),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                    _autoSaveDraft();
                  }
                },
              ),
              const SizedBox(height: CSSpacing.spacing16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: CSTypography.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Detailed Description *',
                  hintText: isLost
                      ? 'Describe key visual markers, stickers, scratch marks, case color...'
                      : 'Provide a general public description. Keep unique private serials or passcode details secret so the rightful owner can verify them.',
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
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please provide a description.';
                  }
                  if (val.trim().length < 8) {
                    return 'Description must be at least 8 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: CSSpacing.spacing24),

              // ─── Location & Date Section ───────────────────────────────────
              const CSSectionHeader(title: 'Campus Location & Date'),
              const SizedBox(height: CSSpacing.spacing12),

              // Campus Zone Selector
              DropdownButtonFormField<String>(
                initialValue: _selectedZone,
                style: CSTypography.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Approximate Campus Area *',
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
                items: CampusLocations.zones.map((z) {
                  return DropdownMenuItem(
                    value: z,
                    child: Text(z, style: CSTypography.bodyMedium),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedZone = val);
                    _autoSaveDraft();
                  }
                },
              ),
              const SizedBox(height: CSSpacing.spacing16),

              // Specific sub-location (optional)
              TextFormField(
                controller: _specificLocationController,
                style: CSTypography.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Specific Spot (Optional)',
                  hintText: 'e.g. 2nd floor silent study room, bench near cafe',
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

              // Date Selector Tile
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLost ? 'Date Lost' : 'Date Found',
                            style: CSTypography.caption.copyWith(color: CSColors.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMMM d, yyyy').format(_selectedDate),
                            style: CSTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Icon(Icons.calendar_today_outlined, size: 20, color: CSColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: CSSpacing.spacing24),

              // ─── Photo Upload Section ──────────────────────────────────────
              const CSSectionHeader(title: 'Item Photo'),
              const SizedBox(height: CSSpacing.spacing12),

              if (_pickedImagePath != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(CSSpacing.radiusCard),
                      child: Image.file(
                        File(_pickedImagePath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: CSColors.inkBlack.withValues(alpha: 0.7),
                        radius: 18,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, color: CSColors.paperWhite, size: 18),
                          onPressed: () {
                            setState(() => _pickedImagePath = null);
                            _autoSaveDraft();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CSSpacing.spacing12),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Camera'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: CSColors.textPrimary,
                          side: const BorderSide(color: CSColors.dividerLight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(CSSpacing.radiusButton),
                          ),
                        ),
                        onPressed: () => _pickImage(true),
                      ),
                    ),
                    const SizedBox(width: CSSpacing.spacing12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: CSColors.textPrimary,
                          side: const BorderSide(color: CSColors.dividerLight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(CSSpacing.radiusButton),
                          ),
                        ),
                        onPressed: () => _pickImage(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CSSpacing.spacing8),
                Text(
                  'Photos help owners confirm matches faster.',
                  style: CSTypography.caption.copyWith(color: CSColors.textMuted),
                ),
                const SizedBox(height: CSSpacing.spacing16),
              ],

              // ─── Privacy Guard Switch ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(CSSpacing.spacing16),
                decoration: BoxDecoration(
                  color: CSColors.surfaceCard,
                  borderRadius: BorderRadius.circular(CSSpacing.radiusCard),
                  border: Border.all(color: CSColors.dividerLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shield_outlined, size: 18, color: CSColors.textPrimary),
                              const SizedBox(width: 8),
                              Text(
                                'Mask Sensitive Details',
                                style: CSTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Approximate location on public maps to prevent unauthorized scavenging.',
                            style: CSTypography.bodySmall.copyWith(color: CSColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _protectPrivacy,
                      activeThumbColor: CSColors.accentLimeDark,
                      onChanged: (val) {
                        setState(() => _protectPrivacy = val);
                        _autoSaveDraft();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CSSpacing.spacing32),

              // ─── Submit CTA ────────────────────────────────────────────────
              CSPrimaryButton(
                label: _isSubmitting
                    ? 'Publishing Report...'
                    : (isLost ? 'Submit Lost Item Report' : 'Submit Found Item Report'),
                icon: isLost ? Icons.search : Icons.check_circle_outline,
                onPressed: _isSubmitting ? null : _handleSubmit,
              ),
              const SizedBox(height: CSSpacing.spacing32),
            ],
          ),
        ),
      ),
    );
  }
}
