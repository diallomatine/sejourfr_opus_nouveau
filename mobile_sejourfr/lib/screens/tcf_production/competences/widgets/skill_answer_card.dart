/// La carte « Ta réponse » d'un petit sujet.
///
/// **Une seule coque pour l'écrit et pour l'oral** : c'est ce qui garantit la
/// parité. Ce qui change entre les deux, c'est uniquement la zone de production
/// passée en `child` (champ de saisie ⇄ panneau d'enregistrement) et la donnée
/// affichée à droite du pied de carte (compteur de mots ⇄ durée).
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';

/// La teinte du pied de carte : le compteur dit **où on en est** de la cible.
///
/// Sans état « dans la cible », le candidat n'a que deux informations — neutre
/// ou trop long — et rien ne lui confirme qu'il est bon. Miroir du web
/// (`counterOk` / `counterWarn`).
enum SkillMetaTone {
  /// Rien n'a encore été produit : la cible ne veut rien dire.
  neutral,

  /// Dans la fourchette conseillée.
  inTarget,

  /// Hors fourchette (ou au-delà du plafond serveur) : on avertit, on ne
  /// bloque jamais.
  outOfTarget,
}

class SkillAnswerCard extends StatelessWidget {
  const SkillAnswerCard({
    super.key,
    required this.accent,
    required this.child,
    this.title = 'Ta réponse',
    this.icon = LucideIcons.penLine,
    this.tip,
    this.meta,
    this.metaTone = SkillMetaTone.neutral,
  });

  final Color accent;
  final Widget child;
  final String title;

  /// Le crayon à l'écrit, le micro à l'oral : l'icône dit l'épreuve.
  final IconData icon;

  /// L'astuce du sujet, **sans** le mot « Astuce : » — il est ajouté ici.
  /// `null` ⇒ le pied de carte n'affiche que [meta].
  final String? tip;

  /// Compteur de mots (écrit) ou durée (oral). `null` ⇒ pied de carte réduit
  /// à l'astuce.
  final String? meta;

  /// Teinte de [meta] : neutre, vert dans la cible, ambre hors cible.
  final SkillMetaTone metaTone;

  Color get _metaColor => switch (metaTone) {
        SkillMetaTone.neutral => AppColors.inkSoft,
        SkillMetaTone.inTarget => AppColors.green,
        // `amber` est un ambre de remplissage, illisible en lettres.
        SkillMetaTone.outOfTarget => AppColors.amberDark,
      };

  @override
  Widget build(BuildContext context) {
    final footer = tip != null || meta != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.ui(size: 14, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
          if (footer) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tip != null)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            LucideIcons.lightbulb,
                            size: 14,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Astuce : ${tip!}',
                            style: AppFonts.ui(
                              size: 11.5,
                              height: 1.4,
                              weight: FontWeight.w600,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                if (meta != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    meta!,
                    style: AppFonts.ui(
                      size: 11.5,
                      weight: FontWeight.w700,
                      color: _metaColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// La zone de saisie de l'écrit : un champ sobre dont le texte grisé est
/// l'**amorce** du sujet (`answerStarter`), qui donne l'élan sans donner la
/// réponse.
///
/// Volontairement distincte de `WritingZone` (le gros éditeur des sujets TCF
/// complets, avec ses stats, sa barre de progression et sa confirmation
/// d'effacement) : ici le compteur et l'astuce vivent dans le pied de la carte,
/// et tout ce qui s'ajouterait repousserait le champ sous la ligne de
/// flottaison.
class SkillWritingField extends StatefulWidget {
  const SkillWritingField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.accent,
    this.starter,
    this.minLines = 4,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Color accent;

  /// `null` ⇒ texte grisé neutre : jamais de champ muet, jamais de « null ».
  final String? starter;
  final int minLines;

  @override
  State<SkillWritingField> createState() => _SkillWritingFieldState();
}

class _SkillWritingFieldState extends State<SkillWritingField> {
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocusChanged);

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: focused ? widget.accent.withValues(alpha: 0.04) : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: focused ? widget.accent : AppColors.line,
          width: focused ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        onTapOutside: (_) => _focusNode.unfocus(),
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        textCapitalization: TextCapitalization.sentences,
        minLines: widget.minLines,
        maxLines: null,
        cursorColor: widget.accent,
        cursorWidth: 1.5,
        style: AppFonts.ui(size: 14.5, height: 1.55),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: widget.starter ?? 'Écris ta réponse ici…',
          hintStyle: AppFonts.ui(
            size: 14.5,
            height: 1.55,
            color: AppColors.muted2,
          ),
        ),
      ),
    );
  }
}

/// L'équivalent oral de l'amorce : une **suggestion de démarrage** posée
/// au-dessus du panneau d'enregistrement. Absente quand le sujet n'en porte pas.
class SkillStarterHint extends StatelessWidget {
  const SkillStarterHint({super.key, required this.starter});

  final String starter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Commence par : ',
              style: AppFonts.ui(
                size: 12,
                height: 1.45,
                weight: FontWeight.w800,
                color: AppColors.inkSoft,
              ),
            ),
            TextSpan(
              text: '« $starter »',
              style: AppFonts.ui(
                size: 12,
                height: 1.45,
                color: AppColors.muted2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
