import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/screen_header.dart';
import 'task_training_data.dart';
import 'tcf_production_module.dart';
import 'widgets/production_blocks.dart';
import 'widgets/production_common.dart';
import 'widgets/production_examples.dart';
import 'widgets/production_state_views.dart';

/// Liste des **modèles corrigés** d'une tâche
/// (`/tcf/{ee,eo}/tache/:n/exemples`).
///
/// Les modèles ne sont plus un onglet de l'écran d'entraînement : ils ont leur
/// écran, atteint par le bouton discret posé au-dessus de la liste des sujets.
/// Le contenu et l'appel API sont inchangés — seul le point d'entrée change.
class TcfTaskExamplesScreen extends ConsumerWidget {
  const TcfTaskExamplesScreen({
    super.key,
    required this.module,
    required this.tache,
  });

  final TcfProductionModule module;
  final int tache;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = TaskTrainingKey(epreuve: module.epreuve, tacheNumero: tache);
    // Les modèles ont leur propre provider : ils ne dépendent pas du catalogue
    // de sujets, et cet écran n'a rien à faire des productions du candidat.
    final async = ref.watch(taskExamplesProvider(key));
    final meta = productionTaskMeta(module, tache);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Exemples corrigés',
              sub: 'Tâche $tache · ${meta.title}',
              onBack: () => _back(context),
            ),
            Expanded(
              child: async.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: module.accent),
                ),
                error: (e, _) => ProductionErrorView(
                  message: ApiClient.toApiException(e).message,
                  onRetry: () => ref.invalidate(taskExamplesProvider(key)),
                ),
                data: (examples) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: _content(context, ref, examples),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    WidgetRef ref,
    List<ProductionExampleDto> examples,
  ) {
    final auth = ref.read(authControllerProvider);
    final premium =
        auth is AuthAuthenticated && auth.user.canAccessModule(AppModule.tcf);

    return [
      ProductionSectionHead(
        title: 'Des modèles à imiter',
        description: module.isEo
            ? 'Écoute comment un candidat traite le sujet, puis reprends la structure sur tes propres réponses.'
            : 'Lis comment un candidat traite le sujet, puis reprends la structure sur tes propres réponses.',
        accent: module.accent,
      ),
      const SizedBox(height: 11),
      if (examples.isEmpty)
        MutedHint(
          text: module.isEo
              ? 'Les exemples audio arriveront bientôt pour cette tâche.'
              : 'Les exemples rédigés arriveront bientôt pour cette tâche.',
        )
      else
        for (int i = 0; i < examples.length; i++)
          FeaturedExampleCard(
            example: examples[i],
            accent: module.accent,
            locked: !premium && i > 0,
            onOpen: (!premium && i > 0)
                ? () => showPaywallSheet(context)
                : () => _openExample(context, examples[i]),
          ),
      const SizedBox(height: 10),
      StrategyCard(
        accent: module.accent,
        onTap: () => _openPlan(context),
      ),
      const SizedBox(height: 15),
      ProductionNotice(
        title: 'À quoi servent ces modèles',
        body:
            "Ils montrent une façon de faire, pas la seule bonne réponse. Repère la structure et les formules, puis écris ou parle avec tes propres mots.",
      ),
    ];
  }

  void _openExample(BuildContext context, ProductionExampleDto example) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExampleDetailSheet(module: module, example: example),
    );
  }

  void _openPlan(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlanSheet(module: module, tache: tache),
    );
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/tcf/${module.routeKey}/tache/$tache');
    }
  }
}
