import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Zone de redaction calquee sur `.writing-zone` du mockup HTML :
///   - en-tete "Votre redaction" + compteur vert
///   - textarea blanc avec border haut (la toolbar BIU du HTML est cosmetique,
///     pas implementee pour Lot B -- le backend recoit du texte brut)
///   - bottom row : "Mots : X", check "Dans la plage", bouton corbeille
class WritingZone extends StatelessWidget {
  const WritingZone({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.wordCount,
    required this.minWords,
    required this.maxWords,
    this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int wordCount;
  final int minWords;
  final int maxWords;
  final VoidCallback? onClear;

  bool get _inRange => wordCount >= minWords && wordCount <= maxWords;

  String get _statusLabel {
    if (wordCount == 0) return 'Commencez a ecrire';
    if (wordCount < minWords) return 'Encore ${minWords - wordCount} mots min.';
    if (wordCount > maxWords) return '${wordCount - maxWords} mots de trop';
    return 'Dans la plage recommandee';
  }

  Color get _statusColor {
    if (wordCount == 0) return AppColors.muted;
    if (wordCount > maxWords) return AppColors.red;
    if (wordCount < minWords) return AppColors.amber;
    return AppColors.green;
  }

  @override
  Widget build(BuildContext context) {
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
                    'Votre redaction',
                    style: AppFonts.jakarta(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Text(
                  '$wordCount mots',
                  style: AppFonts.jakarta(
                    size: 13,
                    weight: FontWeight.w600,
                    color: _inRange ? AppColors.green : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.multiline,
              minLines: 10,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: AppFonts.jakarta(
                size: 14,
                color: AppColors.ink,
                height: 1.6,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: 'Ecrivez votre redaction ici...',
                hintStyle: AppFonts.jakarta(
                  size: 14,
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
                  'Mots : $wordCount',
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
                if (onClear != null) ...[
                  const SizedBox(width: 12),
                  Material(
                    color: AppColors.redLight,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: onClear,
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
