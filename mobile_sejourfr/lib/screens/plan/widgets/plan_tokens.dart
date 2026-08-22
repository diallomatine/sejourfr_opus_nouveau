import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/skill_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_tag.dart';
import '../plan_labels.dart';

/// Les **primitives du Plan** : la pastille d'un domaine, la pilule de sa
/// priorité, le rail des paliers et les points d'une étape.
///
/// ⚠️ **Aucune teinte nouvelle.** Tout se peint avec `AppColors` / `TagTone`
/// existants : un même état ne doit pas changer de couleur d'un écran à
/// l'autre.
///
/// 🛑 **Les deux familles de domaines n'ont pas la même teinte** : la
/// **compréhension** (CO, CE) est bleue, l'**expression** (EO, EE) est rouge —
/// c'est la maquette du Plan, et c'est ce qui permet de distinguer d'un coup
/// d'œil « j'écoute / je lis » de « je parle / j'écris ». À ne pas confondre
/// avec l'accent du module « Compétences » (`TcfProductionModule.accent`), qui
/// est une autre surface et garde sa propre décision.

/// La pastille carrée d'un domaine : son icône, sur le fond clair de sa
/// famille. [filled] la remplit — réservé au domaine que le Plan traite en
/// priorité forte, pour qu'un seul élément de la liste attire l'œil.
class PlanDomainTile extends StatelessWidget {
  const PlanDomainTile({
    super.key,
    required this.epreuve,
    this.size = 38,
    this.filled = false,
  });

  /// `null` sur une ligne qui ne porte pas de domaine (un jalon complet, par
  /// exemple) : la pastille garde alors son icône générique plutôt que
  /// d'emprunter celle d'un domaine qu'on aurait deviné.
  final EpreuveType? epreuve;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    // Une ligne sans domaine (un jalon d'examen complet) reste bleue : elle ne
    // relève d'aucune des deux familles, on ne lui prête pas le rouge de
    // l'expression.
    final domain = epreuve;
    final expression =
        domain == null ? false : planDomainSection(domain)?.isProduction ?? false;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled
            ? (expression ? AppColors.red : AppColors.blue)
            : (expression ? AppColors.redLight : AppColors.blueLight),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Icon(
        planDomainIcon(epreuve),
        size: size * 0.52,
        color: filled
            ? AppColors.white
            : (expression ? AppColors.redDark : AppColors.blueDark),
      ),
    );
  }
}

/// Ton de pilule d'une priorité de domaine. **Dérivé, jamais une table de
/// couleurs de plus** : « priorité forte » se peint comme le statut
/// `PRIORITY` d'une compétence (rouge), « à travailler » comme un état bleu,
/// le reste reste neutre — un domaine qu'on n'a pas encore mesuré n'est pas un
/// domaine faible.
extension PlanDomainPriorityTone on PlanDomainPriority {
  TagTone get tone => switch (this) {
        PlanDomainPriority.forte => TagTone.red,
        PlanDomainPriority.aTravailler => TagTone.blue,
        PlanDomainPriority.entretien => TagTone.neutral,
        PlanDomainPriority.pasEncorePrioritaire => TagTone.neutral,
        PlanDomainPriority.aEvaluer => TagTone.ghost,
      };
}

/// La pilule de priorité d'un domaine. Le libellé est **gelé côté serveur**
/// (`PlanDomainPriority.getLabel()`), recopié dans l'enum : jamais une chaîne
/// écrite ici.
class PlanDomainPriorityTag extends StatelessWidget {
  const PlanDomainPriorityTag({
    super.key,
    required this.priority,
    this.compact = true,
  });

  final PlanDomainPriority priority;
  final bool compact;

  @override
  Widget build(BuildContext context) => AppTag(
        label: priority.label,
        tone: priority.tone,
        compact: compact,
      );
}

/// **Teinte et icône d'une nature d'action**, déclarées ici et nulle part
/// ailleurs.
///
/// ⚠️ **Aucune teinte nouvelle** : on reprend `TagTone` / `AppColors`
/// existants. Chaque nature a **sa** couleur, **son** icône et **son** libellé
/// — les quatre pilules ne peuvent pas se confondre à l'œil :
///
/// - « À évaluer » — **neutre**, une loupe : on ne sait pas, et *inconnu n'est
///   jamais mauvais* ;
/// - « À renforcer » — **ambre**, une clé à molette : c'est une réparation.
///   Même ton que `SkillMasteryState.toReinforce`, qui porte le même libellé —
///   voulu, ils disent la même chose ;
/// - « À vérifier » — **vert**, un badge coché : le travail est fait, il reste
///   à le prouver en situation ;
/// - « À acquérir » — **bleu**, une toque d'études : c'est un apprentissage
///   neuf.
///
/// 🛑 **« À acquérir » ne peut pas se lire « à renforcer »** : autre constante,
/// autre libellé (gelé serveur), autre teinte, autre icône, et une phrase
/// dédiée sur la carte (`kPlanAcquisitionNote`). Aucun chemin de code ne
/// traduit l'une en l'autre.
extension PlanActionNatureStyle on PlanActionNature {
  TagTone get tone => switch (this) {
        PlanActionNature.aEvaluer => TagTone.neutral,
        PlanActionNature.aRenforcer => TagTone.amber,
        PlanActionNature.aVerifier => TagTone.success,
        PlanActionNature.aAcquerir => TagTone.blue,
      };

  /// Pour les surfaces qui peignent un rang ou une bordure plutôt qu'une
  /// pilule. L'ambre **de texte** passe par `amberDark` : `amber` est un ambre
  /// de remplissage.
  Color get color => switch (this) {
        PlanActionNature.aEvaluer => AppColors.inkSoft,
        PlanActionNature.aRenforcer => AppColors.amberDark,
        PlanActionNature.aVerifier => AppColors.green,
        PlanActionNature.aAcquerir => AppColors.blue,
      };

  IconData get icon => switch (this) {
        PlanActionNature.aEvaluer => LucideIcons.search,
        PlanActionNature.aRenforcer => LucideIcons.wrench,
        PlanActionNature.aVerifier => LucideIcons.badgeCheck,
        PlanActionNature.aAcquerir => LucideIcons.graduationCap,
      };
}

/// La pilule de nature d'une entrée du Plan — **la pastille de la carte**.
///
/// Le libellé est **gelé côté serveur** (`PlanActionNature.getLabel()`),
/// recopié dans l'enum : jamais une chaîne écrite ici.
class PlanActionNatureTag extends StatelessWidget {
  const PlanActionNatureTag({
    super.key,
    required this.nature,
    this.compact = true,
  });

  final PlanActionNature nature;
  final bool compact;

  @override
  Widget build(BuildContext context) => AppTag(
        label: nature.label,
        tone: nature.tone,
        icon: nature.icon,
        compact: compact,
      );
}

/// **La pastille d'une tâche** : « Tâche 2 », teintée par son numéro.
///
/// Trois teintes qui **tournent** (tâche 1 bleue claire, 2 ambrée, 3 **bleu
/// plein**) : à l'intérieur d'une même épreuve, deux encarts voisins ne se
/// confondent pas. Ce n'est **pas** une sémantique — une tâche 3 n'est ni plus
/// urgente ni plus grave qu'une tâche 1, elle est juste plus loin dans
/// l'épreuve.
///
/// 🛑 **La 3ᵉ teinte n'est PAS rouge**, et ne doit jamais le redevenir. Deux
/// raisons : le Rouge France est réservé aux CTA critiques (charte), et une
/// carte d'expression porte **déjà** deux rouges de sens différents — la
/// pastille de domaine ([PlanDomainTile]) et le statut « Priorité »
/// ([PlanRowStatusStyle]). Trois rouges pour trois choses, l'œil ne distingue
/// plus rien. La maquette, elle, prend un violet : nos tokens n'en ont pas, et
/// on n'en fabrique pas.
///
/// La 3ᵉ se distingue donc par le **remplissage**, pas par la teinte — les deux
/// autres familles claires disponibles sont déjà prises ailleurs dans le même
/// en-tête (le vert est la coche « fait », le gris la pastille de contexte
/// « Niveau B1 »).
///
/// ⚠️ **Aucune teinte nouvelle** : les trois paires viennent d'`AppColors`.
class PlanTaskBadge extends StatelessWidget {
  const PlanTaskBadge({super.key, required this.task});

  final SkillTaskCode task;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch ((task.tacheNumero - 1) % 3) {
      0 => (AppColors.blueLight, AppColors.blueDark),
      1 => (AppColors.amberLight, AppColors.amberDark),
      _ => (AppColors.blue, AppColors.white),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        planTaskBadgeLabel(task),
        style: AppFonts.ui(size: 10.5, weight: FontWeight.w800, color: fg),
      ),
    );
  }
}

/// Le repère d'un encart **sans tâche** : « Niveau B1 », « Jalon ». Neutre —
/// il situe, il ne qualifie pas.
class PlanContextBadge extends StatelessWidget {
  const PlanContextBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surface3,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: AppFonts.ui(
            size: 10.5,
            weight: FontWeight.w800,
            color: AppColors.inkSoft,
          ),
        ),
      );
}

/// Teinte du statut d'une ligne de priorité.
///
/// ⚠️ **Aucune teinte nouvelle** : les quatre natures reprennent
/// [PlanActionNatureStyle.tone] à l'identique — un même mot ne peut pas changer
/// de couleur d'un écran à l'autre —, « Priorité » prend le rouge des statuts
/// bloquants et « Solide » le vert des acquis, exactement comme
/// [LearningPlanSkillStatusColor].
extension PlanRowStatusStyle on PlanRowStatus {
  TagTone get tone => switch (this) {
        PlanRowStatus.priorite => TagTone.red,
        PlanRowStatus.solide => TagTone.success,
        PlanRowStatus.aRenforcer => PlanActionNature.aRenforcer.tone,
        PlanRowStatus.aAcquerir => PlanActionNature.aAcquerir.tone,
        PlanRowStatus.aVerifier => PlanActionNature.aVerifier.tone,
        PlanRowStatus.aEvaluer => PlanActionNature.aEvaluer.tone,
      };
}

/// La pastille de statut d'une ligne de priorité. « À acquérir » y porte son
/// palier cible (« À acquérir · B1 ») : c'est le seul statut qui désigne un
/// palier à venir plutôt qu'un constat.
class PlanRowStatusTag extends StatelessWidget {
  const PlanRowStatusTag({super.key, required this.status, this.level});

  final PlanRowStatus status;
  final TargetLevel? level;

  @override
  Widget build(BuildContext context) => AppTag(
        label: planRowStatusLabel(status, level),
        tone: status.tone,
        compact: true,
      );
}

/// Le rail des paliers `A2 → B1 → B2`, avec le palier courant en évidence.
///
/// [current] est **nullable** : tant que rien n'est mesuré, aucun point n'est
/// allumé — on ne place pas le candidat sur une échelle par défaut.
/// [onDark] est la variante posée sur le dégradé de la carte de priorité.
class PlanLevelRail extends StatelessWidget {
  const PlanLevelRail({super.key, required this.current, this.onDark = false});

  final TargetLevel? current;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    const levels = TargetLevel.values;
    final index = current == null ? -1 : levels.indexOf(current!);
    final reached = onDark
        ? AppColors.white.withValues(alpha: 0.95)
        : AppColors.blue;
    final empty = onDark
        ? AppColors.white.withValues(alpha: 0.28)
        : AppColors.surface3;
    final textOn = onDark ? AppColors.white : AppColors.ink;
    final textOff = onDark
        ? AppColors.white.withValues(alpha: 0.62)
        : AppColors.inkFaint;

    return Row(
      children: [
        for (var i = 0; i < levels.length; i++) ...[
          _RailDot(
            label: levels[i].wire,
            reached: i <= index,
            active: i == index,
            reachedColor: reached,
            emptyColor: empty,
            textColor: i <= index ? textOn : textOff,
            onDark: onDark,
          ),
          if (i < levels.length - 1)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: i < index ? reached : empty,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _RailDot extends StatelessWidget {
  const _RailDot({
    required this.label,
    required this.reached,
    required this.active,
    required this.reachedColor,
    required this.emptyColor,
    required this.textColor,
    required this.onDark,
  });

  final String label;
  final bool reached;
  final bool active;
  final Color reachedColor;
  final Color emptyColor;
  final Color textColor;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final size = active ? 11.0 : 8.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: reached ? reachedColor : emptyColor,
            shape: BoxShape.circle,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: onDark
                          ? AppColors.white.withValues(alpha: 0.22)
                          : AppColors.blueLight,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: AppFonts.ui(
            size: 12.5,
            weight: active ? FontWeight.w800 : FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

/// La note discrète de bas de bloc : une nuance, jamais une alerte.
class PlanNote extends StatelessWidget {
  const PlanNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          text,
          style: AppFonts.ui(size: 12, height: 1.5, color: AppColors.inkFaint),
        ),
      );
}

/// Le numéro d'un rang dans une liste ordonnée (priorités, chemin, étapes).
class PlanRankBadge extends StatelessWidget {
  const PlanRankBadge({
    super.key,
    required this.rank,
    this.tone = AppColors.inkFaint,
    this.icon,
    this.semanticsLabel,
    this.size = 24,
  });

  final int rank;
  final Color tone;
  final IconData? icon;
  final String? semanticsLabel;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: icon != null
            ? Icon(
                icon,
                size: size * 0.55,
                color: tone,
                semanticLabel: semanticsLabel,
              )
            : Text(
                '$rank',
                style: AppFonts.display(size: size * 0.5, color: tone),
              ),
      );
}
