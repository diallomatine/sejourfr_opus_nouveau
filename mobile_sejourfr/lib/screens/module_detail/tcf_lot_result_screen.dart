import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';

final _attemptProvider =
    FutureProvider.autoDispose.family<Attempt, String>((ref, attemptId) {
  return ref.watch(attemptsRepositoryProvider).getById(attemptId);
});

/// Écran de bilan affiché à la fin d'un lot TCF QCM. Push depuis le runner
/// quand l'attempt termine avec un contexte `from=tcfLot` dans l'URL.
/// L'utilisateur revient ensuite à la liste des lots du niveau via le CTA.
class TcfLotResultScreen extends ConsumerWidget {
  const TcfLotResultScreen({
    super.key,
    required this.attemptId,
    required this.moduleKey,
    required this.level,
  });

  final String attemptId;

  /// 'co' ou 'ce' — sert à reconstruire la route de retour vers les lots.
  final String moduleKey;

  /// Niveau du lot ('a2', 'b1', 'b2') — idem pour la route de retour.
  final String level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAttempt = ref.watch(_attemptProvider(attemptId));

    final String levelLabel = level.toUpperCase();

    void backToLots() {
      // Grâce au `pushReplacement` côté runner, l'écran lots est resté dans
      // la stack — un pop retombe pile dessus en préservant sa propre
      // history vers le détail module. Fallback `context.go` uniquement si
      // la stack a été reset par ailleurs (deep link / hot reload).
      if (context.canPop()) {
        context.pop();
        return;
      }
      context.go(
        AppRoutes.tcfLevelLots
            .replaceFirst(':moduleKey', moduleKey)
            .replaceFirst(':level', level),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: asyncAttempt.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          ),
          error: (e, _) => _ErrorView(
            message: ApiClient.toApiException(e).message,
            onClose: backToLots,
          ),
          data: (attempt) {
            final total = attempt.totalQuestions;
            final score = attempt.score ?? 0;
            final percent = total == 0 ? 0 : (score / total * 100).round();
            final errors = total - score;
            final duration = attempt.finishedAt != null
                ? attempt.finishedAt!.difference(attempt.startedAt)
                : Duration.zero;

            // Couleur + icône + titre pilotés par le RÉSULTAT (pas le niveau du
            // lot) : vert ≥ 70 %, ambre 40–69 %, rouge < 40 %. Mêmes seuils que
            // le badge score des cards de la liste de lots (_colorForScore).
            final tier = _ResultTier.fromPercent(percent);

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                _TopBar(
                  onClose: backToLots,
                  accent: tier.accent,
                  icon: tier.icon,
                ),
                const SizedBox(height: 22),
                Column(
                  children: [
                    Text(
                      'SÉRIE TERMINÉE',
                      style: AppFonts.mono(
                        size: 10,
                        color: AppColors.muted,
                        letterSpacing: 1.8,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tier.heading,
                      style: AppFonts.display(
                        size: 30,
                        weight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Center(
                  child: _ScoreCircle(
                    score: score,
                    total: total,
                    percent: percent,
                    accent: tier.accent,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _caption(percent),
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(
                    size: 13,
                    color: AppColors.muted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                _SummaryCard(
                  correctAnswers: score,
                  errors: errors,
                  duration: duration,
                  levelLabel: levelLabel,
                  accent: tier.accent,
                ),
                const SizedBox(height: 12),
                _AdviceCard(
                  percent: percent,
                  level: levelLabel,
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Voir le rapport détaillé',
                  onPressed: () => context.push(
                    AppRoutes.examReport.replaceFirst(':attemptId', attemptId),
                  ),
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Retour aux lots',
                  variant: AppButtonVariant.ghost,
                  onPressed: backToLots,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _caption(int percent) {
    if (percent >= 80) {
      return 'Excellent ! Tu es solide sur ce niveau, attaque le suivant.';
    }
    if (percent >= 60) {
      return 'Tu es sur une bonne progression. Continue à enchaîner les lots.';
    }
    if (percent >= 40) {
      return 'Encore quelques erreurs à corriger — revois et repasse ce lot ou un voisin.';
    }
    return 'Il reste du travail. Reviens sur les explications avant de repasser.';
  }
}

/// Palier de résultat d'un lot : couleur d'accent, icône de synthèse et titre
/// éditorial, pilotés par le pourcentage de réussite. Seuils alignés sur le
/// badge score des cards de la liste de lots (vert ≥ 70 %, ambre ≥ 40 %, rouge).
class _ResultTier {
  const _ResultTier({
    required this.accent,
    required this.icon,
    required this.heading,
  });

  final Color accent;
  final IconData icon;
  final String heading;

  static _ResultTier fromPercent(int percent) {
    if (percent >= 70) {
      return const _ResultTier(
        accent: AppColors.green,
        icon: LucideIcons.trophy,
        heading: 'Bravo !',
      );
    }
    if (percent >= 40) {
      return const _ResultTier(
        accent: AppColors.amber,
        icon: LucideIcons.trendingUp,
        heading: 'Bien joué !',
      );
    }
    return const _ResultTier(
      accent: AppColors.red,
      icon: LucideIcons.rotateCcw,
      heading: 'Continue !',
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onClose,
    required this.accent,
    required this.icon,
  });

  final VoidCallback onClose;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onClose,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              alignment: Alignment.center,
              child: const Icon(LucideIcons.x,
                  size: 20, color: AppColors.ink),
            ),
          ),
        ),
        const Spacer(),
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.12),
          ),
          child: Icon(icon, size: 22, color: accent),
        ),
      ],
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  const _ScoreCircle({
    required this.score,
    required this.total,
    required this.percent,
    required this.accent,
  });

  final int score;
  final int total;
  final int percent;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 138,
      height: 138,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anneau de fond + progress (conic via CustomPaint serait plus précis,
          // ici on reste sur une fraction radiale simple avec un cercle gradient).
          CustomPaint(
            size: const Size(138, 138),
            painter: _ScoreRingPainter(progress: percent / 100, accent: accent),
          ),
          Container(
            width: 104,
            height: 104,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score/$total',
                  style: AppFonts.ui(
                    size: 28,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                  ).copyWith(letterSpacing: -0.6),
                ),
                const SizedBox(height: 2),
                Text(
                  'SCORE',
                  style: AppFonts.mono(
                    size: 9.5,
                    color: AppColors.muted,
                    letterSpacing: 1.6,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  _ScoreRingPainter({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bg = Paint()
      ..color = AppColors.line2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    const startAngle = -1.5708; // -90° (top)
    final sweepAngle = 6.2832 * progress; // 360° * progress
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.accent != accent;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.correctAnswers,
    required this.errors,
    required this.duration,
    required this.levelLabel,
    required this.accent,
  });

  final int correctAnswers;
  final int errors;
  final Duration duration;
  final String levelLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RÉSUMÉ',
            style: AppFonts.mono(
              size: 9.5,
              color: AppColors.muted,
              letterSpacing: 1.8,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _Row(
            label: 'Bonnes réponses',
            value: '$correctAnswers',
            valueColor: accent,
          ),
          const SizedBox(height: 8),
          _Row(label: 'Erreurs', value: '$errors'),
          const SizedBox(height: 8),
          _Row(label: 'Temps', value: _formatDuration(duration)),
          const SizedBox(height: 8),
          _Row(label: 'Niveau du lot', value: levelLabel),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return '—';
    final m = d.inMinutes;
    final s = d.inSeconds - m * 60;
    if (m == 0) return '$s s';
    return '$m min ${s.toString().padLeft(2, '0')}';
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppFonts.ui(
                size: 13,
                color: AppColors.ink2,
              ),
            ),
          ),
          Text(
            value,
            style: AppFonts.ui(
              size: 13.5,
              weight: FontWeight.w800,
              color: valueColor ?? AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.percent, required this.level});

  final int percent;
  final String level;

  @override
  Widget build(BuildContext context) {
    final advice = percent >= 80
        ? 'Tu maîtrises bien le niveau $level. Tente le niveau supérieur pour confirmer.'
        : percent >= 60
            ? 'Revois les questions ratées pour combler les petits écarts.'
            : percent >= 40
                ? 'Reprends les explications des questions ratées avant de relancer un lot.'
                : 'Travaille en profondeur les questions de ce lot : lis les explications et repasse-le.';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'À TRAVAILLER',
            style: AppFonts.mono(
              size: 9.5,
              color: AppColors.blue,
              letterSpacing: 1.8,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            advice,
            style: AppFonts.ui(
              size: 13,
              color: AppColors.ink2,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(LucideIcons.x),
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
