import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/models/skill_models.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/fixed_action_bar.dart';
import '../../core/widgets/pressable_card.dart';
import '../../core/widgets/screen_header.dart';
import '../plan/learning_plan_provider.dart';
import '../plan/plan_now_card.dart';
import '../plan/widgets/plan_epreuve_reco.dart';
import 'competences/competences_providers.dart';
import 'expression_labels.dart';
import 'production_nav.dart';
import 'tcf_production_module.dart';
import 'widgets/production_common.dart';
import 'widgets/task_palette.dart';

/// **Niveau 1 du parcours EE/EO** — maquette du propriétaire
/// `~/Desktop/sejourfr_ecrans/expression_ecran.png`.
///
/// Trois blocs : l'en-tête (« TCF IRN » / « Expression écrite » / « Votre
/// progression vers l'objectif B2 »), la carte **« Recommandé pour vous »**,
/// puis **« Les 3 tâches »**. La barre fixe du bas mène aux **examens blancs**
/// (demande explicite du propriétaire) : ils portent sur l'épreuve entière,
/// jamais sur une tâche, et leur écran ne change pas d'un octet.
///
/// 🛑 **« Recommandé » VIENT DU PLAN, jamais du catalogue.**
/// [planEpreuveCarte] prend l'étape ouverte du **bloc de cette épreuve**, et le
/// tap fait exactement ce que ferait la même étape tapée depuis le Plan. **Aucun
/// repli** : bloc terminé ou action qui ne se résout pas ⇒ **la carte
/// disparaît**. Retomber sur « la première case libre » recommanderait autre
/// chose que le Plan.
///
/// 🛑 **Rien n'est compté ici.** « 3/8 compétences acquises » est de
/// l'arithmétique sur un `masteryState` **servi** ([acquisesLabel]), et le
/// dénominateur vient de la liste servie — jamais un 8 écrit en dur.
///
/// ⚠️ **Ce qui a quitté l'écran** (maquette) : la carte de synthèse de l'épreuve
/// et ses trois compteurs, les trois compteurs du pied de chaque tâche, et la
/// note pédagogique. Ils redisaient en chiffres ce que le sous-titre annonce, et
/// repoussaient les trois tâches sous la ligne de flottaison.
class ProductionTasksScreen extends ConsumerWidget {
  const ProductionTasksScreen({super.key, required this.module});

  final TcfProductionModule module;

  static const int _taches = 3;

  SkillSection get _section => module.isEo ? SkillSection.eo : SkillSection.ee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(userTargetLevelProvider);
    final skills = ref.watch(skillsSectionProvider(_section)).valueOrNull;
    // Le Plan est **déjà chargé** par l'Accueil et par Réviser : son échec
    // n'emporte pas l'écran, la carte de recommandation disparaît simplement.
    // 🛑 **L'étape du CYCLE pour cette épreuve**, la même que le Plan met en
    // tête (demande du propriétaire, 2026-09-20). ⚠️ Elle **remplace**
    // `recommandationDuPlan`, qui lisait les priorités : deux autorités pour la
    // même question, donc deux réponses possibles selon l'écran.
    final auth = ref.watch(authControllerProvider);
    final carte = planEpreuveCarte(
      ref.watch(learningPlanProvider).valueOrNull,
      ref.watch(journeyProvider).valueOrNull,
      module.epreuve.wire,
      free: !(auth is AuthAuthenticated && auth.user.hasTcf),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              eyebrow: 'TCF IRN',
              title: module.title,
              // 🛑 L'objectif est celui de la DÉMARCHE du candidat, servi. Sans
              // démarche déclarée, la ligne disparaît — on ne devine pas un
              // palier à sa place.
              sub: progressionVersObjectif(level?.wire),
              onBack: () => leaveProductionEpreuve(context),
            ),
            Expanded(
              child: RefreshIndicator(
                color: module.accent,
                onRefresh: () async {
                  invalidateSkillsSection(ref, _section);
                  ref.invalidate(learningPlanProvider);
                  await ref.read(skillsSectionProvider(_section).future);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  children: [
                    PlanEpreuveReco(
                      blocCode: module.epreuve.wire,
                      icon: module.isEo ? LucideIcons.mic : LucideIcons.penLine,
                    ),
                    Text(
                      'Les $_taches tâches',
                      style: AppFonts.ui(size: 17, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    for (var n = 1; n <= _taches; n++) ...[
                      _TaskCard(
                        module: module,
                        numero: n,
                        skills: _skillsOf(n, skills),
                        active:
                            carte?.step.taskCode?.wire == _section.taskCode(n),
                        onTap: () => context.push(productionTaskPath(module, n)),
                      ),
                      const SizedBox(height: 11),
                    ],
                  ],
                ),
              ),
            ),
            FixedActionBar(
              child: AppButton(
                label: 'Examens blancs',
                icon: LucideIcons.target,
                height: 52,
                onPressed: () => context.push(productionExamsPath(module)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Les compétences de la tâche, telles que servies. Liste vide tant que le
  /// référentiel n'est pas chargé : le compteur ne s'affiche alors pas du tout,
  /// plutôt que d'annoncer « 0/0 ».
  List<SkillDto> _skillsOf(int tache, List<SkillDto>? skills) {
    final code = _section.taskCode(tache);
    return skills?.where((s) => s.taskCode == code).toList() ?? const [];
  }
}

/// Ligne d'une tâche : rond numéroté, intitulé, « 3/8 compétences acquises »,
/// et la pastille d'état de la tâche.
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.module,
    required this.numero,
    required this.skills,
    required this.active,
    required this.onTap,
  });

  final TcfProductionModule module;
  final int numero;
  final List<SkillDto> skills;

  /// La tâche que le Plan recommande : son numéro est plein, pas teinté.
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (toneBg, toneFg) = taskPalette(numero);
    final badge = tacheBadge(skills);

    return PressableCard(
      onTap: onTap,
      radius: AppRadii.lg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.blue : toneBg,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                '$numero',
                style: AppFonts.display(
                  size: 17,
                  color: active ? AppColors.white : toneFg,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productionTaskLabeledTitle(module, numero),
                    style: AppFonts.ui(size: 15.5, weight: FontWeight.w800),
                  ),
                  if (skills.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      acquisesLabel(skills),
                      style: AppFonts.ui(
                        size: 13.5,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (badge != null)
              ExpressionStateBadge(label: badge)
            else
              const Icon(
                LucideIcons.chevronRight,
                size: 17,
                color: AppColors.inkFaint,
              ),
          ],
        ),
      ),
    );
  }
}
