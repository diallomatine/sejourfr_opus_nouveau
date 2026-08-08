import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Carte d'exercice de la maquette (`.exercise`) : carte blanche `radius 28`,
/// `padding 18`, ombre douce. En tête, la pastille de critère teintée de
/// l'accent (bleu à l'écrit, rouge à l'oral) et, à droite, le repère de
/// progression « Sujet i/N ». Puis le titre d'intention, la consigne, le
/// contexte et les contraintes.
///
/// Même carte des deux côtés : l'écrit et l'oral affichent le même exercice,
/// seule la zone de production en dessous change (saisie ou enregistreur).
///
/// Les variantes compactes (écrans d'enregistrement et de fin, où la consigne
/// a déjà été lue) passent simplement [maxLines].
class ConsigneCard extends StatelessWidget {
  const ConsigneCard({
    super.key,
    required this.consigne,
    this.title = 'Consigne',
    this.subtitle,
    this.subTitleHero,
    this.accent = AppColors.blue,
    this.soft = AppColors.blueLight,
    this.maxLines,
    this.step,
    this.contexte,
    this.requirements = const [],
  });

  final String consigne;

  /// Libellé de la pastille de tête (`.criterion` du prototype).
  final String title;

  /// Phrase de contrainte affichée sous le titre d'intention.
  final String? subtitle;

  /// Titre d'intention de l'exercice (`h2` du prototype).
  final String? subTitleHero;

  final Color accent;

  /// Teinte de remplissage de la pastille de tête.
  final Color soft;

  final int? maxLines;

  /// Repère de progression du prototype (`.step`, « Sujet 2/5 »). Absent quand
  /// l'écran ne sait pas où il se situe — on n'invente pas de rang.
  final String? step;

  /// Contexte du sujet (`.context`), rendu dans son encadré propre.
  final String? contexte;

  /// Contraintes de l'exercice (`.requirements`), déjà formatées.
  final List<String> requirements;

  @override
  Widget build(BuildContext context) {
    final heading = subTitleHero;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: _Pill(
                  label: title.toUpperCase(),
                  background: soft,
                  foreground: accent,
                ),
              ),
              if (step != null) ...[
                const SizedBox(width: 10),
                _Pill(
                  label: step!,
                  background: AppColors.surface2,
                  foreground: AppColors.inkSoft,
                ),
              ],
            ],
          ),
          if (heading != null && heading.isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(heading, style: AppFonts.display(size: 20, height: 1.26)),
          ],
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              subtitle!,
              style: AppFonts.ui(
                size: 12,
                height: 1.48,
                color: AppColors.inkSoft,
              ),
            ),
          ],
          SizedBox(height: heading == null ? 13 : 11),
          Text(
            consigne,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
            style: AppFonts.ui(size: 14.5, weight: FontWeight.w500, height: 1.5),
          ),
          if (contexte != null && contexte!.isNotEmpty) ...[
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTEXTE',
                    style: AppFonts.label(size: 10, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    contexte!,
                    style: AppFonts.ui(size: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
          if (requirements.isNotEmpty) ...[
            const SizedBox(height: 11),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final r in requirements)
                  _Pill(
                    label: r,
                    background: AppColors.surface2,
                    foreground: AppColors.inkSoft,
                    bordered: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Pilule du prototype (`.criterion`, `.step`, `.requirement`).
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    this.bordered = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: bordered ? Border.all(color: AppColors.line) : null,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppFonts.ui(
          size: 10,
          weight: FontWeight.w900,
          color: foreground,
        ),
      ),
    );
  }
}
