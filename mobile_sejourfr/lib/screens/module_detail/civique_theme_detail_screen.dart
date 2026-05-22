import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/api/user_content_repository.dart';
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
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/question_detail_sheet.dart';
import 'civique_exam_briefing_sheet.dart';
import 'widgets/module_detail_widgets.dart';

/// Pool des thèmes civique — partagé avec le hub mais on évite de l'importer.
final _civiqueThemesProvider = FutureProvider.autoDispose<List<ThemeDto>>((ref) {
  return ref.watch(themesRepositoryProvider).list(module: AppModule.civique);
});

final _civiqueStatsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  return ref.watch(userContentRepositoryProvider).stats(module: AppModule.civique);
});

/// Historique des **examens civique scopés à un thème** (20 Q de ce thème,
/// 20 min, seuil 16). Family indexée par themeId. Filtre côté backend via
/// `?themeId=...` qui regarde la colonne `lot_theme_id` de l'attempt.
final _civiqueThemeExamsHistoryProvider =
    FutureProvider.autoDispose.family<List<AttemptSummary>, String>((ref, themeId) {
  return ref.watch(attemptsRepositoryProvider).listMine(
        type: AttemptType.mockExam,
        module: AppModule.civique,
        themeId: themeId,
        limit: 30,
      );
});

/// Questions ratées du user sur un thème civique précis. Family indexée
/// par themeId.
final _civiqueWrongProvider = FutureProvider.autoDispose.family<List<QuestionDto>, String>((ref, themeId) {
  return ref.watch(userContentRepositoryProvider).wrongAnswered(
        module: AppModule.civique,
        themeId: themeId,
      );
});

enum _DetailTab { lots, exams, errors }

/// 10 slots d'examens par thème (vs 20 pour l'examen blanc complet
/// civique qui couvre les 5 thèmes — cf. `CiviqueExamBlancScreen`).
const int _civiqueThemeExamSlotsCount = 10;

/// Écran détail d'un thème civique avec 3 onglets (Lots / Examens / Erreurs),
/// calqué sur le pattern TCF QCM (CO/CE). Accessible via `/civique/theme/:themeId`.
class CiviqueThemeDetailScreen extends ConsumerStatefulWidget {
  const CiviqueThemeDetailScreen({super.key, required this.themeId});

  final String themeId;

  @override
  ConsumerState<CiviqueThemeDetailScreen> createState() => _CiviqueThemeDetailScreenState();
}

class _CiviqueThemeDetailScreenState extends ConsumerState<CiviqueThemeDetailScreen> {
  bool _starting = false;
  _DetailTab _tab = _DetailTab.lots;

  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated && auth.user.canAccessModule(AppModule.civique);
  }

  /// Lance un entraînement libre sur ce thème (CTA du bas onglet Lots).
  /// Le backend tire `kInitialBatchSize` questions du thème — distinct des
  /// lots numérotés qui pull une fenêtre fixe.
  Future<void> _startFreeTraining(ThemeDto theme) async {
    if (_starting) return;
    final isPremium = _isPremium();
    setState(() => _starting = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.civique;
    try {
      final attempt = await ref.read(attemptsRepositoryProvider).start(
            StartAttemptRequest(
              type: AttemptType.training,
              module: AppModule.civique,
              themeId: isPremium ? theme.id : null,
              size: isPremium ? kInitialBatchSize : kDemoBatchSize,
            ),
          );
      if (!mounted) return;
      context.push(AppRoutes.runner.replaceFirst(':attemptId', attempt.id));
    } catch (e) {
      if (!mounted) return;
      final apiErr = ApiClient.toApiException(e);
      if (apiErr.isForbidden) {
        showPaywallSheet(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErr.message), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  /// Lance un lot précis de 15 questions du thème (tap sur une card de lot).
  /// Réservé premium : 403 → paywall.
  Future<void> _startLot(ThemeDto theme, LotDto lot) async {
    if (_starting) return;
    if (!_isPremium()) {
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
      context.push(AppRoutes.runner.replaceFirst(':attemptId', attempt.id));
    } catch (e) {
      if (!mounted) return;
      final apiErr = ApiClient.toApiException(e);
      if (apiErr.isForbidden) {
        showPaywallSheet(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErr.message), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  /// Lance un examen civique scopé à un thème (20 Q de ce thème, 20 min,
  /// seuil 16/20). Distinct de l'examen blanc complet civique (40 Q tous
  /// thèmes) accessible depuis la carte sombre du hub.
  Future<void> _startThemeExam(ThemeDto theme) async {
    if (_starting) return;
    if (!_isPremium()) {
      showPaywallSheet(context);
      return;
    }
    setState(() => _starting = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.civique;
    try {
      final attempt = await ref.read(attemptsRepositoryProvider).start(
            StartAttemptRequest(
              type: AttemptType.mockExam,
              module: AppModule.civique,
              themeId: theme.id,
            ),
          );
      if (!mounted) return;
      ref.invalidate(_civiqueThemeExamsHistoryProvider(theme.id));
      context.push(AppRoutes.runner.replaceFirst(':attemptId', attempt.id));
    } catch (e) {
      if (!mounted) return;
      final apiErr = ApiClient.toApiException(e);
      if (apiErr.isForbidden) {
        showPaywallSheet(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErr.message), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _openExamBriefing(ThemeDto theme) {
    if (_starting) return;
    if (!_isPremium()) {
      showPaywallSheet(context);
      return;
    }
    showCiviqueThemeExamBriefingSheet(
      context,
      themeName: theme.name,
      onStart: () => _startThemeExam(theme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themesAsync = ref.watch(_civiqueThemesProvider);
    final statsAsync = ref.watch(_civiqueStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: themesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          ),
          error: (e, _) => _ErrorBlock(
            message: ApiClient.toApiException(e).message,
            onBack: () => context.pop(),
          ),
          data: (themes) {
            final theme = themes.where((t) => t.id == widget.themeId).firstOrNull;
            if (theme == null) {
              return _ErrorBlock(
                message: 'Thème introuvable.',
                onBack: () => context.pop(),
              );
            }

            final themeStats = statsAsync.maybeWhen(
              data: (s) => s.byTheme.where((t) => t.themeId == theme.id).firstOrNull,
              orElse: () => null,
            );
            final percent = themeStats == null ? 0 : (themeStats.mastery * 100).round();
            final attempts = themeStats?.answered ?? 0;

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  children: [
                    ModuleDetailTopBar(
                      onBack: () => context.pop(),
                      icon: _iconForTheme(theme.code),
                      iconColor: AppColors.blue,
                      iconBg: AppColors.blueLight,
                    ),
                    const SizedBox(height: 22),
                    ModuleDetailTitle(
                      eyebrow: 'Module civique',
                      title: theme.name,
                    ),
                    const SizedBox(height: 22),
                    ModuleDetailHero(
                      icon: _iconForTheme(theme.code),
                      headline: '${theme.questionCount} questions au programme',
                      description: theme.description ?? 'Questions officielles couvrant ce thème.',
                      gradient: const [AppColors.blue, AppColors.blueDark],
                    ),
                    const SizedBox(height: 16),
                    ModuleDetailStats(
                      items: [
                        (value: '${theme.questionCount}', label: 'Questions'),
                        (value: '≈ 20 min', label: 'Durée'),
                        (value: _parcoursLabel(), label: 'Parcours'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ModuleDetailScoreCard(
                      percent: percent,
                      attemptsCount: attempts,
                      accent: AppColors.blue,
                    ),
                    const SizedBox(height: 18),
                    ModuleDetailTabs(
                      labels: const ['Lots', 'Examens', 'Erreurs'],
                      activeIndex: _tab.index,
                      onChanged: (i) => setState(() => _tab = _DetailTab.values[i]),
                      accent: AppColors.blue,
                    ),
                    const SizedBox(height: 14),
                    _TabContent(
                      tab: _tab,
                      theme: theme,
                      onLotTap: (lot) => _startLot(theme, lot),
                      onStartExam: () => _openExamBriefing(theme),
                      examStarting: _starting,
                    ),
                    if (_tab == _DetailTab.lots) ...[
                      const SizedBox(height: 18),
                      AppButton(
                        label: 'Commencer l\'entraînement',
                        icon: Icons.play_arrow_rounded,
                        isLoading: _starting,
                        onPressed: _starting ? null : () => _startFreeTraining(theme),
                      ),
                    ],
                  ],
                ),
                if (_starting)
                  const Positioned.fill(
                    child: ModuleDetailStartingOverlay(accent: AppColors.blue),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _parcoursLabel() {
    final auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated) return 'CSP · CR · NAT';
    final target = auth.user.targetProcedure;
    return switch (target) {
      TargetProcedure.csp => 'CSP',
      TargetProcedure.cr => 'CR',
      TargetProcedure.nat => 'NAT',
      null => 'CSP · CR · NAT',
    };
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

class _TabContent extends ConsumerWidget {
  const _TabContent({
    required this.tab,
    required this.theme,
    required this.onLotTap,
    required this.onStartExam,
    required this.examStarting,
  });

  final _DetailTab tab;
  final ThemeDto theme;
  final ValueChanged<LotDto> onLotTap;
  final VoidCallback onStartExam;
  final bool examStarting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (tab) {
      case _DetailTab.lots:
        return _LotsTab(theme: theme, onLotTap: onLotTap);
      case _DetailTab.exams:
        return _ExamsTab(
          theme: theme,
          onStartExam: onStartExam,
          starting: examStarting,
        );
      case _DetailTab.errors:
        return _ErrorsTab(theme: theme);
    }
  }
}

// ---------------------------------------------------------------------------
// Onglet Lots
// ---------------------------------------------------------------------------

class _LotsTab extends ConsumerWidget {
  const _LotsTab({required this.theme, required this.onLotTap});

  final ThemeDto theme;
  final ValueChanged<LotDto> onLotTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotsAsync = ref.watch(civiqueLotsProvider(theme.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOTS DE RÉVISION',
                style: AppFonts.mono(
                  size: 9.5,
                  color: AppColors.muted,
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Découpés en séries de 15 questions, dans l\'ordre du programme. '
                'Touche un lot pour t\'entraîner, ton dernier score reste affiché.',
                style: AppFonts.jakarta(
                  size: 13,
                  color: AppColors.ink2,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Tes lots',
              style: AppFonts.jakarta(
                size: 14,
                weight: FontWeight.w800,
                color: AppColors.ink,
              ).copyWith(letterSpacing: -0.2),
            ),
            const Spacer(),
            lotsAsync.maybeWhen(
              data: (lots) => Text(
                '${lots.length} lot${lots.length > 1 ? 's' : ''}',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.muted,
                  letterSpacing: 1.4,
                  weight: FontWeight.w600,
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        lotsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.blue),
              ),
            ),
          ),
          error: (e, _) => _SmallErrorBox(
            message: ApiClient.toApiException(e).message,
          ),
          data: (lots) {
            if (lots.isEmpty) {
              return ModuleDetailTabPlaceholder(
                icon: Icons.menu_book_outlined,
                title: 'Aucun lot pour ce thème',
                description: 'Le pool de questions est en cours de constitution. Reviens d\'ici peu.',
              );
            }
            return Column(
              children: [
                for (final lot in lots)
                  _CiviqueLotCard(
                    lot: lot,
                    onTap: () => onLotTap(lot),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Card d'un lot civique. Numéro coloré à gauche, titre + sous-titre,
/// badge dernier score à droite quand le lot a déjà été fait.
class _CiviqueLotCard extends StatelessWidget {
  const _CiviqueLotCard({required this.lot, required this.onTap});

  final LotDto lot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = lot.lastScore != null;
    final color = done ? _scoreColor(lot) : AppColors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: done ? color.withValues(alpha: 0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? color.withValues(alpha: 0.3) : AppColors.line,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: done ? color : AppColors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${lot.numero}',
                      style: AppFonts.jakarta(
                        size: 14,
                        weight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lot ${lot.numero}',
                          style: AppFonts.jakarta(
                            size: 14.5,
                            weight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          done
                              ? '${lot.totalQuestions} questions · déjà fait'
                              : '${lot.totalQuestions} questions',
                          style: AppFonts.jakarta(
                            size: 12,
                            color: AppColors.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (done)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${lot.lastScore}/${lot.totalQuestions}',
                        style: AppFonts.jakarta(
                          size: 12,
                          weight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.muted2,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _scoreColor(LotDto lot) {
    if (lot.lastScore == null || lot.totalQuestions == 0) {
      return AppColors.muted;
    }
    final ratio = lot.lastScore! / lot.totalQuestions;
    if (ratio >= 0.7) return AppColors.green;
    if (ratio >= 0.4) return AppColors.amber;
    return AppColors.red;
  }
}

// ---------------------------------------------------------------------------
// Onglet Examens
// ---------------------------------------------------------------------------

/// 10 slots d'examens civique **scopés à ce thème** (20 questions du thème
/// en 20 min, seuil 16/20). Distinct de l'examen blanc complet civique
/// (40 Q tous thèmes) accessible depuis la carte sombre du hub.
class _ExamsTab extends ConsumerWidget {
  const _ExamsTab({
    required this.theme,
    required this.onStartExam,
    required this.starting,
  });

  final ThemeDto theme;
  final VoidCallback onStartExam;
  final bool starting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(_civiqueThemeExamsHistoryProvider(theme.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EXAMEN BLANC · ${theme.name.toUpperCase()}',
                style: AppFonts.mono(
                  size: 9.5,
                  color: AppColors.muted,
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '20 questions tirées uniquement de ce thème en 20 min — '
                'conditions réelles. Seuil de réussite : 16/20.',
                style: AppFonts.jakarta(
                  size: 13,
                  color: AppColors.ink2,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: const [
                  _Chip(text: '20 questions'),
                  _Chip(text: '20 min'),
                  _Chip(text: 'Seuil 16/20'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Tes examens',
              style: AppFonts.jakarta(
                size: 14,
                weight: FontWeight.w800,
                color: AppColors.ink,
              ).copyWith(letterSpacing: -0.2),
            ),
            const Spacer(),
            Text(
              '$_civiqueThemeExamSlotsCount disponibles',
              style: AppFonts.mono(
                size: 10,
                color: AppColors.muted,
                letterSpacing: 1.4,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        asyncHistory.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.blue),
              ),
            ),
          ),
          error: (e, _) => _SmallErrorBox(
            message: ApiClient.toApiException(e).message,
          ),
          data: (history) {
            final finished = history.where((a) => a.isFinished).toList().reversed.toList();
            return Column(
              children: [
                for (int i = 0; i < _civiqueThemeExamSlotsCount; i++)
                  _CiviqueExamSlotCard(
                    slot: i + 1,
                    attempt: i < finished.length ? finished[i] : null,
                    onTapEmpty: starting ? null : onStartExam,
                    onTapDone: (attempt) => _showExamSheet(
                      context,
                      attempt,
                      onStartExam,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showExamSheet(
    BuildContext context,
    AttemptSummary attempt,
    VoidCallback onRetake,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _CiviqueExamActionSheet(
        attempt: attempt,
        onViewDetails: () {
          Navigator.of(sheetCtx).pop();
          context.push(
            AppRoutes.examResult.replaceFirst(':attemptId', attempt.id),
          );
        },
        onRetake: () {
          Navigator.of(sheetCtx).pop();
          onRetake();
        },
      ),
    );
  }
}

class _CiviqueExamSlotCard extends StatelessWidget {
  const _CiviqueExamSlotCard({
    required this.slot,
    required this.attempt,
    required this.onTapEmpty,
    required this.onTapDone,
  });

  final int slot;
  final AttemptSummary? attempt;
  final VoidCallback? onTapEmpty;
  final ValueChanged<AttemptSummary> onTapDone;

  @override
  Widget build(BuildContext context) {
    final done = attempt != null;
    final color = _scoreColor(attempt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: done ? color.withValues(alpha: 0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? color.withValues(alpha: 0.3) : AppColors.line,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: done ? () => onTapDone(attempt!) : onTapEmpty,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: done ? color : AppColors.line2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$slot',
                      style: AppFonts.jakarta(
                        size: 14,
                        weight: FontWeight.w800,
                        color: done ? AppColors.white : AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Examen $slot',
                          style: AppFonts.jakarta(
                            size: 14.5,
                            weight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          done ? _formatDoneSubtitle(attempt!) : 'Disponible · 20 questions, 20 min',
                          style: AppFonts.jakarta(
                            size: 12,
                            color: AppColors.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (done)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${attempt!.score ?? 0}/${attempt!.totalQuestions}',
                        style: AppFonts.jakarta(
                          size: 12,
                          weight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.muted2,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _scoreColor(AttemptSummary? a) {
    if (a == null || a.score == null || a.totalQuestions == 0) {
      return AppColors.muted;
    }
    final pct = a.score! / a.totalQuestions * 100;
    if (pct >= 80) return AppColors.green; // seuil civique 80%
    if (pct >= 50) return AppColors.amber;
    return AppColors.red;
  }

  String _formatDoneSubtitle(AttemptSummary a) {
    const months = [
      'janv.',
      'févr.',
      'mars',
      'avril',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    final d = a.finishedAt!;
    return '${d.day} ${months[d.month - 1]} ${d.year} · ${a.score ?? 0}/${a.totalQuestions}';
  }
}

class _CiviqueExamActionSheet extends StatelessWidget {
  const _CiviqueExamActionSheet({
    required this.attempt,
    required this.onViewDetails,
    required this.onRetake,
  });

  final AttemptSummary attempt;
  final VoidCallback onViewDetails;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Examen blanc passé',
                style: AppFonts.fraunces(size: 22, weight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Score : ${attempt.score ?? 0}/${attempt.totalQuestions} bonnes réponses',
                textAlign: TextAlign.center,
                style: AppFonts.jakarta(size: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Voir les détails',
                icon: Icons.visibility_outlined,
                onPressed: onViewDetails,
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Reprendre (questions différentes)',
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.ghost,
                onPressed: onRetake,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onglet Erreurs
// ---------------------------------------------------------------------------

class _ErrorsTab extends ConsumerWidget {
  const _ErrorsTab({required this.theme});

  final ThemeDto theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncWrong = ref.watch(_civiqueWrongProvider(theme.id));

    return asyncWrong.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.blue),
          ),
        ),
      ),
      error: (e, _) => _SmallErrorBox(message: ApiClient.toApiException(e).message),
      data: (wrongs) {
        if (wrongs.isEmpty) {
          return ModuleDetailTabPlaceholder(
            icon: Icons.verified_outlined,
            title: 'Aucune erreur récente',
            description: 'Bravo — aucune question ratée sur ${theme.name} pour l\'instant.',
          );
        }
        // Cap à 20 entrées pour rester cohérent avec les autres modules.
        final capped = wrongs.length > 20 ? wrongs.sublist(0, 20) : wrongs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${capped.length} ERREUR${capped.length > 1 ? 'S' : ''}',
                    style: AppFonts.mono(
                      size: 9.5,
                      color: AppColors.red,
                      letterSpacing: 1.6,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  theme.name,
                  style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final q in capped) _WrongQuestionCard(question: q),
          ],
        );
      },
    );
  }
}

class _WrongQuestionCard extends ConsumerWidget {
  const _WrongQuestionCard({required this.question});

  final QuestionDto question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openDetail(context, ref),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.redLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: AppColors.red,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.muted2,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            question.statement,
                            style: AppFonts.jakarta(
                              size: 14,
                              weight: FontWeight.w600,
                              height: 1.4,
                              color: AppColors.ink,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.bookmarks_outlined,
                                size: 12,
                                color: AppColors.muted2,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  question.themeName,
                                  style: AppFonts.mono(
                                    size: 10,
                                    color: AppColors.muted,
                                    letterSpacing: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final detailed = await ref.read(userContentRepositoryProvider).reviewQuestion(question.id);
      if (!context.mounted) return;
      showQuestionDetailSheet(context, question: detailed);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(ApiClient.toApiException(e).message),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Helpers communs
// ---------------------------------------------------------------------------

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.line2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppFonts.mono(
          size: 9.5,
          color: AppColors.ink2,
          letterSpacing: 1.2,
          weight: FontWeight.w600,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: AppFonts.jakarta(size: 12, color: AppColors.redDark),
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
