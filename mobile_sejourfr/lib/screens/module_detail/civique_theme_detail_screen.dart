import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../core/widgets/paywall_sheet.dart';
import '../tcf_production/widgets/module_screen_header.dart';
import 'civique_hub_data.dart';
import 'widgets/civique_hub/civique_exam_hero.dart';
import 'widgets/civique_hub/civique_history_section.dart';
import 'widgets/civique_hub/civique_lot_row.dart';
import 'widgets/lot_done_sheet.dart';
import 'widgets/qcm_hub/qcm_section_label.dart';

/// Plafond du nombre de lots rendus inline dans la section « S'entraîner par
/// lot » du hub Civique. Au-delà, le bouton « Voir plus » étend la liste —
/// pendant de la section « S'entraîner par niveau » TCF qui en a 3 fixes.
const int _civiqueLotsInlineCap = 6;

/// Hub Civique d'un thème : single scroll, header + hero rouge (examen blanc
/// thème) + section lots + historique. Pendant de `TcfQcmDetailScreen`.
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

  /// Tap sur un lot : si déjà fait → sheet « Voir le détail » / « Reprendre »,
  /// sinon → démarrage direct.
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
              style: AppFonts.jakarta(size: 13, color: AppColors.white)),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }
    context.push(AppRoutes.examReport.replaceFirst(':attemptId', id));
  }

  /// Lance un lot précis (15 Q du thème). Lot 1 = découverte gratuite par
  /// sous-module ; Lot 2+ paywall pour les non-abonnés.
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

  void _openExamResult(AttemptSummary attempt) {
    context.push(AppRoutes.examResult.replaceFirst(':attemptId', attempt.id));
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.civique);
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
            final theme = themes.where((t) => t.id == widget.themeId).firstOrNull;
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
    final icon = _iconForTheme(theme.code);

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            ModuleScreenHeader(
              title: theme.name,
              subtitle: 'Civique · ${theme.questionCount} questions',
              onBack: _back,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: CiviqueExamHero(
                icon: icon,
                examSubtitle: '20 questions · 20 min',
                description:
                    'Conditions réelles sur « ${theme.name} » : 20 Q tirées du thème, seuil 16/20.',
                onStart: () => _openExamsPage(theme),
              ),
            ),
            const SizedBox(height: 16),
            const QcmSectionLabel('S\'entraîner par lot'),
            lotsAsync.when(
              loading: () => const _LoadingRow(),
              error: (e, _) => _SmallErrorBox(
                message: ApiClient.toApiException(e).message,
              ),
              data: (lots) => _LotsList(
                lots: lots,
                isPremium: isPremium,
                showAll: _showAllLots,
                onTap: (lot) => _onLotTap(theme, lot),
                onToggleShowAll: () => setState(() => _showAllLots = true),
              ),
            ),
            const SizedBox(height: 8),
            historyAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (history) => CiviqueHistorySection(
                history: history,
                onSeeAll: () => _openExamsPage(theme),
                onTap: _openExamResult,
              ),
            ),
          ],
        ),
        if (_starting)
          const Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: Color(0x33000000)),
            ),
          ),
      ],
    );
  }

  IconData _iconForTheme(String code) {
    final lower = code.toLowerCase();
    if (lower.contains('principe') || lower.contains('symbole')) {
      return Icons.flag_rounded;
    }
    if (lower.contains('institution')) return Icons.account_balance_rounded;
    if (lower.contains('droit') || lower.contains('devoir')) {
      return Icons.gavel_rounded;
    }
    if (lower.contains('histoire') || lower.contains('geo')) {
      return Icons.public_rounded;
    }
    if (lower.contains('societe') || lower.contains('société')) {
      return Icons.people_alt_rounded;
    }
    return Icons.menu_book_rounded;
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
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Text(
            'Aucun lot pour ce thème. Le pool de questions est en cours de constitution.',
            style: AppFonts.jakarta(
              size: 12.5,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ),
      );
    }
    final visible =
        showAll ? lots : lots.take(_civiqueLotsInlineCap).toList();
    final hiddenCount = lots.length - visible.length;
    return Column(
      children: [
        for (final lot in visible)
          CiviqueLotRow(
            lot: lot,
            locked: !isPremium && lot.numero > 1,
            onTap: () => onTap(lot),
          ),
        if (hiddenCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: TextButton.icon(
              onPressed: onToggleShowAll,
              icon: Text(
                'Voir les lots ${visible.length + 1} à ${lots.length}',
                style: AppFonts.jakarta(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
              label: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: AppColors.blue),
            ),
          ),
      ],
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2.4, color: AppColors.blue),
        ),
      ),
    );
  }
}

class _SmallErrorBox extends StatelessWidget {
  const _SmallErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.redLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: AppFonts.jakarta(size: 12, color: AppColors.redDark),
        ),
      ),
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
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.ink,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: AppFonts.jakarta(size: 14, color: AppColors.red),
          ),
        ],
      ),
    );
  }
}
