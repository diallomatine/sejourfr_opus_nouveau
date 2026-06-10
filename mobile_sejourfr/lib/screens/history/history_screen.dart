import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

/// Historique des examens blancs **civique complets uniquement** (40 Q, tous
/// thèmes, seuil 32). Les examens thématiques (20 Q d'un seul thème) vivent
/// dans l'onglet Examens du détail de chaque thème, pas ici — sinon la liste
/// se mélange et le "score moyen" perd son sens.
///
/// Filtre côté API (`module=CIVIQUE&type=MOCK_EXAM`) + filtre côté client
/// (`!isThemeScoped`, qui s'appuie sur `lotThemeId == null`).
final _civiqueExamHistoryProvider =
    FutureProvider.autoDispose<List<AttemptSummary>>((ref) async {
  final all = await ref.watch(attemptsRepositoryProvider).listMine(
        type: AttemptType.mockExam,
        module: AppModule.civique,
        limit: 30,
      );
  return all.where((s) => !s.isThemeScoped).toList();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(_civiqueExamHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Examens civique',
          style: AppFonts.ui(size: 16, weight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: list.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            message: ApiClient.toApiException(e).message,
            onRetry: () => ref.invalidate(_civiqueExamHistoryProvider),
          ),
          data: (sessions) {
            if (sessions.isEmpty) return const _EmptyState();
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(_civiqueExamHistoryProvider),
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
                        AppRoutes.examResult.replaceFirst(':attemptId', s.id),
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
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.sessions});

  final List<AttemptSummary> sessions;

  @override
  Widget build(BuildContext context) {
    final finished = sessions.where((s) => s.isFinished && s.score != null);
    if (finished.isEmpty) return const SizedBox.shrink();

    // Taux de réussite moyen (en %) plutôt que score brut, car les totaux
    // peuvent varier entre civique (40) et TCF (60+).
    final ratios = finished.map((s) => s.totalQuestions == 0 ? 0.0 : s.score! / s.totalQuestions).toList();
    final avgRatio = ratios.reduce((a, b) => a + b) / ratios.length;
    final avgPercent = (avgRatio * 100).round();
    final good = avgRatio >= 0.7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(
          '§ Vos ${finished.length} dernière${finished.length > 1 ? "s" : ""} session${finished.length > 1 ? "s" : ""}',
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: AppFonts.display(size: 22, weight: FontWeight.w500),
            children: [
              const TextSpan(text: 'Vous progressez '),
              TextSpan(
                text: good ? 'bien' : 'pas mal',
                style: AppFonts.display(
                  size: 22,
                  weight: FontWeight.w700,
                  color: good ? AppColors.green : AppColors.amber,
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
              const TextSpan(text: 'Taux moyen : '),
              TextSpan(
                text: '$avgPercent %',
                style: AppFonts.ui(
                  size: 13,
                  color: AppColors.ink,
                  weight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: good ? ' · vous êtes sur la bonne voie' : ' · continuez à vous entraîner',
              ),
            ],
            style: AppFonts.ui(size: 13, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Chart d'évolution (taux % par session, pour pouvoir mixer civique et TCF)
// ---------------------------------------------------------------------------

class _EvolutionChart extends StatelessWidget {
  const _EvolutionChart({required this.sessions});

  final List<AttemptSummary> sessions;

  @override
  Widget build(BuildContext context) {
    // On garde les sessions finies, en ordre chrono (oldest → newest pour
    // l'affichage des barres de gauche à droite).
    final finished = sessions.where((s) => s.isFinished && s.score != null).toList().reversed.toList();
    if (finished.isEmpty) return const SizedBox.shrink();

    // 6 dernières max
    final shown = finished.length > 6 ? finished.sublist(finished.length - 6) : finished;

    // On affiche en RATIO (0 → 1.0) pour pouvoir mélanger civique 40 et
    // TCF 60+ sans biaiser les barres.
    final ratios = shown
        .map((s) => s.totalQuestions == 0 ? 0.0 : (s.score! / s.totalQuestions).clamp(0.0, 1.0))
        .toList();

    // Seuil moyen : on prend le seuil de la dernière session si dispo
    final lastWithThreshold = shown.lastWhere(
      (s) => s.passThreshold != null && s.totalQuestions > 0,
      orElse: () => shown.first,
    );
    final thresholdRatio = lastWithThreshold.passThreshold != null && lastWithThreshold.totalQuestions > 0
        ? (lastWithThreshold.passThreshold! / lastWithThreshold.totalQuestions).clamp(0.0, 1.0)
        : null;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Évolution · ${shown.length} dernière${shown.length > 1 ? "s" : ""}',
            style: AppFonts.mono(
              size: 10,
              color: AppColors.muted,
              letterSpacing: 1.5,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          // Hauteur FIXE et CLIPÉE → le chart ne peut plus déborder
          ClipRect(
            child: SizedBox(
              height: 140,
              child: CustomPaint(
                size: Size.infinite,
                painter: _ChartPainter(
                  ratios: ratios,
                  scores: shown.map((s) => s.score!).toList(),
                  thresholdRatio: thresholdRatio,
                ),
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
    required this.ratios,
    required this.scores,
    required this.thresholdRatio,
  });

  /// Ratios 0..1 — la hauteur de chaque barre est cette valeur fois chartHeight.
  final List<double> ratios;

  /// Scores absolus à afficher sous chaque barre.
  final List<int> scores;

  /// Hauteur relative de la ligne de seuil (0..1), null si pas de seuil.
  final double? thresholdRatio;

  @override
  void paint(Canvas canvas, Size size) {
    if (ratios.isEmpty) return;

    const labelHeight = 22.0;
    const topPadding = 6.0; // marge en haut pour que la barre max ne touche pas le bord
    final chartHeight = (size.height - labelHeight - topPadding).clamp(0.0, double.infinity);
    final chartTop = topPadding;
    final chartBottom = chartTop + chartHeight;

    final barCount = ratios.length;
    final slotWidth = size.width / barCount;
    final barWidth = (slotWidth * 0.55).clamp(8.0, 36.0);

    // ───── Ligne de seuil ─────
    if (thresholdRatio != null) {
      final r = thresholdRatio!.clamp(0.0, 1.0);
      final y = chartBottom - r * chartHeight;
      final dashPaint = Paint()
        ..color = AppColors.muted2.withValues(alpha: 0.5)
        ..strokeWidth = 1;
      const dashWidth = 4.0;
      const dashSpace = 4.0;
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, y),
          Offset((x + dashWidth).clamp(0, size.width), y),
          dashPaint,
        );
        x += dashWidth + dashSpace;
      }
      final tp = TextPainter(
        text: TextSpan(
          text: 'Seuil',
          style: AppFonts.mono(
            size: 9,
            color: AppColors.muted,
            letterSpacing: 1.0,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, (y - 14).clamp(0, chartBottom)));
    }

    // ───── Barres ─────
    for (int i = 0; i < barCount; i++) {
      final r = ratios[i].clamp(0.0, 1.0);
      final barHeight = r * chartHeight;
      final isLast = i == barCount - 1;

      Color color;
      if (thresholdRatio == null) {
        color = isLast ? AppColors.blue : AppColors.blue.withValues(alpha: 0.6);
      } else if (isLast) {
        color = AppColors.blue;
      } else if (r >= thresholdRatio!) {
        color = AppColors.green.withValues(alpha: 0.7);
      } else {
        color = AppColors.amber.withValues(alpha: 0.7);
      }

      final centerX = slotWidth * i + slotWidth / 2;
      // top et bottom sont CLAMPÉS dans la zone du chart → plus de débordement
      final top = (chartBottom - barHeight).clamp(chartTop, chartBottom);
      final bottom = chartBottom;

      // Cas particulier : barre à 0 → on dessine un petit trait minimal
      // pour qu'on voie qu'il y a eu une session
      final actualTop = barHeight < 2 ? bottom - 2 : top;

      final rect = RRect.fromLTRBR(
        centerX - barWidth / 2,
        actualTop,
        centerX + barWidth / 2,
        bottom,
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = color);

      // Label score sous la barre
      final tp = TextPainter(
        text: TextSpan(
          text: '${scores[i]}',
          style: AppFonts.mono(
            size: 10,
            color: isLast ? AppColors.blue : AppColors.muted,
            letterSpacing: 0.5,
          ).copyWith(
            fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(centerX - tp.width / 2, chartBottom + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.ratios != ratios || old.scores != scores || old.thresholdRatio != thresholdRatio;
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

    // L'écran ne montre que des examens blancs civique complets (40 Q tous
    // thèmes). Pas besoin de répéter "Civique" sur chaque ligne — le titre
    // explique le format de l'examen.
    final title = 'Examen blanc · 40 questions';

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
                  style: AppFonts.display(
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
                  style: AppFonts.ui(
                    size: 14,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  style: AppFonts.ui(
                    size: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (session.isFinished) const Icon(LucideIcons.chevronRight, size: 12, color: AppColors.muted2),
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
            const Icon(LucideIcons.timer, size: 48, color: AppColors.muted2),
            const SizedBox(height: 14),
            Text(
              'Aucun examen civique',
              style: AppFonts.display(
                size: 20,
                weight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Vos examens blancs civique (40 questions) apparaîtront ici.',
              textAlign: TextAlign.center,
              style: AppFonts.ui(size: 13, color: AppColors.muted2),
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
            const Icon(LucideIcons.cloudOff, size: 36, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.ui(size: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
