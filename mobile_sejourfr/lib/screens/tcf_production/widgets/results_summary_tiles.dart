import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import 'priority_card.dart';

/// Les deux réponses que le candidat cherche juste après sa note : **ce qui
/// marche** et **ce qu'il faut corriger**.
///
/// Deux bandeaux pleine largeur, empilés, **repliés par défaut** : sur une
/// ligne chacun, le rapport annonce son verdict positif et son verdict négatif
/// sans imposer une seule phrase de lecture. Le détail — points traités, points
/// forts, priorité complète avec sa technique et sa réécriture — s'ouvre en
/// dessous, dans le même encart.
///
/// C'est aussi ce qui supprime la dernière redite du rapport : la priorité
/// n'était résumée en haut que pour être répétée en entier plus bas. Elle vit
/// désormais **à un seul endroit**, ici.
///
/// ⚠️ **La check-list de la consigne vit ici, et nulle part ailleurs** (depuis
/// le retrait de « Voir l'analyse complète », contrat v15/v9) : le dépliant
/// montre les points **traités** puis les points **oubliés**. Sans ces
/// derniers, le candidat lisait « 2/3 points traités » sans jamais savoir
/// lequel manquait — or c'est exactement ce qui lui coûte des points. Les
/// pistes non abordées, elles, ne coûtent rien et ne sont plus rendues.
class ResultsSummaryTiles extends StatelessWidget {
  const ResultsSummaryTiles({
    super.key,
    required this.accomplissement,
    required this.priorites,
    required this.pointsForts,
  });

  final Accomplissement? accomplissement;
  final List<PointAAmeliorer> priorites;
  final List<String> pointsForts;

  /// Points **obligatoires** traités / demandés. Les pistes sont exclues des
  /// deux côtés : ne pas traiter une piste n'enlève aucun point, l'inclure au
  /// dénominateur ferait lire « 3/5 » à une consigne entièrement remplie.
  ({int done, int total, List<String> libelles, List<String> oublies})?
      get _points {
    final data = accomplissement;
    if (data == null) return null;
    final traites = data.pointsTraites.where((p) => p.obligatoire).toList();
    final manques = data.manques;
    final total = traites.length + manques.length;
    if (total == 0) return null;
    return (
      done: traites.length,
      total: total,
      libelles: traites.map((p) => p.libelle).toList(),
      oublies: manques.map((p) => p.libelle).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = _points;
    final hasPositif = points != null || pointsForts.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasPositif)
          _SummaryTile(
            tone: AppColors.green,
            background: AppColors.greenLight,
            icon: LucideIcons.circleCheck,
            title: 'Ce qui marche',
            value: points == null
                ? (pointsForts.length > 1
                    ? '${pointsForts.length} points forts'
                    : '1 point fort')
                : '${points.done}/${points.total} points traités',
            detail: [
              if (points != null && points.libelles.isNotEmpty)
                _Bullets(items: points.libelles, tone: AppColors.green),
              // Le compteur dit « 2/3 » : sans cette liste, le candidat ne
              // saurait jamais QUEL point manque. Un titre est ici necessaire —
              // sans lui, un manque se lirait comme une reussite de plus.
              if (points != null && points.oublies.isNotEmpty) ...[
                if (points.libelles.isNotEmpty) const SizedBox(height: 12),
                Text(
                  'Points oubliés',
                  style: AppFonts.ui(
                    size: 12,
                    weight: FontWeight.w800,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(height: 7),
                _Bullets(items: points.oublies, tone: AppColors.red),
              ],
              // Un filet, pas un titre : ce qui a ete demande d'un cote, ce que
              // la langue reussit de l'autre — deux natures, une seule liste
              // les melangeait.
              if (points != null &&
                  (points.libelles.isNotEmpty || points.oublies.isNotEmpty) &&
                  pointsForts.isNotEmpty) ...[
                const SizedBox(height: 11),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.green.withValues(alpha: 0.22),
                ),
                const SizedBox(height: 11),
              ],
              if (pointsForts.isNotEmpty)
                _Bullets(items: pointsForts, tone: AppColors.green),
            ],
          ),
        if (priorites.isNotEmpty)
          _SummaryTile(
            // Le rouge est demandé ici, et il est juste : c'est le seul bloc du
            // rapport qui dit « à refaire ». Il ne peint aucun niveau CECRL —
            // la règle « jamais de rouge sur un niveau » n'est pas en cause.
            tone: AppColors.red,
            background: AppColors.redLight,
            icon: LucideIcons.circleAlert,
            title: 'À corriger en priorité',
            value: priorites.length > 1
                ? '${priorites.length} priorités'
                : '1 priorité',
            detail: [
              for (final (index, priorite) in priorites.indexed) ...[
                if (index > 0) const SizedBox(height: 14),
                PriorityCard(
                  priorite: priorite,
                  rang: index + 1,
                  total: priorites.length,
                  embedded: true,
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// Un bandeau repliable : une ligne en tête, le détail en dessous, dans le même
/// encart teinté.
class _SummaryTile extends StatefulWidget {
  const _SummaryTile({
    required this.tone,
    required this.background,
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
  });

  final Color tone;
  final Color background;
  final IconData icon;
  final String title;

  /// Le chiffre qui tient dans la ligne d'en-tête (« 3/3 points traités »).
  final String value;

  final List<Widget> detail;

  @override
  State<_SummaryTile> createState() => _SummaryTileState();
}

class _SummaryTileState extends State<_SummaryTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final hasDetail = widget.detail.isNotEmpty;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.background,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: widget.tone.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap:
                  hasDetail ? () => setState(() => _open = !_open) : null,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 18, color: widget.tone),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.ui(
                          size: 14,
                          weight: FontWeight.w800,
                          color: widget.tone,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.value,
                      style: AppFonts.ui(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    if (hasDetail) ...[
                      const SizedBox(width: 4),
                      Icon(
                        _open
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 18,
                        color: widget.tone,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_open && hasDetail)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.detail,
              ),
            ),
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({required this.items, required this.tone});

  final List<String> items;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, item) in items.indexed)
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 9),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
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
      ],
    );
  }
}
