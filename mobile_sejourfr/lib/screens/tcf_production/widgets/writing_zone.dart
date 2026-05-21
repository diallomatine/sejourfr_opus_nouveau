import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

/// Zone de rédaction calquée sur `.writing-zone` du mockup HTML.
///
/// Améliorations vs version initiale :
///   - Barre de progression animée (vers minWords puis maxWords)
///   - Stats étendues : mots, caractères, phrases, temps de lecture estimé
///   - Confirmation avant clear (évite la perte accidentelle)
///   - Indicateur d'auto-save (optionnel)
///   - Animations fluides sur changements de status
///   - Accessibilité (Semantics)
///   - Action "expand" pour passer en mode plein écran (optionnel)
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
    this.onExpand,
    this.minLines = 10,
    this.showAutoSave = false,
    this.isSaving = false,
    this.lastSavedAt,
    this.title = 'Votre rédaction',
    this.hint = 'Écrivez votre rédaction ici…',
    this.readingWpm = 200, // mots par minute pour estimation
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final int wordCount;
  final int minWords;
  final int maxWords;
  final VoidCallback? onClear;
  final VoidCallback? onExpand;
  final int minLines;
  final bool showAutoSave;
  final bool isSaving;
  final DateTime? lastSavedAt;
  final String title;
  final String hint;
  final int readingWpm;

  @override
  State<WritingZone> createState() => _WritingZoneState();
}

class _WritingZoneState extends State<WritingZone> with SingleTickerProviderStateMixin {
  FocusNode? _internalFocusNode;
  late final AnimationController _statusAnimController;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    _focusNode.addListener(_onFocusChanged);
    _statusAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant WritingZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Petite animation quand on entre dans la plage
    if (oldWidget.wordCount != widget.wordCount && _inRange && !_wasInRange(oldWidget.wordCount)) {
      _statusAnimController.forward(from: 0);
    }
  }

  bool _wasInRange(int old) => old >= widget.minWords && old <= widget.maxWords;

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
    _statusAnimController.dispose();
    super.dispose();
  }

  bool get _inRange => widget.wordCount >= widget.minWords && widget.wordCount <= widget.maxWords;

  bool get _overMax => widget.wordCount > widget.maxWords;

  bool get _underMin => widget.wordCount > 0 && widget.wordCount < widget.minWords;

  /// Progression 0..1 :
  ///  - 0 -> 0.6 : vers minWords
  ///  - 0.6 -> 1.0 : entre minWords et maxWords
  ///  - >1.0 (clampé) : trop de mots
  double get _progress {
    if (widget.wordCount == 0) return 0;
    if (widget.wordCount <= widget.minWords) {
      return (widget.wordCount / widget.minWords) * 0.6;
    }
    if (widget.wordCount <= widget.maxWords) {
      final delta = widget.wordCount - widget.minWords;
      final range = widget.maxWords - widget.minWords;
      return 0.6 + (delta / range) * 0.4;
    }
    return 1.0;
  }

  String get _statusLabel {
    if (widget.wordCount == 0) return 'Commencez à écrire';
    if (_underMin) {
      final remaining = widget.minWords - widget.wordCount;
      return 'Encore $remaining ${remaining > 1 ? "mots" : "mot"} min.';
    }
    if (_overMax) {
      final over = widget.wordCount - widget.maxWords;
      return '$over ${over > 1 ? "mots" : "mot"} de trop';
    }
    return 'Dans la plage recommandée';
  }

  Color get _statusColor {
    if (widget.wordCount == 0) return AppColors.muted;
    if (_overMax) return AppColors.red;
    if (_underMin) return AppColors.amber;
    return AppColors.green;
  }

  IconData get _statusIcon {
    if (widget.wordCount == 0) return Icons.edit_outlined;
    if (_overMax) return Icons.warning_amber_rounded;
    if (_underMin) return Icons.info_outline_rounded;
    return Icons.check_circle_rounded;
  }

  // ---------- Stats dérivées ----------

  int get _charCount => widget.controller.text.length;

  int get _charCountNoSpaces => widget.controller.text.replaceAll(RegExp(r'\s'), '').length;

  int get _sentenceCount {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return 0;
    final matches = RegExp(r'[.!?]+').allMatches(text);
    return matches.isEmpty ? 1 : matches.length;
  }

  /// Temps de lecture estimé en secondes
  int get _readingTimeSec {
    if (widget.wordCount == 0) return 0;
    final minutes = widget.wordCount / widget.readingWpm;
    return (minutes * 60).round();
  }

  String get _readingTimeLabel {
    final s = _readingTimeSec;
    if (s < 1) return '—';
    if (s < 60) return '$s s';
    final min = (s / 60).floor();
    final rem = s % 60;
    if (rem == 0) return '$min min';
    return '$min min $rem s';
  }

  // ---------- Actions ----------

  Future<void> _handleClear() async {
    if (widget.controller.text.trim().isEmpty) {
      widget.onClear?.call();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Effacer la rédaction ?',
          style: AppFonts.jakarta(
            size: 16,
            weight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'Tout le texte sera supprimé. Cette action est irréversible.',
          style: AppFonts.jakarta(
            size: 14,
            color: AppColors.muted,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Annuler',
              style: AppFonts.jakarta(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Effacer',
              style: AppFonts.jakarta(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      widget.onClear?.call();
    }
  }

  String _formatSavedAt(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 5) return 'à l\'instant';
    if (diff.inSeconds < 60) return 'il y a ${diff.inSeconds} s';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    return 'il y a ${diff.inHours} h';
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    return Semantics(
      container: true,
      label: 'Zone de rédaction',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(focused),
            const SizedBox(height: 8),
            _buildProgressBar(),
            const SizedBox(height: 10),
            _buildTextField(focused),
            const SizedBox(height: 10),
            _buildStatsRow(),
            if (widget.showAutoSave) ...[
              const SizedBox(height: 6),
              _buildAutoSaveRow(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool focused) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 18,
                color: focused ? AppColors.blue : AppColors.ink,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.title,
                  style: AppFonts.jakarta(
                    size: 14,
                    weight: FontWeight.w700,
                    color: focused ? AppColors.blue : AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: anim, child: child),
          ),
          child: Container(
            key: ValueKey('${widget.wordCount}-$_inRange'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _inRange
                  ? AppColors.green.withValues(alpha: 0.12)
                  : AppColors.muted.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.wordCount} mots',
              style: AppFonts.jakarta(
                size: 12,
                weight: FontWeight.w700,
                color: _inRange ? AppColors.green : AppColors.muted,
              ),
            ),
          ),
        ),
        if (widget.onExpand != null) ...[
          const SizedBox(width: 8),
          _IconAction(
            icon: Icons.open_in_full_rounded,
            tooltip: 'Mode plein écran',
            onTap: widget.onExpand!,
            color: AppColors.muted,
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      tween: Tween(begin: 0, end: _progress.clamp(0.0, 1.0)),
      builder: (context, value, _) {
        return Stack(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: value,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: _inRange
                      ? [
                          BoxShadow(
                            color: AppColors.green.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
            // Marqueur minWords
            Positioned(
              left: 0,
              right: 0,
              child: LayoutBuilder(
                builder: (ctx, c) {
                  final pos = c.maxWidth * 0.6 - 1;
                  return Container(
                    margin: EdgeInsets.only(left: pos),
                    width: 2,
                    height: 4,
                    color: AppColors.white,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(bool focused) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: focused ? AppColors.blueSoft : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _overMax
              ? AppColors.red
              : focused
                  ? AppColors.blue
                  : AppColors.line,
          width: (focused || _overMax) ? 1.5 : 1,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: (_overMax ? AppColors.red : AppColors.blue).withValues(alpha: 0.08),
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
          hintText: widget.hint,
          hintStyle: AppFonts.jakarta(
            size: 15,
            color: AppColors.muted2,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Stats compactes
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _StatChip(
                  icon: Icons.text_fields_rounded,
                  label: '${widget.wordCount} mots',
                ),
                _StatChip(
                  icon: Icons.short_text_rounded,
                  label: '$_charCount car.',
                ),
                if (_sentenceCount > 0)
                  _StatChip(
                    icon: Icons.format_quote_rounded,
                    label: '$_sentenceCount ${_sentenceCount > 1 ? "phrases" : "phrase"}',
                  ),
                if (_readingTimeSec > 0)
                  _StatChip(
                    icon: Icons.schedule_rounded,
                    label: _readingTimeLabel,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_statusIcon, size: 14, color: _statusColor),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    _statusLabel,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.onClear != null) ...[
            const SizedBox(width: 8),
            _IconAction(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Effacer',
              onTap: _handleClear,
              color: AppColors.red,
              bgColor: AppColors.redLight,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAutoSaveRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.isSaving) ...[
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation(AppColors.muted),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Enregistrement…',
              style: AppFonts.jakarta(
                size: 11,
                color: AppColors.muted,
                weight: FontWeight.w500,
              ),
            ),
          ] else if (widget.lastSavedAt != null) ...[
            Icon(Icons.cloud_done_outlined, size: 12, color: AppColors.green),
            const SizedBox(width: 4),
            Text(
              'Enregistré ${_formatSavedAt(widget.lastSavedAt!)}',
              style: AppFonts.jakarta(
                size: 11,
                color: AppColors.muted,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ----------------- Sous-widgets utilitaires -----------------

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppFonts.jakarta(
            size: 12,
            color: AppColors.muted,
            weight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.onTap,
    required this.color,
    this.bgColor,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color? bgColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: bgColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}
