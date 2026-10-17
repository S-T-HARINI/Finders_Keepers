import 'package:flutter/material.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';

/// Campus Signal — Search Bar
///
/// Custom search input styled to the CS design system.
/// Not a generic Material SearchBar — has specific CS visual treatment.
class CSSearchBar extends StatefulWidget {
  const CSSearchBar({
    super.key,
    this.hint = 'Search items…',
    this.onChanged,
    this.onSubmitted,
    this.controller,
  });

  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;

  @override
  State<CSSearchBar> createState() => _CSSearchBarState();
}

class _CSSearchBarState extends State<CSSearchBar> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: CSColors.paperDark,
        borderRadius: BorderRadius.circular(CSSpacing.radiusSm),
        border: Border.all(color: CSColors.graphiteHairline),
      ),
      child: Row(
        children: [
          const SizedBox(width: CSSpacing.md),
          const Icon(
            Icons.search_rounded,
            size: 20,
            color: CSColors.graphite,
          ),
          const SizedBox(width: CSSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: CSTypography.bodyMedium.copyWith(
                color: CSColors.inkBlack,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: CSTypography.bodyMedium.copyWith(
                  color: CSColors.graphite,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                fillColor: Colors.transparent,
                filled: false,
              ),
            ),
          ),
          if (_hasText)
            GestureDetector(
              onTap: () {
                _controller.clear();
                widget.onChanged?.call('');
              },
              child: const Padding(
                padding: EdgeInsets.all(CSSpacing.sm),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 18,
                  color: CSColors.graphite,
                ),
              ),
            )
          else
            const SizedBox(width: CSSpacing.md),
        ],
      ),
    );
  }
}
