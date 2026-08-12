import 'package:flutter/material.dart';

import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import 'before_after_lines.dart';

/// Une priorite de travail, rendue comme la carte « focus » de la maquette :
/// **un constat, une reecriture**, et la technique en repli.
///
/// Ce que le correcteur ecrit dans `comment` est utile mais long — jusqu'a huit
/// lignes de consignes imbriquees. Affiche a plat, ce pave etait le plus gros
/// bloc de texte du rapport et faisait fuir la seule chose vraiment actionnable
/// juste en dessous : la phrase reecrite. Il est donc **borne a deux lignes**,
/// avec un geste pour le lire en entier. Rien n'est retire.
///
/// Une evaluation anterieure ne porte qu'une chaine : la carte se reduit alors
/// au constat, sans encadre vide ni bouton mort.
class PriorityCard extends StatefulWidget {
  const PriorityCard({
    super.key,
    required this.priorite,
    required this.rang,
    required this.total,
    this.embedded = false,
  });

  final PointAAmeliorer priorite;

  /// Rang affiche (1, 2) : deux priorites classees, pas un inventaire.
  final int rang;

  /// Nombre total de priorites : une seule se dit « 1 chose à corriger en
  /// priorité » (l'etiquette de la maquette), deux se numerotent.
  final int total;

  /// Rendue **dans** le bandeau « À corriger en priorité » : plus de carte
  /// ambre ni d'etiquette, puisque le bandeau qui l'ouvre les porte deja. Une
  /// carte dans une carte et un titre repete deux fois, c'est exactement la
  /// redite que le rapport corrige.
  final bool embedded;

  @override
  State<PriorityCard> createState() => _PriorityCardState();
}

class _PriorityCardState extends State<PriorityCard> {
  bool _open = false;

  String get _tag => widget.total == 1
      ? '1 chose à corriger en priorité'
      : 'Priorité ${widget.rang} sur ${widget.total}';

  @override
  Widget build(BuildContext context) {
    final priorite = widget.priorite;
    final comment = priorite.comment;
    final exemple = priorite.exemple;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              _tag,
              style: AppFonts.ui(
                size: 11.5,
                weight: FontWeight.w800,
                color: AppColors.amberDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ] else if (widget.total > 1) ...[
          Text(
            'PRIORITÉ ${widget.rang}',
            style: AppFonts.label(size: 10, color: AppColors.red),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          priorite.constat,
          style: AppFonts.display(
            size: widget.embedded ? 15.5 : 17,
            weight: FontWeight.w700,
            color: AppColors.ink,
          ).copyWith(height: 1.3),
        ),
        if (comment != null) ...[
          const SizedBox(height: 7),
          Text(
            comment,
            maxLines: _open ? null : 2,
            overflow: _open ? null : TextOverflow.ellipsis,
            style: AppFonts.ui(size: 13.5, color: AppColors.ink2, height: 1.45),
          ),
          _MoreLink(
            open: _open,
            onTap: () => setState(() => _open = !_open),
          ),
        ],
        if (exemple != null) ...[
          const SizedBox(height: 12),
          _RewriteBox(exemple: exemple, embedded: widget.embedded),
        ],
      ],
    );

    if (widget.embedded) return content;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.amberLight.withValues(alpha: 0.55),
            AppColors.amberLight,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.45)),
      ),
      child: content,
    );
  }
}

class _MoreLink extends StatelessWidget {
  const _MoreLink({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          open ? 'Réduire' : 'Comment faire',
          style: AppFonts.ui(
            size: 12,
            weight: FontWeight.w800,
            color: AppColors.blue,
          ),
        ),
      ),
    );
  }
}

/// La demonstration sur SA phrase : deux lignes, l'ancienne barree, la nouvelle
/// en vert. C'est le bloc le plus court du rapport et le plus utile — il ne se
/// replie jamais.
class _RewriteBox extends StatelessWidget {
  const _RewriteBox({required this.exemple, this.embedded = false});

  final ExempleReecriture exemple;

  /// Dans le bandeau rouge, le liseré de la boîte suit le bandeau — un filet
  /// ambre y jurerait.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: (embedded ? AppColors.red : AppColors.amber)
              .withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVANT → APRÈS',
            style: AppFonts.label(size: 9.5, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          BeforeAfterLines(
            avant: exemple.avant,
            apres: exemple.apres,
          ),
        ],
      ),
    );
  }
}
