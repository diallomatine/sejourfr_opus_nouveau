import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/attempt_summary.dart';
import '../../core/models/exam_slots.dart';
import '../../core/models/enums.dart';
import '../../core/models/lot_models.dart';
import '../../core/models/question_models.dart';
import '../../core/providers/lots_provider.dart';
import '../tcf_production/widgets/exam_filter_chips.dart';
import 'serie_filtre.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/utils/start_failure.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/exams_action_bar.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/screen_header.dart';
import 'civique_exam_briefing_sheet.dart';
import 'civique_hub_data.dart';
import 'widgets/civique_hub/civique_history_section.dart';
import 'widgets/exam_done_sheet.dart';
import 'widgets/lot_done_sheet.dart';
import 'widgets/serie_card.dart';

/// Plafond du nombre de séries rendues inline. Au-delà, le bouton « Voir
/// plus » étend la liste — certains thèmes civiques ont beaucoup de lots.
const int _civiqueLotsInlineCap = 6;

/// Détail d'un thème civique (cf. pattern `MLevels`/`MSeries` maquette,
/// sans niveaux : Civique n'a pas de palier CECRL). Séries directes +
/// historique des examens du thème + bouton « Examens blancs » fixé en bas.
/// Accessible via `/civique/theme/:themeId`.
class CiviqueThemeDetailScreen extends ConsumerStatefulWidget {
  const CiviqueThemeDetailScreen({super.key, required this.themeId});

  final String themeId;

  @override
  ConsumerState<CiviqueThemeDetailScreen> createState() =>
      _CiviqueThemeDetailScreenState();
}

class _CiviqueThemeDetailScreenState
    extends ConsumerState<CiviqueThemeDetailScreen> {
  bool _starting = false;
  bool _showAllLots = false;

  /// 🛑 **Un état d'écran, pas une préférence** : le filtre se remet à
  /// « Toutes » à chaque ouverture. Le mémoriser cacherait des séries sans que
  /// le candidat se souvienne de l'avoir demandé.
  SerieFiltre _filtre = SerieFiltre.tous;

  /// 🛑 **`watch`, jamais `read`** : le paywall est poussé AU-DESSUS de cet
  /// écran, qui reste monté — un `read` laisserait les lots cadenassés après
  /// un achat.
  bool _isPremium() => ref.watch(accesModuleProvider(AppModule.civique));

  /// Tap sur une série : si déjà faite → sheet « Voir le détail » /
  /// « Reprendre », sinon → démarrage direct.
  void _onLotTap(ThemeDto theme, LotDto lot) {
    if (lot.alreadyAttempted) {
      _openLotDoneSheet(theme, lot);
    } else {
      _startLot(theme, lot);
    }
  }

  void _openLotDoneSheet(ThemeDto theme, LotDto lot) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => LotDoneSheet(
        lot: lot,
        accent: AppColors.blue,
        onViewDetail: () {
          Navigator.of(sheetCtx).pop();
          _openLotReport(lot);
        },
        onResume: () {
          Navigator.of(sheetCtx).pop();
          _startLot(theme, lot);
        },
      ),
    );
  }

  /// « Comme un examen » : pousse le rapport Q-par-Q `ExamReportScreen`.
  /// Nécessite que le backend retourne `lot.lastAttemptId`.
  void _openLotReport(LotDto lot) {
    final id = lot.lastAttemptId;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Détail indisponible — le serveur n\'a pas encore fourni la référence.',
              style: AppFonts.ui(size: 13, color: AppColors.white)),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }
    context.push(AppRoutes.examReport.replaceFirst(':attemptId', id));
  }

  /// Lance une série (15 Q du thème). Série 1 = découverte gratuite par
  /// thème ; série 2+ paywall pour les non-abonnés.
  Future<void> _startLot(ThemeDto theme, LotDto lot) async {
    if (_starting) return;
    if (!_isPremium() && lot.numero > 1) {
      showPaywallSheet(context, ctaLocation: AnalyticsCtaLocation.other);
      return;
    }
    setState(() => _starting = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.civique;
    try {
      final attempt = await ref.read(attemptsRepositoryProvider).start(
            StartAttemptRequest(
              type: AttemptType.training,
              module: AppModule.civique,
              themeId: theme.id,
              lotNumero: lot.numero,
            ),
          );
      if (!mounted) return;
      final runnerPath =
          AppRoutes.runner.replaceFirst(':attemptId', attempt.id);
      context.push('$runnerPath?from=civiqueLot&themeId=${theme.id}');
    } catch (e) {
      if (!mounted) return;
      showPaywallOrError(context, e,
          ctaLocation: AnalyticsCtaLocation.other);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _openExamsPage(ThemeDto theme) {
    ref.read(selectedModuleProvider.notifier).state = AppModule.civique;
    context.push(
      AppRoutes.civiqueThemeExamsPath(theme.id),
    );
  }

  /// Démarre un examen blanc du thème (20 Q, MOCK_EXAM) sur le slot donné,
  /// puis pousse le runner. Miroir de `CiviqueThemeExamsScreen._startExam`.
  Future<void> _startThemeExam(ThemeDto theme,
      {required int slotNumber}) async {
    if (_starting) return;
    setState(() => _starting = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.civique;
    try {
      final attempt = await ref.read(attemptsRepositoryProvider).start(
            StartAttemptRequest(
              type: AttemptType.mockExam,
              module: AppModule.civique,
              themeId: theme.id,
              slotNumber: slotNumber,
            ),
          );
      if (!mounted) return;
      ref.invalidate(civiqueThemeExamsHistoryProvider(theme.id));
      context.push(AppRoutes.runner.replaceFirst(':attemptId', attempt.id));
    } catch (e) {
      if (!mounted) return;
      showPaywallOrError(context, e,
          ctaLocation: AnalyticsCtaLocation.mockExam);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  /// Tap sur un examen de l'historique : ouvre le sheet « Voir le détail » /
  /// « Reprendre », en miroir des séries.
  void _showExamSheet(AttemptSummary attempt, ThemeDto theme) {
    final score = attempt.score;
    final total = attempt.totalQuestions;
    final subtitle =
        (score != null && total > 0) ? 'Dernier score : $score / $total' : null;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => ExamDoneSheet(
        title: 'Examen blanc',
        subtitle: subtitle,
        accent: AppColors.blue,
        onViewDetail: () {
          Navigator.of(sheetCtx).pop();
          context.push(
              AppRoutes.examReport.replaceFirst(':attemptId', attempt.id));
        },
        // « Reprendre » : relance le briefing de CE slot (puis nouvel examen),
        // au lieu de renvoyer vers la grille. Le verrou est celui SERVI pour ce
        // créneau (le slot 1 est offert et rejouable, 2026-09-24) — jamais
        // déduit de l'historique.
        onResume: () async {
          Navigator.of(sheetCtx).pop();
          final slot = attempt.slotNumber ?? 1;
          final grille = await ref
              .read(civiqueThemeExamSlotsProvider(theme.id).future)
              .then<ExamSlots?>((g) => g, onError: (_) => null);
          if (!mounted) return;
          if (grille?.isLocked(slot) ?? true) {
            showPaywallSheet(
              context,
              ctaLocation: AnalyticsCtaLocation.mockExam,
            );
            return;
          }
          showCiviqueThemeExamBriefingSheet(
            context,
            themeName: theme.name,
            onStart: () =>
                _startThemeExam(theme, slotNumber: attempt.slotNumber ?? 1),
          );
        },
      ),
    );
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.reviser);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themesAsync = ref.watch(civiqueThemesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: themesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          ),
          error: (e, _) => _ErrorBlock(
            message: ApiClient.toApiException(e).message,
            onBack: _back,
          ),
          data: (themes) {
            final theme =
                themes.where((t) => t.id == widget.themeId).firstOrNull;
            if (theme == null) {
              return _ErrorBlock(
                message: 'Thème introuvable.',
                onBack: _back,
              );
            }
            return _buildBody(theme);
          },
        ),
      ),
    );
  }

  Widget _buildBody(ThemeDto theme) {
    final lotsAsync = ref.watch(civiqueLotsProvider(theme.id));
    final historyAsync = ref.watch(civiqueThemeExamsHistoryProvider(theme.id));
    final isPremium = _isPremium();

    return Column(
      children: [
        ScreenHeader(
          title: theme.name,
          sub: 'Civique · ${theme.questionCount} questions',
          onBack: _back,
        ),
        Expanded(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  lotsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child:
                            CircularProgressIndicator(color: AppColors.blue),
                      ),
                    ),
                    error: (e, _) => AppCard(
                      child: Text(
                        ApiClient.toApiException(e).message,
                        style:
                            AppFonts.ui(size: 13, color: AppColors.inkSoft),
                      ),
                    ),
                    data: (lots) => _LotsList(
                      lots: lots,
                      isPremium: isPremium,
                      showAll: _showAllLots,
                      filtre: _filtre,
                      onTap: (lot) => _onLotTap(theme, lot),
                      onToggleShowAll: () =>
                          setState(() => _showAllLots = true),
                      // Changer de filtre replie la liste : le plafond
                      // d'affichage repart de zéro sur un autre sous-ensemble.
                      onFiltre: (f) => setState(() {
                        _filtre = f;
                        _showAllLots = false;
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  historyAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (history) => CiviqueHistorySection(
                      history: history,
                      onSeeAll: () => _openExamsPage(theme),
                      onTap: (attempt) => _showExamSheet(attempt, theme),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ExamsActionBar(onPressed: () => _openExamsPage(theme)),
              ),
              if (_starting)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(color: Color(0x33000000)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sous-widgets locaux
// ---------------------------------------------------------------------------

class _LotsList extends StatelessWidget {
  const _LotsList({
    required this.lots,
    required this.isPremium,
    required this.showAll,
    required this.filtre,
    required this.onTap,
    required this.onToggleShowAll,
    required this.onFiltre,
  });

  final List<LotDto> lots;
  final bool isPremium;
  final bool showAll;
  final SerieFiltre filtre;
  final ValueChanged<LotDto> onTap;
  final VoidCallback onToggleShowAll;
  final ValueChanged<SerieFiltre> onFiltre;

  @override
  Widget build(BuildContext context) {
    if (lots.isEmpty) {
      return AppCard(
        child: Text(
          'Aucune série pour ce thème. Le pool de questions est en cours de constitution.',
          style:
              AppFonts.ui(size: 12.5, color: AppColors.inkSoft, height: 1.4),
        ),
      );
    }
    // 🛑 **Le filtre s'applique AVANT le plafond d'affichage** : plafonner
    // d'abord montrerait « 6 séries » dont certaines ne passent pas le filtre,
    // et « Voir les séries 7 à 20 » compterait des lignes invisibles.
    final retenues = serieFiltrer(lots, filtre);
    final visible =
        showAll ? retenues : retenues.take(_civiqueLotsInlineCap).toList();
    final hiddenCount = retenues.length - visible.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExamFilterChips(
          active: SerieFiltre.values.indexOf(filtre),
          labels: serieFiltreLabels(lots),
          onChanged: (i) => onFiltre(SerieFiltre.values[i]),
        ),
        const SizedBox(height: 14),
        // 🛑 Un filtre qui ne rend rien le **dit** : une liste vide sans un mot
        // se lit comme une panne.
        if (retenues.isEmpty)
          AppCard(
            child: Text(
              kSerieFiltreVide,
              style: AppFonts.ui(size: 13, color: AppColors.muted),
            ),
          ),
        for (final lot in visible) ...[
          SerieCard(
            lot: lot,
            accent: AppColors.blue,
            soft: AppColors.blueLight,
            locked: !isPremium && lot.numero > 1,
            onTap: () => onTap(lot),
          ),
          const SizedBox(height: 10),
        ],
        if (hiddenCount > 0)
          TextButton.icon(
            onPressed: onToggleShowAll,
            icon: Text(
              'Voir les séries ${visible.length + 1} à ${retenues.length}',
              style: AppFonts.ui(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.blue,
              ),
            ),
            label: const Icon(LucideIcons.chevronDown,
                size: 16, color: AppColors.blue),
          ),
      ],
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(LucideIcons.arrowLeft),
            color: AppColors.ink,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: AppFonts.ui(size: 14, color: AppColors.red),
          ),
        ],
      ),
    );
  }
}
