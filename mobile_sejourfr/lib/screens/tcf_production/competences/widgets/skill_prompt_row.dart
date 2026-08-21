import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/skill_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_lock.dart';
import 'skill_status_badge.dart';

/// La liste des petits sujets d'une compétence : **une carte, des lignes**.
///
/// La maquette groupe les sujets dans un seul encart séparé par des filets, au
/// lieu d'empiler quinze cartes autonomes. Ce n'est pas qu'une question de
/// densité : une carte par sujet donnait à chacun le poids d'un écran, alors
/// qu'ils se lisent en série — on cherche « où j'en suis dans la série », pas
/// « que vaut ce sujet-ci ».
///
/// Le filet est indenté à gauche de la pastille (15 de marge + 28 de pastille +
/// 10 d'écart) pour s'aligner sur le texte, comme `ListGroup`.
class SkillPromptGroup extends StatelessWidget {
  const SkillPromptGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.only(left: 53),
                child: Divider(height: 1, thickness: 1, color: AppColors.line2),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Une ligne de petit sujet : pastille d'état, titre, critère du sujet, statut.
///
/// La **pastille dit l'état par sa forme** — coche sur un sujet validé, flèche
/// de reprise sur un sujet à renforcer, numéro sur un sujet jamais traité :
/// c'est le repère que la maquette substitue au liseré vertical de l'ancienne
/// carte, qui ne repérait plus rien dès qu'on empilait les statuts.
///
/// Un sujet **verrouillé** (`prompt.locked`, calculé serveur) reste dans la
/// liste, à sa place, **entièrement lisible** — titre, critère, numéro — et
/// c'est le cadenas ([PremiumLockPill]) qui prend la place du statut. Le tap
/// mène à l'offre, décidé par l'appelant.
///
/// 🛑 **Rien n'est flouté ici, et c'est une règle écrite du module** : sur les
/// Compétences, un contenu verrouillé « reste affiché et lisible (titre, état,
/// compteurs) ». Le flou du produit est réservé à **deux** surfaces du Plan
/// (les lignes de la séance et celles de « Mes priorités ») ; l'étendre par
/// symétrie est explicitement interdit — d'autant que la carte « Prochain
/// sujet recommandé » et l'exercice recommandé du Plan nomment déjà ces
/// sujets en clair.
class SkillPromptRow extends StatelessWidget {
  const SkillPromptRow({
    super.key,
    required this.prompt,
    required this.accent,
    required this.onTap,
    this.highlighted = false,
  });

  final SkillPromptSummary prompt;
  final Color accent;
  final VoidCallback onTap;

  /// Le sujet que l'écran propose de faire maintenant : fond légèrement teinté,
  /// pastille à l'accent du module. Aucun autre effet — la carte de
  /// recommandation, au-dessus, porte déjà l'action.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          prompt.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.ui(size: 14.5, weight: FontWeight.w700, height: 1.25),
        ),
        if (prompt.uniqueCriterion.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            prompt.uniqueCriterion,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.ui(
              size: 12,
              color: AppColors.inkFaint,
              height: 1.35,
            ),
          ),
        ],
      ],
    );

    return Material(
      color: highlighted ? AppColors.surface2 : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
          child: Row(
            children: [
              _StatusChip(
                prompt: prompt,
                accent: accent,
                highlighted: highlighted,
              ),
              const SizedBox(width: 10),
              Expanded(child: text),
              const SizedBox(width: 10),
              if (prompt.locked)
                const PremiumLockPill()
              else
                SkillStatusBadge(status: prompt.status),
            ],
          ),
        ),
      ),
    );
  }
}

/// La pastille de tête d'une ligne : 28×28, ronde, teintée du statut.
///
/// `skill_status_badge.dart` reste **le seul** endroit qui décide de la teinte
/// d'un statut : on ne fait ici que la reprendre. Un sujet jamais traité porte
/// son **numéro** (il situe dans la série), les autres portent le glyphe de
/// leur statut.
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.prompt,
    required this.accent,
    required this.highlighted,
  });

  final SkillPromptSummary prompt;
  final Color accent;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final treated = prompt.status.isTreated;
    // `amber` est un ambre de remplissage : sur un glyphe il passe, sur du
    // texte jamais — d'où `amberDark` pour le chiffre et l'icône.
    final tone = treated
        ? (prompt.status == SkillPromptStatus.toReinforce
            ? AppColors.amberDark
            : skillStatusColor(prompt.status))
        : (highlighted ? accent : AppColors.inkFaint);
    final background = treated || highlighted
        ? tone.withValues(alpha: 0.12)
        : AppColors.surface2;

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: treated
          ? Icon(_glyph(prompt.status), size: 14, color: tone)
          : Text(
              '${prompt.displayOrder}',
              style: AppFonts.display(
                size: 12.5,
                weight: FontWeight.w800,
                color: tone,
              ),
            ),
    );
  }

  static IconData _glyph(SkillPromptStatus status) => switch (status) {
        SkillPromptStatus.validated => LucideIcons.check,
        SkillPromptStatus.toReinforce => LucideIcons.refreshCw,
        SkillPromptStatus.treated => LucideIcons.check,
        SkillPromptStatus.todo => LucideIcons.circleDashed,
      };
}
