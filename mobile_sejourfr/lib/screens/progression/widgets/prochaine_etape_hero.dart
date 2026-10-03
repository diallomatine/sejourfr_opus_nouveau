import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/shell_navigation.dart';
import '../../../core/widgets/sejour/sejour_kit.dart';
import '../../home/home_labels.dart';
import '../../plan/civic_plan_labels.dart';
import '../../plan/civic_plan_provider.dart';
import '../../plan/journey_labels.dart';
import '../../plan/learning_plan_provider.dart';
import '../../plan/now_card_gestes.dart';
import '../../plan/plan_now_card.dart';
import '../progression_labels.dart';

/// **« Prochaine étape »** d'un écran de progression (maquette web
/// `#tcf-progression` / `#civique-progression`, ramenée au portrait) : l'étape
/// courante du parcours du module (`journey.current`), avec **le même geste
/// que la carte « À faire maintenant » de l'Accueil** ([gesteEtapeTcf] /
/// [gesteEtapeCivique]) — jamais un second chemin.
///
/// 🛑 Rien n'est composé : titre, méta et geste viennent de [planNowCard] /
/// [civicNowCard]. Bloc à états propres (brief §7) : squelette, erreur +
/// « Réessayer », parcours à jour.
class ProchaineEtapeHero extends ConsumerStatefulWidget {
  const ProchaineEtapeHero({super.key, required this.civique});

  final bool civique;

  @override
  ConsumerState<ProchaineEtapeHero> createState() => _ProchaineEtapeHeroState();
}

class _ProchaineEtapeHeroState extends ConsumerState<ProchaineEtapeHero> {
  bool _lancement = false;

  Future<void> _lancer(Future<void> Function() geste) async {
    if (_lancement) return;
    setState(() => _lancement = true);
    try {
      await geste();
    } finally {
      if (mounted) setState(() => _lancement = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.civique ? _civique(context) : _tcf(context);

  Widget _tcf(BuildContext context) {
    final planAsync = ref.watch(learningPlanProvider);
    final journeyAsync = ref.watch(journeyProvider);
    final plan = planAsync.valueOrNull;
    final parcours = journeyAsync.valueOrNull;
    if (plan == null || parcours == null) {
      return _attente(
        enErreur: planAsync.hasError || journeyAsync.hasError,
        reessayer: () {
          ref.invalidate(learningPlanProvider);
          ref.invalidate(journeyProvider);
        },
      );
    }
    final compte = ref.watch(authControllerProvider);
    final free = !(compte is AuthAuthenticated && compte.user.hasTcf);
    final carte = planNowCard(plan, journey: parcours, free: free);
    if (carte == null) return _aJour(context, civique: false);
    return SfHero(
      civique: false,
      label: kProchaineEtapeLabel,
      title: carte.title,
      sub: homeActionMeta(
          [carte.kindLabel ?? carte.subtitle, carte.minutesLabel]),
      cta: carte.geste == PlanNowGeste.debloquer ? carte.cta : kHomeTcfCta,
      onPressed: gesteEtapeTcf(context, ref, carte, lancer: _lancer),
    );
  }

  Widget _civique(BuildContext context) {
    final planAsync = ref.watch(civicPlanProvider);
    final journeyAsync = ref.watch(journeyCiviqueProvider);
    final plan = planAsync.valueOrNull;
    final parcours = journeyAsync.valueOrNull;
    if (plan == null || parcours == null) {
      return _attente(
        enErreur: planAsync.hasError || journeyAsync.hasError,
        reessayer: () {
          ref.invalidate(civicPlanProvider);
          ref.invalidate(journeyCiviqueProvider);
        },
      );
    }
    final compte = ref.watch(authControllerProvider);
    final free = !(compte is AuthAuthenticated && compte.user.hasCivique);
    final carte =
        civicNowCard(plan, journey: parcours, free: free, lancerExamen: true);
    if (carte == null) return _aJour(context, civique: true);
    return SfHero(
      civique: true,
      label: kProchaineEtapeLabel,
      title: carte.title,
      sub: homeActionMeta([carte.subtitle, carte.meta]),
      cta: carte.geste == PlanNowGeste.debloquer ? carte.cta : kHomeCiviqueCta,
      onPressed: gesteEtapeCivique(context, ref, carte, lancer: _lancer),
    );
  }

  Widget _attente({required bool enErreur, required VoidCallback reessayer}) {
    if (enErreur) {
      return SfBlockError(
        message: kHomeBlockError,
        retryLabel: kHomeRetry,
        onRetry: reessayer,
      );
    }
    return const SfBlockSkeleton(height: 170);
  }

  /// Plus d'étape à faire : le hero le dit et mène au Plan du module, où se
  /// trouve « Actualiser mon plan » (même issue que l'Accueil).
  Widget _aJour(BuildContext context, {required bool civique}) {
    return SfHero(
      civique: civique,
      label: kProchaineEtapeLabel,
      title: kJourneyUpToDateTitle,
      cta: civique ? kHomeCiviqueCta : kHomeTcfCta,
      onPressed: () =>
          pousserOuAller(context, AppRoutes.modulePlan(civique: civique)),
    );
  }
}
