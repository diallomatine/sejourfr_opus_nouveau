import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/skill_models.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/fixed_action_bar.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/pressable_card.dart';
import '../../core/widgets/screen_header.dart';
import '../plan/learning_plan_provider.dart';
import 'competences/competences_nav.dart';
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
/// [recommandationDuPlan] lit la séance du jour, puis la priorité n°1, puis les
/// suivantes — dans l'ordre où le serveur les range. **Aucun repli** : le Plan
/// classant les quatre domaines par urgence, un candidat dont la priorité est
/// en compréhension n'a rien à recommander ici et **la carte disparaît**.
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
    final plan = ref.watch(learningPlanProvider).valueOrNull;
    final reco = recommandationDuPlan(plan, _section);

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
                    if (reco != null) ...[
                      _RecoCard(module: module, reco: reco),
                      const SizedBox(height: 20),
                    ],
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
                        active: reco?.taskCode == _section.taskCode(n),
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

/// La carte « Recommandé pour vous ».
///
/// 🛑 **Verrouillée, elle reste DÉSIGNÉE** : la compétence garde son nom, et
/// c'est l'action qui ouvre l'offre. On ne masque jamais un constat — le Plan a
/// déjà choisi de nommer cette priorité.
class _RecoCard extends ConsumerWidget {
  const _RecoCard({required this.module, required this.reco});

  final TcfProductionModule module;
  final ExpressionRecommendation reco;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compteur = exercicesReussisLabel(reco.validated, reco.total);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.redLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              kExpressionRecommendedLabel,
              style: AppFonts.ui(
                size: 12,
                weight: FontWeight.w700,
                color: AppColors.redDark,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Icon(module.icon, size: 24, color: AppColors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reco.title,
                      style: AppFonts.display(size: 19),
                    ),
                    if (reco.taskCode != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${tacheLabel(reco.taskCode!)} · ${module.title}',
                        style: AppFonts.ui(
                          size: 13,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (compteur != null) ...[
            const SizedBox(height: 14),
            Text(
              compteur,
              style: AppFonts.ui(size: 13.5, color: AppColors.inkFaint),
            ),
          ],
          const SizedBox(height: 14),
          AppButton(
            label: reco.locked
                ? 'Débloquer cette compétence'
                : kExpressionRecommendedCta,
            icon: reco.locked ? LucideIcons.lock : LucideIcons.arrowRight,
            height: 54,
            variant: reco.locked ? AppButtonVariant.primary : AppButtonVariant.danger,
            onPressed: () => reco.locked
                ? showPaywallSheet(context, ref: ref)
                : context.push(
                    competenceDetailPath(module, reco.skillId, planStep: true),
                  ),
          ),
        ],
      ),
    );
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
