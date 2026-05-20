import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Zone de rédaction calquée sur `.writing-zone` du mockup HTML :
///   - en-tête "Votre rédaction" + compteur vert
///   - textarea blanc avec bordure (bleue au focus)
///   - bottom row : "Mots : X", check "Dans la plage", bouton corbeille
class WritingZone extends StatefulWidget {
  const WritingZone({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.wordCount,
    required this.minWords,
    required this.maxWords,
    this.focusNode,
    this.onClear,
    this.minLines = 10,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final int wordCount;
  final int minWords;
  final int maxWords;
  final VoidCallback? onClear;
  final int minLines;

  @override
  State<WritingZone> createState() => _WritingZoneState();
}

class _WritingZoneState extends State<WritingZone> {
  FocusNode? _internalFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  bool get _inRange =>
      widget.wordCount >= widget.minWords && widget.wordCount <= widget.maxWords;

  String get _statusLabel {
    if (widget.wordCount == 0) return 'Commencez à écrire';
    if (widget.wordCount < widget.minWords) {
      return 'Encore ${widget.minWords - widget.wordCount} mots min.';
    }
    if (widget.wordCount > widget.maxWords) {
      return '${widget.wordCount - widget.maxWords} mots de trop';
    }
    return 'Dans la plage recommandée';
  }

  Color get _statusColor {
    if (widget.wordCount == 0) return AppColors.muted;
    if (widget.wordCount > widget.maxWords) return AppColors.red;
    if (widget.wordCount < widget.minWords) return AppColors.amber;
    return AppColors.green;
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Votre rédaction',
                    style: AppFonts.jakarta(
                      size: 14,
                      weight: FontWeight.w700,
                      color: focused ? AppColors.blue : AppColors.ink,
                    ),
                  ),
                ),
                Text(
                  '${widget.wordCount} mots',
                  style: AppFonts.jakarta(
                    size: 13,
                    weight: FontWeight.w600,
                    color: _inRange ? AppColors.green : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: focused ? AppColors.blueSoft : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: focused ? AppColors.blue : AppColors.line,
                width: focused ? 1.5 : 1,
              ),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              onTapOutside: (_) => _focusNode.unfocus(),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: widget.minLines,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: AppColors.blue,
              cursorWidth: 1.5,
              cursorRadius: const Radius.circular(1),
              style: AppFonts.jakarta(
                size: 15,
                color: AppColors.ink,
                height: 1.6,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: 'Écrivez votre rédaction ici…',
                hintStyle: AppFonts.jakarta(
                  size: 15,
                  color: AppColors.muted2,
                  height: 1.6,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: Row(
              children: [
                Text(
                  'Mots : ${widget.wordCount}',
                  style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                ),
                const Spacer(),
                Icon(
                  _inRange ? Icons.check_rounded : Icons.info_outline_rounded,
                  size: 14,
                  color: _statusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _statusLabel,
                  style: AppFonts.jakarta(
                    size: 12,
                    weight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
                if (widget.onClear != null) ...[
                  const SizedBox(width: 12),
                  Material(
                    color: AppColors.redLight,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: widget.onClear,
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.red),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
