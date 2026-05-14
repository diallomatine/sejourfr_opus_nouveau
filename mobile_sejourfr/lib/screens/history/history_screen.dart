import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/attempt_summary.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/eyebrow.dart';

final _historyProvider = FutureProvider.autoDispose<List<AttemptSummary>>((ref) {
  return ref.watch(attemptsRepositoryProvider).listMine(
        type: AttemptType.mockExam,
        limit: 20,
      );
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(_historyProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Mes examens',
          style: AppFonts.jakarta(size: 16, weight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: list.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            message: ApiClient.toApiException(e).message,
            onRetry: () => ref.invalidate(_historyProvider),
          ),
          data: (sessions) {
            if (sessions.isEmpty) return const _EmptyState();
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(_historyProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  _Header(sessions: sessions),
                  const SizedBox(height: 20),
                  if (sessions.where((s) => s.isFinished).length >= 2) ...[
                    _EvolutionChart(sessions: sessions),
                    const SizedBox(height: 20),
                  ],
                  const Eyebrow('§ Sessions'),
                  const SizedBox(height: 10),
                  for (final s in sessions) ...[
                    _SessionItem(
                      session: s,
                      onTap: () => context.push(
                        '${AppRoutes.examResult.replaceFirst(':attemptId', s.id)}',
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header — score moyen + progression
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.sessions});

  final List<AttemptSummary> sessions;

  @override
  Widget build(BuildContext context) {
    final finished = sessions.where((s) => s.isFinished && s.score != null);
    if (finished.isEmpty) {
      return const SizedBox.shrink();
    }
    final avgScore = finished.map((s) => s.score!.toDouble()).reduce((a, b) => a + b) / finished.length;
    final maxTotal = finished.first.totalQuestions;
    final threshold = finished.first.passThreshold;
    final aboveThreshold = threshold != null && avgScore >= threshold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow('§ Vos ${finished.length} dernières sessions'),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: AppFonts.fraunces(size: 22, weight: FontWeight.w500),
            children: [
              const TextSpan(text: 'Vous progressez '),
              TextSpan(
                text: aboveThreshold ? 'bien' : 'pas mal',
                style: AppFonts.fraunces(
                  size: 22,
                  weight: FontWeight.w700,
                  color: aboveThreshold ? AppColors.green : AppColors.amber,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Score moyen : '),
              TextSpan(
                text: '${avgScore.toStringAsFixed(1)}/$maxTotal',
                style: AppFonts.jakarta(
                  size: 13,
                  color: AppColors.ink,
                  weight: FontWeight.w800,
                ),
              ),
              if (threshold != null)
                TextSpan(
                  text: aboveThreshold
                      ? ' · au-dessus du seuil officiel'
                      : ' · seuil officiel à $threshold/$maxTotal',
                ),
            ],
            style: AppFonts.jakarta(size: 13, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Chart d'évolution (custom painter, pas de dépendance externe)
// ---------------------------------------------------------------------------

class _EvolutionChart extends StatelessWidget {
  const _EvolutionChart({required this.sessions});

  final List<AttemptSummary> sessions;

  @override
  Widget build(BuildContext context) {
    // Sessions terminées, ordre chronologique pour l'affichage des barres
    final finished = sessions.where((s) => s.isFinished && s.score != null).toList().reversed.toList();
    if (finished.isEmpty) return const SizedBox.shrink();

    // On limite à 6 barres max pour rester lisible
    final shown = finished.length > 6 ? finished.sublist(finished.length - 6) : finished;

    final maxTotal = shown.first.totalQuestions;
    final threshold = shown.first.passThreshold;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Évolution du score · ${shown.length} dernière${shown.length > 1 ? "s" : ""}',
            style: AppFonts.mono(
              size: 10,
              color: AppColors.muted,
              letterSpacing: 1.5,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: CustomPaint(
              size: Size.infinite,
              painter: _ChartPainter(
                scores: shown.map((s) => s.score!).toList(),
                max: maxTotal,
                threshold: threshold,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(shown.length, (i) {
                  return Expanded(
                    child: Container(),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.scores,
    required this.max,
    required this.threshold,
  });

  final List<int> scores;
  final int max;
  final int? threshold;

  @override
  void paint(Canvas canvas, Size size) {
    const labelHeight = 22.0;
    final chartHeight = size.height - labelHeight;
    final barWidth = (size.width / scores.length) * 0.55;
    final spacing = size.width / scores.length;

    // Ligne de seuil
    if (threshold != null) {
      final thresholdY = chartHeight - (threshold! / max) * chartHeight;
      final dashPaint = Paint()
        ..color = AppColors.muted2.withValues(alpha: 0.5)
        ..strokeWidth = 1;
      const dashWidth = 4.0;
      const dashSpace = 4.0;
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, thresholdY),
          Offset(startX + dashWidth, thresholdY),
          dashPaint,
        );
        startX += dashWidth + dashSpace;
      }
      // Label "Seuil 32"
      final tp = TextPainter(
        text: TextSpan(
          text: 'Seuil $threshold',
          style: AppFonts.mono(
            size: 9,
            color: AppColors.muted,
            letterSpacing: 1.0,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(0, thresholdY - 14));
    }

    // Barres
    for (int i = 0; i < scores.length; i++) {
      final score = scores[i];
      final ratio = score / max;
      final barHeight = ratio * chartHeight;
      final isLast = i == scores.length - 1;

      Color color;
      if (threshold == null) {
        color = AppColors.blue;
      } else if (isLast) {
        color = AppColors.blue;
      } else if (score >= threshold!) {
        color = AppColors.green.withValues(alpha: 0.7);
      } else {
        color = AppColors.amber.withValues(alpha: 0.7);
      }

      final centerX = spacing * i + spacing / 2;
      final rect = RRect.fromLTRBR(
        centerX - barWidth / 2,
        chartHeight - barHeight,
        centerX + barWidth / 2,
        chartHeight,
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = color);

      // Label du score
      final tp = TextPainter(
        text: TextSpan(
          text: '$score',
          style: AppFonts.mono(
            size: 10,
            color: isLast ? AppColors.blue : AppColors.muted,
            letterSpacing: 0.5,
          ).copyWith(
            fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(centerX - tp.width / 2, chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.scores != scores || old.max != max || old.threshold != threshold;
}

// ---------------------------------------------------------------------------
// Item de la liste
// ---------------------------------------------------------------------------

class _SessionItem extends StatelessWidget {
  const _SessionItem({required this.session, required this.onTap});

  final AttemptSummary session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final score = session.score ?? 0;
    final total = session.totalQuestions;
    final passed = session.isPassed;
    final failed = session.isFailed;

    final scoreBg = passed
        ? AppColors.green.withValues(alpha: 0.1)
        : failed
            ? AppColors.redLight
            : AppColors.blueLight;
    final scoreColor = passed
        ? AppColors.green
        : failed
            ? AppColors.red
            : AppColors.blue;

    final moduleLabel = session.module == AppModule.civique ? 'Civique' : 'TCF';
    final diffLabel = session.difficulty?.wire ?? '';
    final title = '$moduleLabel${diffLabel.isEmpty ? '' : ' · $diffLabel'}';

    final dateStr = _formatDate(session.startedAt);
    final durStr = session.durationSeconds != null ? '${(session.durationSeconds! / 60).round()} min' : '';
    final statusStr = passed
        ? 'réussi'
        : failed
            ? 'échec'
            : 'inachevé';

    final metaPieces = [dateStr, if (durStr.isNotEmpty) durStr, statusStr];
    final meta = metaPieces.join(' · ');

    return AppCard(
      onTap: session.isFinished ? onTap : null,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Bloc score à gauche
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scoreBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: AppFonts.fraunces(
                    size: 22,
                    weight: FontWeight.w700,
                    color: scoreColor,
                    height: 1.0,
                  ),
                ),
                Text(
                  '/ $total',
                  style: AppFonts.mono(
                    size: 9,
                    color: scoreColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.jakarta(
                    size: 14,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  style: AppFonts.jakarta(
                    size: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (session.isFinished) const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.muted2),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ---------------------------------------------------------------------------
// Empty / Error
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, size: 48, color: AppColors.muted2),
            const SizedBox(height: 14),
            Text(
              'Aucun examen passé',
              style: AppFonts.fraunces(
                size: 20,
                weight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Vos examens blancs apparaîtront ici, avec votre progression.',
              textAlign: TextAlign.center,
              style: AppFonts.jakarta(size: 13, color: AppColors.muted2),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 36, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.jakarta(size: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
