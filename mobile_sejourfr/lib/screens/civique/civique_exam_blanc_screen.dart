import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/attempt_summary.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../module_detail/civique_exam_briefing_sheet.dart';

/// 20 slots d'examens blancs civiques. Tap vide → briefing + start
/// (POST `/api/attempts {type:MOCK_EXAM, module:CIVIQUE}`), tap fait → push
/// le rapport d'examen. Cf. `TcfFullExamsScreen` pour la version TCF complète.
const int _civiqueExamSlotsCount = 20;

final _civiqueExamsProvider =
    FutureProvider.autoDispose<List<AttemptSummary>>((ref) async {
  // Les examens thème-scopés (20 Q d'un thème, `lot_theme_id` non null) vivent
  // sur l'onglet Examens du détail thème et ne doivent pas polluer la liste
  // des examens blancs complets (40 Q tous thèmes). On filtre donc côté
  // client par `lotThemeId == null` — la limite à 50 inclut l'ensemble
  // des MOCK_EXAM civique du user, suffisant pour les 20 slots affichés.
  final all = await ref.watch(attemptsRepositoryProvider).listMine(
        type: AttemptType.mockExam,
        module: AppModule.civique,
        limit: 50,
      );
  return all.where((a) => !a.isThemeScoped).toList();
});

class CiviqueExamBlancScreen extends ConsumerStatefulWidget {
  const CiviqueExamBlancScreen({super.key});

  @override
  ConsumerState<CiviqueExamBlancScreen> createState() =>
      _CiviqueExamBlancScreenState();
}

class _CiviqueExamBlancScreenState
    extends ConsumerState<CiviqueExamBlancScreen> {
  bool _starting = false;

  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated &&
        auth.user.canAccessModule(AppModule.civique);
  }

  Future<void> _startExam() async {
    if (_starting) return;
    if (!_isPremium()) {
      // Non-abonné : 1 examen blanc gratuit (slot 1). Si un attempt existe
      // déjà — fini ou en cours — on ne crée jamais de nouvel attempt.
      final history = ref.read(_civiqueExamsProvider).valueOrNull ?? const [];
      // In-progress → on resume avec le même attempt (questions inchangées).
      final inProgress = history.where((a) => !a.isFinished).toList();
      if (inProgress.isNotEmpty) {
        context.push(AppRoutes.runner.replaceFirst(':attemptId', inProgress.first.id));
        return;
      }
      // Fini → paywall (relance non autorisée pour non-abonné).
      if (history.any((a) => a.isFinished)) {
        showPaywallSheet(context);
        return;
      }
    }
    setState(() => _starting = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.civique;
    try {
      final attempt = await ref.read(attemptsRepositoryProvider).start(
            StartAttemptRequest(
              type: AttemptType.mockExam,
              module: AppModule.civique,
            ),
          );
      if (!mounted) return;
      ref.invalidate(_civiqueExamsProvider);
      context.push(AppRoutes.runner.replaceFirst(':attemptId', attempt.id));
    } catch (e) {
      if (!mounted) return;
      final apiErr = ApiClient.toApiException(e);
      if (apiErr.isForbidden) {
        showPaywallSheet(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiErr.message),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _openBriefing() {
    if (_starting) return;
    if (!_isPremium()) {
      final history = ref.read(_civiqueExamsProvider).valueOrNull ?? const [];
      // Attempt en cours : on reprend directement, sans briefing — questions
      // inchangées car même attempt côté backend.
      final inProgress = history.where((a) => !a.isFinished).toList();
      if (inProgress.isNotEmpty) {
        context.push(AppRoutes.runner.replaceFirst(':attemptId', inProgress.first.id));
        return;
      }
      // Examen déjà fini : pas de relance, paywall.
      if (history.any((a) => a.isFinished)) {
        showPaywallSheet(context);
        return;
      }
    }
    showCiviqueExamBriefingSheet(context, onStart: _startExam);
  }

  void _openResult(AttemptSummary attempt) {
    context.push(
      AppRoutes.examResult.replaceFirst(':attemptId', attempt.id),
    );
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
    final historyAsync = ref.watch(_civiqueExamsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.blue,
          onRefresh: () async {
            ref.invalidate(_civiqueExamsProvider);
            await ref.read(_civiqueExamsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              _TopBar(onBack: _back),
              const SizedBox(height: 22),
              const _Hero(),
              const SizedBox(height: 16),
              const _Stats(),
              const SizedBox(height: 22),
              historyAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _ErrorBox(
                  message: ApiClient.toApiException(e).message,
                  onRetry: () => ref.invalidate(_civiqueExamsProvider),
                ),
                data: (history) => _SlotsSection(
                  history: history,
                  onTapDone: _openResult,
                  onTapEmpty: _openBriefing,
                  isPremium: _isPremium(),
                  onLocked: () => showPaywallSheet(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onBack,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.chevron_left_rounded,
                  size: 22, color: AppColors.ink),
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.blueLight,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'CIVIQUE',
            style: AppFonts.jakarta(
              size: 12,
              weight: FontWeight.w800,
              color: AppColors.blue,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue, AppColors.blueDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXAMENS BLANCS',
            style: AppFonts.mono(
              size: 10,
              color: AppColors.white.withValues(alpha: 0.85),
              letterSpacing: 1.8,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Simule le vrai',
            style: AppFonts.jakarta(
              size: 26,
              weight: FontWeight.w800,
              color: AppColors.white,
              height: 1.1,
            ).copyWith(letterSpacing: -0.5),
          ),
          Text(
            'examen civique',
            style: AppFonts.jakarta(
              size: 26,
              weight: FontWeight.w800,
              color: AppColors.white,
              height: 1.1,
            ).copyWith(letterSpacing: -0.5),
          ),
          const SizedBox(height: 10),
          Text(
            '40 questions tirées sur les 5 thèmes officiels en 45 min. '
            'Seuil de réussite : 32/40.',
            style: AppFonts.jakarta(
              size: 13.5,
              color: AppColors.white.withValues(alpha: 0.9),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _StatCell(value: '40', label: 'Questions')),
        SizedBox(width: 10),
        Expanded(child: _StatCell(value: '45', label: 'Minutes')),
        SizedBox(width: 10),
        Expanded(child: _StatCell(value: '32/40', label: 'Seuil')),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppFonts.jakarta(
              size: 17,
              weight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppFonts.mono(
              size: 9.5,
              color: AppColors.muted,
              letterSpacing: 1.4,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotsSection extends StatelessWidget {
  const _SlotsSection({
    required this.history,
    required this.onTapDone,
    required this.onTapEmpty,
    required this.isPremium,
    required this.onLocked,
  });

  final List<AttemptSummary> history;
  final void Function(AttemptSummary) onTapDone;
  final VoidCallback onTapEmpty;
  final bool isPremium;
  final VoidCallback onLocked;

  @override
  Widget build(BuildContext context) {
    // Backend renvoie DESC → on inverse pour que slot 1 = examen le plus
    // ancien (parité avec les autres surfaces : TCF QCM, EE/EO, full TCF).
    final finished =
        history.where((a) => a.isFinished).toList().reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tes examens',
              style: AppFonts.jakarta(
                size: 16,
                weight: FontWeight.w800,
                color: AppColors.ink,
              ).copyWith(letterSpacing: -0.2),
            ),
            const Spacer(),
            Text(
              '$_civiqueExamSlotsCount disponibles',
              style: AppFonts.mono(
                size: 10,
                color: AppColors.muted,
                letterSpacing: 1.4,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < _civiqueExamSlotsCount; i++) ...[
          _ExamSlotCard(
            slot: i + 1,
            attempt: i < finished.length ? finished[i] : null,
            onTapDone: onTapDone,
            // Slot 1 = découverte gratuite ; slots 2+ réservés aux abonnés.
            locked: !isPremium && (i + 1) > 1,
            onTapEmpty: !isPremium && (i + 1) > 1 ? onLocked : onTapEmpty,
          ),
          if (i != _civiqueExamSlotsCount - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ExamSlotCard extends StatelessWidget {
  const _ExamSlotCard({
    required this.slot,
    required this.attempt,
    required this.onTapDone,
    required this.onTapEmpty,
    this.locked = false,
  });

  final int slot;
  final AttemptSummary? attempt;
  final void Function(AttemptSummary) onTapDone;
  final VoidCallback onTapEmpty;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final done = attempt != null;
    final color = _scoreColor(attempt);

    return Container(
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
                    width: 44,
                    height: 44,
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
                          'Examen blanc $slot',
                          style: AppFonts.jakarta(
                            size: 14.5,
                            weight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          done
                              ? _formatDoneSubtitle(attempt!)
                              : 'Disponible · 40 questions, 45 min',
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
                  if (locked)
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.line2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 15,
                        color: AppColors.muted,
                      ),
                    )
                  else if (done)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
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
    if (pct >= 80) return AppColors.green;
    if (pct >= 50) return AppColors.amber;
    return AppColors.red;
  }

  String _formatDoneSubtitle(AttemptSummary a) {
    const months = [
      'janv.', 'févr.', 'mars', 'avril', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    final d = a.finishedAt!;
    return '${d.day} ${months[d.month - 1]} ${d.year} · ${a.score ?? 0}/${a.totalQuestions}';
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined,
              color: AppColors.red, size: 30),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.jakarta(color: AppColors.muted, size: 12.5),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
