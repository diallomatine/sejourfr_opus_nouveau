import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/models/civic_plan_models.dart';
import '../../core/models/dashboard_models.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/preparation_models.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/preparation_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dashboard_targets.dart';
import '../../core/utils/parcours_affiche.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../plan/civic_plan_provider.dart';
import '../plan/civic_serie_launcher.dart';
import '../plan/learning_plan_provider.dart';
import '../plan/plan_actions.dart';
import '../plan/plan_labels.dart';
import 'reviser_labels.dart';

/// **L'onglet « Réviser »** — la maquette du propriétaire
/// (`~/Desktop/sejourfr_ecrans/reviser_{tcf,civique}.png`), montée sur le KIT.
///
/// Trois blocs, et rien d'autre : l'en-tête et sa bascule de parcours, la carte
/// **« Reprendre là où vous vous êtes arrêté »**, puis la liste des cinq
/// épreuves (TCF) ou des cinq thèmes (civique).
///
/// 🛑 **« Reprendre » vient du PLAN** (demande du propriétaire, 2026-09-12) :
/// c'est la première ligne de la séance du jour côté TCF, la cible de rang 1
/// côté civique. Réviser ne tient aucun historique à lui — le Plan est
/// l'autorité, et les deux écrans ne peuvent donc pas désigner deux choses
/// différentes.
///
/// 🛑 **Sans diagnostic, pas de carte** — sur les deux parcours. Le plan n'est
/// pas disponible, il n'y a rien à reprendre, et une carte qui inventerait un
/// point de reprise mentirait. On lit **`prep.planDisponible`**, jamais
/// `etape` : c'est lui qui rend mot pour mot la condition du moteur.
///
/// 🛑 **Aucune phrase n'est composée ici** : elles vivent dans
/// `reviser_labels.dart`, miroir mot pour mot de `web_sejoufr/lib/reviser.ts`.
class ReviserScreen extends ConsumerStatefulWidget {
  const ReviserScreen({super.key});

  @override
  ConsumerState<ReviserScreen> createState() => _ReviserScreenState();
}

class _ReviserScreenState extends ConsumerState<ReviserScreen> {
  /// Le lancement en cours, pour ne pas démarrer deux fois la même reprise.
  bool _lancement = false;

  Future<void> _refresh() async {
    ref.invalidate(dashboardProvider);
    ref.invalidate(preparationProvider);
    await ref.read(dashboardProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    // 🛑 **Les DEUX parcours sont observés en permanence**, comme sur le Plan :
    // ces providers sont `autoDispose`, donc n'en observer qu'un laissait
    // l'autre se jeter à la bascule — et revenir dessus rappelait son endpoint
    // pour une réponse identique. La bascule ne coûte aucun appel.
    final dashboard = ref.watch(dashboardProvider);
    final plan = ref.watch(learningPlanProvider).valueOrNull;
    final civicPlan = ref.watch(civicPlanProvider).valueOrNull;
    final prep = ref.watch(preparationProvider).valueOrNull;

    // 🛑 **Le parcours affiché est celui de l'Accueil et du Plan**
    // ([parcoursCiviqueProvider]) : une seule mécanique, comme le `?module=`
    // du web. Un état local de plus aurait fini par montrer deux parcours
    // différents au même candidat selon l'écran.
    final civique = ref.watch(parcoursCiviqueProvider) ?? false;
    final module = civique ? AppModule.civique : AppModule.tcf;

    final toggle = Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            reviserSubtitle(module),
            style: AppFonts.ui(size: 13.5, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          SegmentedTabs<bool>(
            tabs: parcoursSegments(tcf: false, civique: true),
            value: civique,
            onChanged: (v) =>
                ref.read(parcoursCiviqueProvider.notifier).state = v,
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: SfTopSlot(
          below: toggle,
          child: RefreshIndicator(
            color: AppColors.blue,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                const SfTop(title: kReviserTitle),
                ...dashboard.when(
                  loading: () => const [_Loading()],
                  error: (e, _) => [
                    _ErrorCard(
                      message: ApiClient.toApiException(e).message,
                      onRetry: () => ref.invalidate(dashboardProvider),
                    ),
                  ],
                  data: (d) => civique
                      ? _civique(d, civicPlan, prep?.civique)
                      : _tcf(d, plan, prep?.tcf),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* ------------------------------------------------------------------ TCF */

  List<Widget> _tcf(
    DashboardSummary dashboard,
    LearningPlan? plan,
    ModulePreparation? prep,
  ) {
    // 🛑 `planDisponible` est **le fait à lire**. Sans lui, on n'a rien à
    // reprendre — et on ne l'invente pas.
    final resume = prep?.planDisponible == true ? reviserResumeTcf(plan) : null;
    final stats = orderedTcfCategories(dashboard.tcf);
    final complementaire = complementaireCategory(dashboard.tcf);
    return <Widget>[
      if (resume != null)
        _ResumeCard(
          resume: resume,
          // L'icône du domaine, la même que sur le Plan et sur son hub — le
          // candidat doit reconnaître ce qu'il reprend.
          icon: planDomainIcon(sectionEpreuve(resume.section)),
          variant: SfButtonVariant.primary,
          onContinue: () => _reprendreTcf(resume),
        ),
      SfSection(
        title: reviserSectionTitle(AppModule.tcf, stats.length),
        flush: true,
        child: SfStack(
          pad: false,
          children: [
            for (final stat in stats)
              _epreuveRow(stat, domainForCode(plan, stat.code)),
          ],
        ),
      ),
      // 🛑 Structure de la langue n'est PAS une cinquième épreuve du TCF IRN :
      // elle sort de la liste et prend sa propre section, avec la note qui le
      // dit. Miroir web : ReviserScreen, section « Renforcer mon français ».
      if (complementaire != null)
        SfSection(
          title: kTcfComplementaireSectionTitle,
          flush: true,
          child: SfStack(
            pad: false,
            children: [
              _epreuveRow(complementaire, null),
              const SfNoteCard(
                icon: LucideIcons.info,
                title: kTcfComplementaireNoteTitle,
                child: Text(kTcfComplementaireNoteReviser),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _epreuveRow(DashboardCategoryStat stat, PlanDomain? domain) {
    return SfEpreuveRow(
      icon: dashboardCategoryIcon(stat.code),
      title: stat.label,
      status: epreuveStatus(stat, domain),
      meta: epreuveMeta(stat, domain),
      ratio: epreuveRatio(stat, domain),
      onTap: () => context.push(dashboardCategoryRoute(stat)),
    );
  }

  /// Lance ce que le Plan désigne — le **même** geste que le bouton principal
  /// du Plan (`startPlanSeanceItem` / `openPlanExercise`), jamais un second
  /// chemin écrit ici.
  Future<void> _reprendreTcf(ReviserResume resume) async {
    if (_lancement) return;
    setState(() => _lancement = true);
    final item = resume.item;
    if (item != null) {
      await startPlanSeanceItem(context, ref, item);
    } else {
      final exercise =
          ref.read(learningPlanProvider).valueOrNull?.currentPriority;
      final recommended = exercise?.recommendedExercise;
      if (recommended != null && mounted) {
        await openPlanExercise(
          context,
          ref,
          recommended,
          masteryBefore: exercise?.masteryState,
        );
      }
    }
    if (!mounted) return;
    setState(() => _lancement = false);
  }

  /* -------------------------------------------------------------- Civique */

  List<Widget> _civique(
    DashboardSummary dashboard,
    CivicPlan? civicPlan,
    ModulePreparation? prep,
  ) {
    final prochaine =
        prep?.planDisponible == true ? civicPlan?.prochaine : null;
    final resume = reviserResumeCivique(prochaine);
    final themes = civicPlan?.themes ?? const <CivicPlanThemeLigne>[];
    return <Widget>[
      if (resume != null && prochaine != null)
        _ResumeCard(
          resume: resume,
          icon: dashboardCategoryIcon(prochaine.themeCode),
          variant: SfButtonVariant.blue,
          onContinue: () => _reprendreCivique(prochaine),
        ),
      SfSection(
        title: reviserSectionTitle(AppModule.civique, dashboard.civique.length),
        flush: true,
        child: SfStack(
          pad: false,
          children: [
            for (final stat in dashboard.civique)
              SfEpreuveRow(
                icon: dashboardCategoryIcon(stat.code),
                title: stat.label,
                status: themeStatus(themeLigneFor(themes, stat.themeId), stat),
                onTap: () => context.push(dashboardCategoryRoute(stat)),
              ),
          ],
        ),
      ),
    ];
  }

  Future<void> _reprendreCivique(CivicPlanCible cible) async {
    if (_lancement) return;
    setState(() => _lancement = true);
    await startCivicSerie(context, ref, cible);
    if (!mounted) return;
    setState(() => _lancement = false);
  }
}

/// **« Reprendre là où vous vous êtes arrêté »** — la carte de tête.
///
/// Même anatomie que la carte « À faire maintenant » du Plan : c'est la même
/// action, vue depuis un autre écran.
class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.resume,
    required this.icon,
    required this.variant,
    required this.onContinue,
  });

  final ReviserResume resume;

  /// Le pictogramme de ce qu'on reprend — le domaine côté TCF, le thème côté
  /// civique. Servi par l'appelant, qui seul sait de quoi il parle.
  final IconData icon;

  /// Rouge côté TCF, bleu côté civique — la sémantique de parcours du produit.
  final SfButtonVariant variant;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SfCard(
        variant: SfCardVariant.hero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SfLabel(kReviserResumeLabel),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(icon, size: 24, color: AppColors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resume.title,
                        style: AppFonts.display(
                          size: 18,
                          weight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      if (resume.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          resume.subtitle!,
                          style: AppFonts.ui(size: 13, color: AppColors.muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SfButton(
              label: kReviserResumeCta,
              variant: variant,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SfCard(
        child: Column(
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.ui(size: 13.5, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            SfButton(
              label: 'Réessayer',
              variant: SfButtonVariant.line,
              icon: null,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
