import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_date.dart';
import '../../../core/widgets/app_tag.dart';
import 'production_blocks.dart';
import 'tcf_note_scale.dart';

/// Cartes de liste du prototype. Même géométrie que la carte de compétence
/// (`.topic-card` : grille `48px 1fr auto`, `gap 12`, `padding 15`,
/// `radius 23`) — c'est ce qui fait que les niveaux du parcours se lisent
/// comme un seul écran.
///
/// `ProductionTaskCard` (la carte T1/T2/T3 du hub d'épreuve) vivait ici :
/// elle est supprimée avec le hub, le choix de tâche se faisant désormais par
/// `ProductionTaskPills`.

/// Carte d'un sujet TCF complet sur l'écran d'une tâche (`.topic-card`).
///
/// Pastille de numéro (ou ✓ quand le sujet est traité), titre, consigne,
/// contraintes réelles du sujet en badges, puis la colonne d'état du prototype
/// (`.topic-actions` : badge au-dessus, bouton rond en dessous). Le **liseré
/// vertical n'existe que si le sujet est traité** — même règle que les petits
/// sujets de compétence, un liseré permanent ne repérerait plus rien.
class ProductionSubjectCard extends StatelessWidget {
  const ProductionSubjectCard({
    super.key,
    required this.order,
    required this.task,
    required this.isOral,
    required this.accent,
    required this.last,
    required this.locked,
    required this.onTap,
  });

  /// Rang du sujet dans la tâche (1-based) : c'est le numéro de la pastille.
  final int order;
  final ProductionTaskDto task;
  final bool isOral;
  final Color accent;
  final ProductionSubmissionDto? last;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = last != null;
    final note = last?.evaluation?.noteSurVingt;

    // La couleur d'une note vient de son PALIER TCF (0 → A1 non atteint,
    // 1 → A1, 2-5 → A2, 6-9 → B1, 10-20 → B2), jamais d'un seuil scolaire sur
    // 20 : 12/20 est un B2. Tant que l'IA n'a pas rendu sa note, on reste sur
    // le vert « terminé ».
    final band = note == null ? null : TcfNoteScale.bandFor(note);
    final doneTone = band?.tone ?? AppColors.green;

    final chipForeground = locked
        ? AppColors.inkFaint
        : done
            ? doneTone
            : accent;
    final chipBackground = locked
        ? AppColors.surface2
        : done
            ? doneTone.withValues(alpha: 0.12)
            : accent.withValues(alpha: 0.10);

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: PressableCard(
        onTap: onTap,
        borderColor: done ? doneTone.withValues(alpha: 0.35) : null,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductionIndexChip(
                    order: order,
                    done: done,
                    foreground: chipForeground,
                    background: chipBackground,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.ui(
                            size: 15,
                            weight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.consigne,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.ui(
                            size: 12,
                            color: AppColors.inkSoft,
                            height: 1.38,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final chip in _metaChips()) chip,
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _statusBadge(band, note),
                      const SizedBox(height: 7),
                      _ActionDot(
                        icon: locked
                            ? LucideIcons.lock
                            : done
                                ? LucideIcons.refreshCw
                                : LucideIcons.play,
                        background: locked ? AppColors.surface2 : accent,
                        foreground:
                            locked ? AppColors.inkFaint : AppColors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (done)
              Positioned(
                left: 0,
                top: 17,
                bottom: 17,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: doneTone,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(5),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(TcfNoteBand? band, double? note) {
    if (locked) {
      return const AppTag(
        label: 'Abonnement',
        tone: TagTone.neutral,
        icon: LucideIcons.lock,
        compact: true,
      );
    }
    if (note != null) {
      return AppTag(
        label: '${formatScore(note)}/20',
        tone: band?.niveau.tagTone ?? TagTone.success,
        compact: true,
      );
    }
    if (last != null) {
      return const AppTag(
        label: 'Fait',
        tone: TagTone.success,
        icon: LucideIcons.check,
        compact: true,
      );
    }
    return const AppTag(label: 'À faire', tone: TagTone.neutral, compact: true);
  }

  /// Contraintes **réelles** du sujet, telles que servies par l'API : palier
  /// visé, puis la longueur (écrit) ou la durée (oral). Rien n'est affiché
  /// quand le champ est absent — pas de chiffre inventé.
  List<Widget> _metaChips() {
    final chips = <Widget>[];

    final niveau = NiveauCecrl.values
        .where((n) => n.wire == task.niveauCible)
        .firstOrNull;
    if (niveau != null) {
      chips.add(AppTag(
        label: niveau.shortName,
        tone: niveau.tagTone,
        compact: true,
      ));
    }

    final constraint = isOral ? _durationLabel() : _wordsLabel();
    if (constraint != null) {
      chips.add(AppTag(
        label: constraint,
        tone: TagTone.ghost,
        icon: isOral ? LucideIcons.clock : LucideIcons.type,
        compact: true,
      ));
    }
    return chips;
  }

  String? _wordsLabel() {
    final min = task.motsMin;
    final max = task.motsMax;
    if (min == null || max == null) return null;
    return '$min-$max mots';
  }

  String? _durationLabel() {
    final max = task.dureeMaxSec;
    if (max == null) return null;
    final minutes = max ~/ 60;
    final seconds = max % 60;
    if (minutes == 0) return '$max s';
    return seconds == 0 ? '$minutes min' : '$minutes min $seconds';
  }
}

/// Bouton rond du prototype (`.small-action`, 36×36).
class _ActionDot extends StatelessWidget {
  const _ActionDot({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: 16, color: foreground),
    );
  }
}
