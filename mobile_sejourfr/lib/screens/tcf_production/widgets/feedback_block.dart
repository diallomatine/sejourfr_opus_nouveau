import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

enum FeedbackKind { positive, improve, suggest }

/// Bloc colore avec une liste a puces. Trois variantes : positif (vert),
/// a ameliorer (ambre), suggestions (violet).
class FeedbackBlock extends StatelessWidget {
  const FeedbackBlock({
    super.key,
    required this.kind,
    required this.title,
    required this.items,
    this.subtitle,
  }) : blocks = const [];

  /// Meme habillage (teinte, titre, intention), mais un contenu compose a la
  /// place des puces : une priorite ne tient pas sur une ligne, elle porte une
  /// technique et sa demonstration.
  const FeedbackBlock.rich({
    super.key,
    required this.kind,
    required this.title,
    required this.blocks,
    this.subtitle,
  }) : items = const [];

  final FeedbackKind kind;
  final String title;
  final List<String> items;
  final List<Widget> blocks;

  /// Ligne d'intention sous le titre (ex: cadrer les priorites plutot que de
  /// les lire comme une liste de reproches).
  final String? subtitle;

  ({Color bg, Color accent, IconData icon}) get _palette {
    switch (kind) {
      case FeedbackKind.positive:
        return (
          bg: AppColors.green.withValues(alpha: 0.08),
          accent: AppColors.green,
          icon: LucideIcons.circleCheck,
        );
      case FeedbackKind.improve:
        return (
          bg: AppColors.amber.withValues(alpha: 0.10),
          accent: AppColors.amber,
          icon: LucideIcons.circleAlert,
        );
      case FeedbackKind.suggest:
        // Bleu France : la suggestion n'a pas de sémantique propre, elle suit
        // la marque (le violet hors palette venait de la maquette HTML).
        return (
          bg: AppColors.blue.withValues(alpha: 0.07),
          accent: AppColors.blue,
          icon: LucideIcons.lightbulb,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && blocks.isEmpty) return const SizedBox.shrink();
    final p = _palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(p.icon, size: 18, color: p.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppFonts.ui(
                  size: 13,
                  weight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppFonts.ui(
                size: 12,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: p.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e,
                      style: AppFonts.ui(
                        size: 13,
                        color: AppColors.ink,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...blocks,
        ],
      ),
    );
  }
}
