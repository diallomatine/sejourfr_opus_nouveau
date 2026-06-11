import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'exam_number_badge.dart';
import 'exam_pill.dart';
import 'exam_slot_action.dart';

/// Carte d'un slot d'examen blanc — utilisée par les pages Examens des hubs
/// QCM (CO/CE/Structure) et des hubs EE/EO.
///
/// La carte rend un layout fixe : badge numéroté à gauche, titre + chips au
/// centre, bouton d'action à droite. Le caller fournit toutes les variations
/// (couleur d'accent du badge selon la difficulté, libellé du pill, widget
/// d'état facultatif pour l'état « terminé »).
///
/// - [badgeBaseBg]/[badgeBaseFg] : couleurs du badge à l'état neutre. EE/EO
///   utilise une palette difficulté (vert/gris/rouge), QCM passe
///   `blueLight`/`blue` pour rester sobre.
/// - [primaryPill] : chip principal (durée pour QCM, niveau de difficulté
///   pour EE/EO).
/// - [secondaryStatus] : widget facultatif à droite du pill (badge score
///   pour les slots terminés, label « À FAIRE ENSUITE » pour le slot next,
///   sous-titre « 3 tâches enchaînées » par défaut côté EE/EO).
class ExamSlotCard extends StatelessWidget {
  const ExamSlotCard({
    super.key,
    required this.slot,
    required this.done,
    required this.isNext,
    required this.isLocked,
    required this.badgeBaseBg,
    required this.badgeBaseFg,
    required this.title,
    required this.primaryPill,
    required this.onTap,
    required this.onAction,
    this.secondaryStatus,
    this.accent = AppColors.blue,
  });

  final int slot;
  final bool done;
  final bool isNext;
  final bool isLocked;
  final Color badgeBaseBg;
  final Color badgeBaseFg;
  final String title;
  final ExamSlotPill primaryPill;
  final Widget? secondaryStatus;
  final VoidCallback onTap;
  final VoidCallback onAction;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final highlighted = isNext && !done && !isLocked;
    return Opacity(
      opacity: isLocked ? 0.55 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: highlighted ? accent : AppColors.line,
            width: highlighted ? 1.2 : 1,
          ),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              child: Row(
                children: [
                  ExamNumberBadge(
                    number: slot,
                    locked: isLocked,
                    next: highlighted,
                    baseBg: badgeBaseBg,
                    baseFg: badgeBaseFg,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppFonts.ui(
                            size: 15,
                            weight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ExamPill(
                              label: primaryPill.label,
                              bg: primaryPill.bg,
                              fg: primaryPill.fg,
                            ),
                            if (secondaryStatus != null) secondaryStatus!,
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ExamSlotAction(
                    done: done,
                    next: highlighted,
                    locked: isLocked,
                    onPressed: onAction,
                    accent: accent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Description compacte du pill principal — façon plus lisible pour le caller.
class ExamSlotPill {
  const ExamSlotPill({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;
}
