import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import '../../core/providers/shared_prefs_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/paywall_sheet.dart';
import 'ee_session_controller.dart';
import 'eo_session_controller.dart';
import 'production_catalog.dart';
import 'production_nav.dart';
import 'production_quota_info.dart';
import 'production_result_labels.dart';
import 'task_training_data.dart';
import 'tcf_production_module.dart';
import 'widgets/exam_filter_chips.dart';
import 'widgets/production_blocks.dart';
import 'widgets/production_cards.dart';
import 'widgets/production_common.dart';
import 'widgets/production_parcours_top.dart';
import 'widgets/production_state_views.dart';

/// Mode « Sujets TCF » du parcours EE/EO : hero, pastilles T1/T2/T3, filtres
/// avec compteurs, puis les sujets en cartes.
///
/// **Écrit et oral suivent exactement le même écran** : seuls l'accent (bleu /
/// rouge) et la zone de production en aval changent.
///
/// Corps seul — l'en-tête, la tête commune du parcours (héros, prochain
/// entraînement, barre des modes, sélecteur de tâche) et le voile d'attente
/// sont portés par [ProductionParcoursScreen]. Les modèles ne sont pas un
/// mode : c'est une ressource d'appoint, atteinte par un lien discret à droite
/// de l'intertitre de la liste des sujets.
class ProductionSubjectsTabView extends ConsumerStatefulWidget {
  const ProductionSubjectsTabView({
    super.key,
    required this.module,
    required this.tache,
    required this.onBusy,
    required this.top,
  });

  final TcfProductionModule module;
  final int tache;

  /// Remonte l'attente au parcours : le voile doit couvrir la tête du parcours.
  final ValueChanged<bool> onBusy;

  /// Tête commune du parcours, rendue en tête de cette liste.
  final List<Widget> Function({required bool withTaskPicker}) top;

  @override
  ConsumerState<ProductionSubjectsTabView> createState() =>
      _ProductionSubjectsTabViewState();
}

class _ProductionSubjectsTabViewState
    extends ConsumerState<ProductionSubjectsTabView> {
  bool _starting = false;
  int _filter = 0; // 0 = Tous, 1 = À faire, 2 = Traités
  bool _showAll = false;

  TaskTrainingKey get _key => TaskTrainingKey(
        epreuve: widget.module.epreuve,
        tacheNumero: widget.tache,
      );

  void _setStarting(bool value) {
    setState(() => _starting = value);
    widget.onBusy(value);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowQuotaInfo());
  }

  /// Info one-time pour les comptes gratuits : 1 essai d'entraînement offert
  /// par épreuve (EE et EO), évalué par l'IA, + 1 examen blanc de production
  /// offert (`ProductionAccessService.enforceQuota` côté backend).
  ///
  /// Elle vit ICI, sur la liste des sujets TCF complets, et nulle part
  /// ailleurs : c'est le seul écran de l'épreuve où cette règle s'applique, et
  /// il précède l'écran de production qui consomme l'essai — on annonce avant,
  /// pas après un 403. Surtout PAS sur l'écran d'entrée (mode « Compétences ») :
  /// les micro-exercices ne verrouillent aucun sujet et ont leur propre quota
  /// (analyses IA offertes), l'y afficher annoncerait une règle fausse.
  ///
  /// Mémorisée par épreuve, sous la même clé que le web
  /// (`sejourfr.prodQuotaInfo.TCF_{EE,EO}`), pour que les deux fronts disent la
  /// même chose au même moment.
  Future<void> _maybeShowQuotaInfo() async {
    if (!mounted || _isPremium()) return;
    final prefs = ref.read(sharedPrefsProvider);
    final key = prodQuotaInfoKey(widget.module.epreuve);
    if (prefs.getBool(key) ?? false) return;
    // Marqué vu AVANT l'ouverture : une feuille se referme aussi en la
    // glissant, geste qui ne passe par aucun callback — l'écrire à la
    // fermeture la ferait revenir à chaque visite.
    await prefs.setBool(key, true);
    if (!mounted) return;
    await showAppSheet<void>(
      context,
      icon: LucideIcons.gift,
      iconBg: widget.module.accent.withValues(alpha: 0.12),
      iconColor: widget.module.accentDark,
      title: 'Un essai gratuit par épreuve',
      children: [
        Text(
          "Vous disposez d'un essai d'entraînement gratuit en "
          '${widget.module.title.toLowerCase()}, évalué par l\'IA '
          '(votre niveau sur les paliers du TCF), ainsi qu\'un examen blanc '
          'complet offert. Pour vous entraîner sans limite, passez à '
          'l\'abonnement Intégral.',
          style: AppFonts.ui(size: 13.5, color: AppColors.inkSoft, height: 1.55),
        ),
        const SizedBox(height: 6),
        AppButton(
          label: 'Compris',
          height: 46,
          variant: widget.module.isEo
              ? AppButtonVariant.accent
              : AppButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// EE/EO sont des épreuves TCF → accès gouverné par l'abonnement Intégral
  /// (`hasTcf`). Non-abonné : seul le 1er sujet est ouvert, le reste est
  /// cadenassé (parité avec les séries CO/CE/Structure).
  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated &&
        auth.user.canAccessModule(AppModule.tcf);
  }

  void _openExamples() =>
      context.push(productionExamplesPath(widget.module, widget.tache));

  Future<void> _practice(ProductionTaskDto task) async {
    if (_starting) return;
    _setStarting(true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
    try {
      // On ouvre TOUJOURS le briefing (lecture du sujet). Le choix du mode EO
      // T1/T2 (examinateur temps réel vs enregistrement seul) est proposé
      // LÀ-BAS, au moment de « Commencer l'enregistrement » — jamais avant
      // d'avoir lu le sujet. Cf. eo_briefing_screen._onStartPressed.
      if (widget.module.isEo) {
        await ref.read(eoSessionProvider.notifier).startSingle(task: task);
      } else {
        await ref.read(eeSessionProvider.notifier).startSingle(task: task);
      }
      if (!mounted) return;
      // On retire le voile AVANT le push : sinon l'écran sortant le garde
      // pendant l'animation de slide → flash d'un écran sombre avant le
      // briefing.
      _setStarting(false);
      // Le rafraîchissement de la liste au retour est géré par le parcours
      // (`RouteAware.didPopNext`) : on ne peut pas se fier au `Future` du push,
      // le flux fait des `pushReplacement` et se résout avant que la note
      // existe.
      context.push(widget.module.isEo
          ? '/tcf/expression-orale/t/0'
          : '/tcf/expression-ecrite/t/0');
    } catch (e) {
      if (!mounted) return;
      final err = ApiClient.toApiException(e);
      if (err.isForbidden) {
        showPaywallSheet(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.message), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) _setStarting(false);
    }
  }

  void _openReport(ProductionSubmissionDto sub) {
    final base = widget.module.isEo
        ? '/tcf/expression-orale/resultats'
        : '/tcf/expression-ecrite/resultats';
    final tache = sub.tacheNumero ?? widget.tache;
    context.push('$base/${sub.id}?taskIndex=${tache - 1}&history=1');
  }

  void _openDoneSheet(ProductionTaskDto task, ProductionSubmissionDto last) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // Le palier de la dernière production, jamais sa note : au TCF un
        // sujet isolé reçoit un niveau (décision produit du 2026-08-08).
        final niveau = tacheNiveau(last.evaluation);
        // Sans niveau affichable, on dit quand même l'état — « Évaluée » si la
        // correction est là, « Traité » sinon. La ligne disparaissait
        // entièrement, alors que la carte derrière la feuille affichait bien
        // « Traité » : deux surfaces, deux vérités sur le même sujet.
        final etat = niveau != null
            ? tacheNiveauLabel(niveau)
            : last.evaluation != null
                ? kTacheEvalueeLabel
                : kTacheTraiteeLabel;
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(),
                Text(task.displayTitle, style: AppFonts.display(size: 18)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(LucideIcons.circleCheck,
                        size: 13, color: AppColors.green),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Dernière évaluation : $etat',
                        style: AppFonts.ui(
                          size: 12.5,
                          color: AppColors.green,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Voir le détail',
                  icon: LucideIcons.fileText,
                  variant: AppButtonVariant.ghost,
                  height: 46,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openReport(last);
                  },
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Refaire',
                  icon: LucideIcons.refreshCw,
                  variant: widget.module.isEo
                      ? AppButtonVariant.accent
                      : AppButtonVariant.primary,
                  height: 46,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _practice(task);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mod = widget.module;

    // La tête du parcours porte la barre des trois modes : elle est rendue
    // **quel que soit l'état** de la liste, sinon une erreur de chargement
    // enfermerait le candidat dans ce mode.
    final content = ref.watch(taskTrainingProvider(_key)).when(
          // Au retour d'un entraînement (le parcours invalide le catalogue), on
          // garde la liste affichée pendant le refetch au lieu de flasher un
          // spinner plein écran.
          skipLoadingOnReload: true,
          loading: () => [
            Center(child: CircularProgressIndicator(color: mod.accent)),
          ],
          error: (e, _) => [
            ProductionErrorView(
              message: ApiClient.toApiException(e).message,
              onRetry: () => invalidateProductionCatalog(ref, mod.epreuve),
            ),
          ],
          data: (data) => data.subjects.isEmpty
              ? const [
                  ProductionEmptyView(
                    description:
                        'Les sujets de cette tâche ne sont pas encore prêts. '
                        'Reviens vite !',
                  ),
                ]
              : _subjects(mod, data),
        );

    return ListView(
      // Une clé par tâche : changer de tâche repart en haut de liste au lieu
      // de garder le défilement d'une autre tâche.
      key: PageStorageKey<int>(widget.tache),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        ...widget.top(withTaskPicker: true),
        ...content,
      ],
    );
  }

  List<Widget> _subjects(TcfProductionModule mod, TaskTrainingData data) {
    final subjects = data.subjects;
    final done = data.lastByTaskId;
    final premium = _isPremium();

    // Index d'origine conservé : c'est lui qui pilote le verrou freemium
    // (1er sujet offert, suivants premium), indépendamment du filtre courant.
    final indexed = [for (int i = 0; i < subjects.length; i++) (i, subjects[i])];
    final doneCount = indexed.where((e) => done[e.$2.id] != null).length;
    final todoCount = indexed.length - doneCount;
    final filtered = indexed.where((e) {
      final isDone = done[e.$2.id] != null;
      if (_filter == 1) return !isDone;
      if (_filter == 2) return isDone;
      return true;
    }).toList();

    final visible = _showAll ? filtered : filtered.take(6).toList();
    final remaining = filtered.length - visible.length;

    return [
      ExamFilterChips(
        active: _filter,
        accent: mod.accent,
        labels: [
          'Tous · ${indexed.length}',
          'À faire · $todoCount',
          'Traités · $doneCount',
        ],
        onChanged: (i) => setState(() {
          _filter = i;
          _showAll = false;
        }),
      ),
      const SizedBox(height: 14),
      ProductionSectionHead(
        title: "Sujets d'entraînement",
        description: mod.isEo
            ? 'Choisis un sujet, enregistre ta réponse, reçois ta correction.'
            : 'Choisis un sujet, rédige ta réponse, reçois ta correction.',
        accent: mod.accent,
        trailing: ProductionSideLink(
          icon: mod.isEo ? LucideIcons.headphones : LucideIcons.bookOpen,
          label: data.examples.isEmpty
              ? 'Exemples corrigés'
              : '${data.examples.length} exemples corrigés',
          accent: mod.accent,
          onTap: _openExamples,
        ),
      ),
      const SizedBox(height: 12),
      if (filtered.isEmpty)
        MutedHint(
          text: _filter == 2
              ? "Aucun sujet traité pour l'instant."
              : 'Tous les sujets sont traités. Bravo !',
        )
      else
        for (final (origIndex, task) in visible)
          ProductionSubjectCard(
            order: origIndex + 1,
            task: task,
            isOral: mod.isEo,
            accent: mod.accent,
            last: done[task.id],
            locked: !premium && origIndex > 0,
            onTap: () {
              if (!premium && origIndex > 0) {
                showPaywallSheet(context);
                return;
              }
              final last = done[task.id];
              if (last != null) {
                _openDoneSheet(task, last);
              } else {
                _practice(task);
              }
            },
          ),
      if (remaining > 0)
        ShowMoreButton(
          label: 'Voir les $remaining autres',
          accent: mod.accent,
          onTap: () => setState(() => _showAll = true),
        ),
    ];
  }
}
