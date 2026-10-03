import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/router/shell_navigation.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../../core/theme/app_theme.dart';
import '../civique/civique_full_exams_screen.dart';
import '../module_detail/tcf_full_exams_screen.dart';
import '../plan/learning_plan_provider.dart';
import '../plan/plan_body.dart';
import '../reviser/reviser_body.dart';
import '../reviser/reviser_labels.dart';
import '../shell/main_shell.dart';
import 'module_labels.dart';

/// **L'écran d'un module** (Navigation v2) — racine de l'onglet TCF ou
/// Civique : en-tête de module, carte « Ma progression », puis le segment
/// **Plan | Entraînement | Examens** qui affiche le corps existant.
///
/// - Chaque segment est une sous-route (`/tcf/plan`, `/civique/examens`…) ;
///   les trois partagent la même page, donc changer de segment met à jour cet
///   écran sans transition et **remonte en haut** ([didUpdateWidget]).
/// - Le segment TCF actif est **blanc**, le segment civique actif **rouge**
///   (couleur du module).
/// - Les corps (`PlanBody`, `ReviserBody`, `TcfFullExamsView`,
///   `CiviqueFullExamsView`) n'ont ni en-tête ni bascule de module.
class ModuleScreen extends ConsumerStatefulWidget {
  const ModuleScreen({super.key, required this.civique, required this.segment});

  final bool civique;
  final ModuleSegment segment;

  @override
  ConsumerState<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends ConsumerState<ModuleScreen> {
  final ScrollController _scroll = ScrollController();

  /// L'onglet de ce module est-il celui qu'on voit ? Sert à tracer
  /// `PLAN_OPENED` à chaque affichage du Plan, retour d'onglet compris.
  bool _visible = false;

  ShellBranch get _branche =>
      widget.civique ? ShellBranch.civique : ShellBranch.tcf;

  @override
  void initState() {
    super.initState();
    _memoriserSegment();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final courant = ShellBrancheCourante.of(context);
    final visible = courant == null || courant == _branche.index;
    if (visible && !_visible) _tracerPlanOuvert();
    _visible = visible;
  }

  @override
  void didUpdateWidget(ModuleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segment == widget.segment) return;
    _memoriserSegment();
    if (_scroll.hasClients) _scroll.jumpTo(0);
    if (_visible) _tracerPlanOuvert();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Le segment d'origine, pour le lien retour d'une Progression ouverte
  /// depuis un autre onglet. Écrit après le cadre : un provider ne se modifie
  /// pas pendant la construction.
  void _memoriserSegment() {
    final segment = widget.segment;
    final civique = widget.civique;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(dernierSegmentProvider(civique).notifier).state = segment;
    });
  }

  /// Étape 5 du tunnel « Suivi » (« plan vu ») : l'affichage d'un segment
  /// Plan, avec le `journeyId` servi du parcours affiché — et rien d'autre.
  /// Parcours injoignable ⇒ l'événement part quand même, sans contexte.
  void _tracerPlanOuvert() {
    if (widget.segment != ModuleSegment.plan) return;
    // Un écran poussé au-dessus (Progression, étape…) cache le Plan : rien
    // n'est « vu » au retour sur l'onglet.
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    final civique = widget.civique;
    unawaited(() async {
      String? journeyId;
      try {
        final journey = await ref
            .read(civique
                ? journeyCiviqueProvider.future
                : journeyProvider.future)
            .timeout(const Duration(seconds: 10));
        journeyId = journey.journeyId;
      } catch (_) {
        journeyId = null;
      }
      if (!mounted) return;
      ref.read(analyticsServiceProvider).track(
            AnalyticsEvent.planOpened,
            path: AnalyticsPath.plan,
            journeyId: journeyId,
          );
    }());
  }

  @override
  Widget build(BuildContext context) {
    final civique = widget.civique;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          controller: _scroll,
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SfModuleHeader(
                      civique: civique,
                      kicker: civique ? kModuleCiviqueKicker : kModuleTcfKicker,
                      title: civique ? kModuleCiviqueTitle : kModuleTcfTitle,
                      lead: civique ? kModuleCiviqueLead : kModuleTcfLead,
                    ),
                    const SizedBox(height: 18),
                    civique
                        ? const _ProgressionCivique()
                        : const _ProgressionTcf(),
                    const SizedBox(height: 20),
                    SegmentedTabs<ModuleSegment>(
                      shape: SegmentedTabsShape.module,
                      value: widget.segment,
                      tabs: [
                        for (final segment in ModuleSegment.values)
                          SegmentTab(
                            value: segment,
                            label: moduleSegmentLabel(segment),
                            color: civique ? AppColors.moduleCivique : null,
                          ),
                      ],
                      onChanged: (segment) {
                        if (segment == widget.segment) return;
                        context.go(segment.path(civique: civique));
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
          body: KeyedSubtree(
            key: ValueKey(widget.segment),
            child: switch (widget.segment) {
              ModuleSegment.plan => PlanBody(civique: civique),
              ModuleSegment.entrainement => ReviserBody(civique: civique),
              ModuleSegment.examens => civique
                  ? const CiviqueFullExamsView()
                  : const TcfFullExamsView(),
            },
          ),
        ),
      ),
    );
  }
}

/// **« Ma progression » — TCF** : niveau actuel estimé (servi par le tableau de
/// bord) → niveau visé du compte (plancher de la démarche appliqué par
/// l'autorité `TargetProcedure.niveauVise`). Aucune valeur ⇒ « — ».
///
/// États du bloc (brief §7) : squelette tant que le tableau de bord n'est pas
/// lu, erreur + « Réessayer » s'il a échoué.
class _ProgressionTcf extends ConsumerWidget {
  const _ProgressionTcf();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableau = ref.watch(dashboardProvider);
    final etat = _etatDuBloc(ref, tableau);
    if (etat != null) return etat;
    final actuel = tableau.valueOrNull?.estimatedTcfLevel?.shortName;
    final cible = ref.watch(userTargetLevelProvider)?.wire;
    return SfProgressSummary(
      civique: false,
      label: kModuleProgressLabel,
      from: actuel ?? kModuleProgressUnknown,
      value: cible ?? kModuleProgressUnknown,
      meta: cible == null
          ? null
          : moduleTcfProgressMeta(cible, kTcfEpreuvesOfficielles.length),
      action: kModuleProgressAction,
      onTap: () => context.push(AppRoutes.progressionTcf),
    );
  }
}

/// **« Ma progression » — civique** : l'avancement en séries
/// ([avancementSeriesCivique], la fonction unique), et le nombre de séries
/// terminées. Mêmes états de bloc que la carte TCF.
class _ProgressionCivique extends ConsumerWidget {
  const _ProgressionCivique();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableau = ref.watch(dashboardProvider);
    final etat = _etatDuBloc(ref, tableau);
    if (etat != null) return etat;
    final themes = tableau.valueOrNull?.civique;
    final avancement = themes == null ? null : avancementSeriesCivique(themes);
    return SfProgressSummary(
      civique: true,
      label: kModuleProgressLabel,
      value: avancement == null
          ? kModuleProgressUnknown
          : moduleCiviqueProgressValue(avancement.pourcentage),
      meta: avancement == null
          ? null
          : moduleCiviqueProgressMeta(avancement.terminees),
      action: kModuleProgressAction,
      onTap: () => context.push(AppRoutes.progressionCivique),
    );
  }
}

/// Le squelette ou l'erreur de la carte « Ma progression », tant que le
/// tableau de bord n'a pas de valeur ; `null` dès qu'il en a une (une relecture
/// garde la carte affichée).
Widget? _etatDuBloc(WidgetRef ref, AsyncValue<Object?> tableau) {
  if (tableau.hasValue) return null;
  if (tableau.hasError) {
    return SfBlockError(
      message: kModuleBlockError,
      retryLabel: kModuleRetry,
      onRetry: () => ref.invalidate(dashboardProvider),
    );
  }
  return const SfBlockSkeleton(height: 104, radius: AppRadii.lg);
}
