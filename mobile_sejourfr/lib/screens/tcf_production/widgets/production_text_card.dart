import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

/// Ce que le candidat a rendu, et — d'un bouton — la meme chose reecrite.
///
/// Les deux vivaient dans deux cartes eloignees : le texte soumis tout en bas
/// de l'ecran, la version amelioree bien plus haut. Or c'est une **comparaison**
/// qu'on demande au candidat de faire ; il faut donc que les deux soient au
/// meme endroit, et qu'une seule s'affiche a la fois.
///
/// La version amelioree n'existe qu'en expression ECRITE (absente en EO par
/// contrat, pas par bug) : sans elle, la carte se reduit au texte rendu, sans
/// bouton mort.
class ProductionTextCard extends StatefulWidget {
  const ProductionTextCard({
    super.key,
    required this.texte,
    this.versionAmelioree,
    this.highlight,
  });

  final String texte;
  final String? versionAmelioree;

  /// Passage a surligner dans le texte rendu — la phrase que vise la priorite
  /// n° 1. Le reperage se fait sur la **premiere occurrence exacte** : si le
  /// correcteur a recompose la phrase, rien n'est surligne plutot que de
  /// designer le mauvais passage.
  final String? highlight;

  @override
  State<ProductionTextCard> createState() => _ProductionTextCardState();
}

class _ProductionTextCardState extends State<ProductionTextCard> {
  bool _improved = false;
  bool _reperes = true;

  @override
  Widget build(BuildContext context) {
    final version = widget.versionAmelioree;
    final hasVersion = version != null && version.isNotEmpty;
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
          if (hasVersion || hasHighlight) ...[
            const SizedBox(height: 13),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (hasVersion)
                  _ActionButton(
                    label: _improved
                        ? 'Masquer la version améliorée'
                        : 'Voir la version améliorée',
                    icon: _improved
                        ? LucideIcons.eyeOff
                        : LucideIcons.fileCheck,
                    primary: true,
                    onTap: () => setState(() => _improved = !_improved),
                  ),
                if (hasHighlight)
                  _ActionButton(
                    label: _reperes
                        ? 'Masquer les repères'
                        : 'Afficher les repères',
                    icon: LucideIcons.highlighter,
                    primary: false,
                    onTap: () => setState(() => _reperes = !_reperes),
                  ),
              ],
            ),
          ],
          if (hasVersion && _improved) ...[
            const SizedBox(height: 12),
            _ImprovedBox(texte: version),
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

/// Les deux actions de `.actions` dans la maquette : la pleine (version
/// ameliorée) et la douce (repères). Petites, cote a cote, elles n'ajoutent
/// aucune ligne de texte a lire.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? AppColors.white : AppColors.blue;
    return Material(
      color: primary ? AppColors.blue : AppColors.blueLight,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 7),
              Text(
                label,
                style:
                    AppFonts.ui(size: 12.5, weight: FontWeight.w800, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImprovedBox extends StatelessWidget {
  const _ImprovedBox({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VERSION AMÉLIORÉE',
            style: AppFonts.label(size: 9.5, color: AppColors.green),
          ),
          const SizedBox(height: 6),
          Text(
            'Vos idées, réécrites : les mêmes, dites autrement.',
            style: AppFonts.ui(size: 12, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            texte,
            style: AppFonts.ui(size: 13.5, color: AppColors.ink, height: 1.6),
          ),
        ],
      ),
    );
  }
}
