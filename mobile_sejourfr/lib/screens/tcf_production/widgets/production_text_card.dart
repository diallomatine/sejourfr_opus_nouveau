import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

/// Ce que le candidat a rendu — et rien d'autre.
///
/// ⚠️ **La bascule « Voir la version améliorée » a été retiree (2026-08-08).**
/// `version_amelioree` reecrit la production au niveau **deja constate** :
/// c'etait le texte le plus visible et le plus copiable du rapport, et il ne
/// fait pas monter d'un palier. Un candidat l'a recopie tel quel, l'a resoumis,
/// et a obtenu **exactement la meme note et le meme niveau**. Le seul texte
/// modele de l'ecran est desormais celui du plan d'action
/// (`ProductionActionPlan`, `version_ciblee`), sous l'intertitre « Une version
/// plus aboutie ».
///
/// Le champ reste servi par l'API et decode dans `production_models.dart`
/// (aucun widget ne le lit) : le retirer du contrat imposerait une nouvelle
/// version de tool-schema sur la grille de notation.
///
/// Reste ici la seule chose qui aide a relire : le reperage de la phrase visee
/// par la priorite n° 1.
class ProductionTextCard extends StatefulWidget {
  const ProductionTextCard({
    super.key,
    required this.texte,
    this.highlight,
  });

  final String texte;

  /// Passage a surligner dans le texte rendu — la phrase que vise la priorite
  /// n° 1. Le reperage se fait sur la **premiere occurrence exacte** : si le
  /// correcteur a recompose la phrase, rien n'est surligne plutot que de
  /// designer le mauvais passage.
  final String? highlight;

  @override
  State<ProductionTextCard> createState() => _ProductionTextCardState();
}

class _ProductionTextCardState extends State<ProductionTextCard> {
  bool _reperes = true;

  @override
  Widget build(BuildContext context) {
    final hasHighlight = (widget.highlight ?? '').trim().isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HighlightedText(
            texte: widget.texte,
            highlight: _reperes ? widget.highlight : null,
          ),
          if (hasHighlight) ...[
            const SizedBox(height: 13),
            Align(
              alignment: Alignment.centerLeft,
              child: _ActionButton(
                label: _reperes ? 'Masquer les repères' : 'Afficher les repères',
                icon: _reperes ? LucideIcons.highlighter : LucideIcons.eye,
                onTap: () => setState(() => _reperes = !_reperes),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Le texte du candidat, avec la phrase visee par la priorite reperee au
/// surligneur. Sans correspondance exacte, on rend le texte tel quel : mieux
/// vaut aucun repere qu'un repere faux.
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({required this.texte, required this.highlight});

  final String texte;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final base =
        AppFonts.ui(size: 13.5, color: AppColors.ink, height: 1.6);
    final cible = highlight?.trim();
    final start =
        cible == null || cible.isEmpty ? -1 : texte.indexOf(cible);
    if (start < 0) return Text(texte, style: base);

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: texte.substring(0, start)),
          TextSpan(
            text: texte.substring(start, start + cible!.length),
            style: base.copyWith(
              backgroundColor: AppColors.amberLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: texte.substring(start + cible.length)),
        ],
      ),
    );
  }
}

/// L'action douce de `.actions` dans la maquette. Petite, elle n'ajoute aucune
/// ligne de texte a lire. La variante pleine servait a la version amelioree :
/// elle est partie avec elle.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blueLight,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppColors.blue),
              const SizedBox(width: 7),
              Text(
                label,
                style: AppFonts.ui(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
