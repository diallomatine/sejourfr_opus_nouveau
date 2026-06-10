import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/attempt_summary.dart';
import '../../core/models/enums.dart';
import '../../core/models/lot_models.dart';
import '../../core/models/question_models.dart';
import '../../core/providers/lots_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/fixed_action_bar.dart';
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

  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated &&
        auth.user.canAccessModule(AppModule.civique);
  }

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
      showPaywallSheet(context);
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
      final apiErr = ApiClient.toApiException(e);
      if (apiErr.isForbidden) {
        showPaywallSheet(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(apiErr.message), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _openExamsPage(ThemeDto theme) {
    ref.read(selectedModuleProvider.notifier).state = AppModule.civique;
    context.push(
      AppRoutes.civiqueThemeExams.replaceFirst(':themeId', theme.id),
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
      final apiErr = ApiClient.toApiException(e);
      if (apiErr.isForbidden) {
        showPaywallSheet(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(apiErr.message), backgroundColor: AppColors.red),
        );
      }
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
        // au lieu de renvoyer vers la grille. Refaire est premium (1er passage
        // gratuit déjà consommé) — paywall pour les non-abonnés.
        onResume: () {
          Navigator.of(sheetCtx).pop();
          if (!_isPremium()) {
            final history = ref
                    .read(civiqueThemeExamsHistoryProvider(theme.id))
                    .valueOrNull ??
                const [];
            if (history.any((a) => a.isFinished)) {
              showPaywallSheet(context);
              return;
            }
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
                      onTap: (lot) => _onLotTap(theme, lot),
                      onToggleShowAll: () =>
                          setState(() => _showAllLots = true),
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
                child: FixedActionBar(
                  child: AppButton(
                    label: 'Examens blancs',
                    icon: LucideIcons.target,
                    onPressed: () => _openExamsPage(theme),
                  ),
                ),
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
    required this.onTap,
    required this.onToggleShowAll,
  });

  final List<LotDto> lots;
  final bool isPremium;
  final bool showAll;
  final ValueChanged<LotDto> onTap;
  final VoidCallback onToggleShowAll;

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
    final visible = showAll ? lots : lots.take(_civiqueLotsInlineCap).toList();
    final hiddenCount = lots.length - visible.length;
    return Column(
      children: [
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
              'Voir les séries ${visible.length + 1} à ${lots.length}',
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
