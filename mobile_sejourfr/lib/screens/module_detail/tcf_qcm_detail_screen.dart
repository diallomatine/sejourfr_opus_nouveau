import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/attempt_summary.dart';
import '../../core/models/enums.dart';
import '../../core/models/question_models.dart';
import '../../core/providers/lots_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/question_detail_sheet.dart';

/// Identifie le module TCF QCM exposé via `/tcf/co`, `/tcf/ce` ou
/// `/tcf/structure`. EE/EO ont leur propre détail.
///
/// `structure` porte un `notice` non nul → bannière d'info rendue en haut du
/// détail pour signaler que ce module ne fait pas partie du TCF IRN officiel.
enum TcfQcmModule {
  co(
    routeKey: 'co',
    questionType: QuestionType.co,
    themeCode: 'TCF_CO',
    eyebrow: 'Module TCF',
    title: 'Compréhension orale',
    headlineNoun: 'questions audio',
    description: 'Entraîne ton oreille sur des dialogues, annonces et messages — '
        'le format exact de l\'examen. C\'est l\'épreuve qui distingue le '
        'plus les niveaux : la travailler régulièrement sécurise ton palier CECRL.',
    icon: Icons.headphones_rounded,
    durationLabel: '≈ 20 min',
    examSubtitle: '25 questions · 20 min',
  ),
  ce(
    routeKey: 'ce',
    questionType: QuestionType.ce,
    themeCode: 'TCF_CE',
    eyebrow: 'Module TCF',
    title: 'Compréhension écrite',
    headlineNoun: 'questions sur textes courts',
    description: 'Affiches, articles, courriels, formulaires — tu rencontres exactement ce '
        'que tu auras le jour J. Lecture rapide, choix juste : ici se joue ton '
        'aisance écrite au TCF.',
    icon: Icons.menu_book_rounded,
    durationLabel: '≈ 35 min',
    examSubtitle: '25 questions · 35 min',
  ),
  structure(
    routeKey: 'structure',
    questionType: QuestionType.structure,
    themeCode: 'TCF_STRUCTURE',
    eyebrow: 'Entraînement complémentaire',
    title: 'Structure de la langue',
    headlineNoun: 'questions de grammaire',
    description: 'Conjugaison, accords, prépositions, connecteurs. Module hors TCF IRN '
        'officiel — mais chaque point de grammaire que tu consolides ici fait '
        'gagner des points sur CE, EE et EO.',
    icon: Icons.spellcheck_rounded,
    durationLabel: '≈ 20 min',
    examSubtitle: '25 questions · 20 min',
    notice:
        'Module non évalué dans le TCF IRN officiel. Cet entraînement reste très utile pour consolider ta grammaire et progresser sur les autres épreuves.',
  );

  const TcfQcmModule({
    required this.routeKey,
    required this.questionType,
    required this.themeCode,
    required this.eyebrow,
    required this.title,
    required this.headlineNoun,
    required this.description,
    required this.icon,
    required this.durationLabel,
    required this.examSubtitle,
    this.notice,
  });

  final String routeKey;
  final QuestionType questionType;
  final String themeCode;
  final String eyebrow;
  final String title;
  final String headlineNoun;
  final String description;
  final IconData icon;
  final String durationLabel;

  /// Sous-titre affiché dans le hero examen blanc (ex: "25 questions · 20 min").
  final String examSubtitle;

  /// Message d'avertissement affiché en haut du détail (juste sous le titre)
  /// quand ce module n'est pas une épreuve officielle TCF IRN. `null` pour
  /// CO/CE.
  final String? notice;
}

// ============================================================================
// Providers locaux
// ============================================================================

/// Historique des examens module du user (hub). Family indexée par QuestionType.
final _hubExamsHistoryProvider =
    FutureProvider.autoDispose.family<List<AttemptSummary>, QuestionType>((ref, qt) {
  return ref.watch(attemptsRepositoryProvider).listMine(
        type: AttemptType.mockExam,
        module: AppModule.tcf,
        moduleExamQuestionType: qt,
        limit: 20,
      );
});

/// Questions ratées de l'utilisateur sur une épreuve (CO/CE/STRUCTURE). Family
/// indexée par QuestionType.
final _wrongQuestionsProvider =
    FutureProvider.autoDispose.family<List<QuestionDto>, QuestionType>((ref, questionType) {
  return ref.watch(userContentRepositoryProvider).wrongAnswered(
        module: AppModule.tcf,
        questionType: questionType,
      );
});

// ============================================================================
// Hub refondé — TcfQcmDetailScreen
// ============================================================================

/// Hub d'épreuve pour les modules TCF QCM (CO, CE, Structure).
/// Pas d'onglets — un seul scroll : topbar, bannière notice (si applicable),
/// hero examen blanc bleu, section niveaux, historique, card erreurs.
class TcfQcmDetailScreen extends ConsumerStatefulWidget {
  const TcfQcmDetailScreen({super.key, required this.module});

  final TcfQcmModule module;

  @override
  ConsumerState<TcfQcmDetailScreen> createState() => _TcfQcmDetailScreenState();
}

class _TcfQcmDetailScreenState extends ConsumerState<TcfQcmDetailScreen> {
  void _openLevel(Difficulty level) {
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
    final route = AppRoutes.tcfLevelLots
        .replaceFirst(':moduleKey', widget.module.routeKey)
        .replaceFirst(':level', level.wire.toLowerCase());
    context.push(route);
  }

  void _openExamsPage() {
    context.push('/tcf/${widget.module.routeKey}/examens');
  }

  void _openErrorsPage() {
    context.push('/tcf/${widget.module.routeKey}/erreurs');
  }

  void _openExamResult(AttemptSummary attempt) {
    context.push(AppRoutes.examResult.replaceFirst(':attemptId', attempt.id));
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mod = widget.module;

    // Lot counts pour A2/B1/B2 en parallèle
    final lotsA2 = ref.watch(lotsProvider(LotsKey(questionType: mod.questionType, difficulty: Difficulty.a2)));
    final lotsB1 = ref.watch(lotsProvider(LotsKey(questionType: mod.questionType, difficulty: Difficulty.b1)));
    final lotsB2 = ref.watch(lotsProvider(LotsKey(questionType: mod.questionType, difficulty: Difficulty.b2)));

    int? countA2 = lotsA2.valueOrNull?.length;
    int? countB1 = lotsB1.valueOrNull?.length;
    int? countB2 = lotsB2.valueOrNull?.length;

    // Historique (top 3 récents)
    final historyAsync = ref.watch(_hubExamsHistoryProvider(mod.questionType));

    // Erreurs — compte pour la card discrète
    final wrongAsync = ref.watch(_wrongQuestionsProvider(mod.questionType));
    final wrongCount = wrongAsync.valueOrNull?.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _AppHeader(
              title: mod.title,
              subtitle: 'TCF IRN · QCM',
              onBack: _back,
            ),
            if (mod.notice != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _ModuleNoticeBanner(message: mod.notice!),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _ExamenHeroBlue(module: mod, onStart: _openExamsPage),
            ),
            const SizedBox(height: 16),
            const _SectionLabel('S\'entraîner par niveau'),
            _LevelRow(
              levelLabel: 'A2',
              title: 'Niveau A2',
              subtitle: 'Débutant · ${countA2 != null ? "$countA2 lots" : "—"}',
              accent: AppColors.green,
              accentBg: AppColors.green.withValues(alpha: 0.14),
              onTap: () => _openLevel(Difficulty.a2),
              lotCount: countA2,
            ),
            _LevelRow(
              levelLabel: 'B1',
              title: 'Niveau B1',
              subtitle: 'Intermédiaire · ${countB1 != null ? "$countB1 lots" : "—"}',
              accent: AppColors.amber,
              accentBg: AppColors.amber.withValues(alpha: 0.14),
              onTap: () => _openLevel(Difficulty.b1),
              lotCount: countB1,
            ),
            _LevelRow(
              levelLabel: 'B2',
              title: 'Niveau B2',
              subtitle: 'Avancé · ${countB2 != null ? "$countB2 lots" : "—"}',
              accent: AppColors.red,
              accentBg: AppColors.red.withValues(alpha: 0.12),
              onTap: () => _openLevel(Difficulty.b2),
              lotCount: countB2,
            ),
            const SizedBox(height: 8),
            historyAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (history) => _HistorySection(
                history: history,
                onSeeAll: _openExamsPage,
                onTap: _openExamResult,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _ErrorsCard(
                wrongCount: wrongCount,
                onTap: _openErrorsPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Header
// ============================================================================

class _AppHeader extends StatelessWidget {
  const _AppHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
      color: AppColors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppFonts.jakarta(size: 17, weight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Hero examen blanc — accent BLEU (CO/CE/Structure)
// ============================================================================

class _ExamenHeroBlue extends StatelessWidget {
  const _ExamenHeroBlue({required this.module, required this.onStart});

  final TcfQcmModule module;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(module.icon, size: 15, color: AppColors.blueDark),
              const SizedBox(width: 6),
              Text(
                'EXAMEN COMPLET · ${module.examSubtitle.toUpperCase()}',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.blueDark,
                  letterSpacing: 1.2,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lancer un examen blanc',
            style: AppFonts.jakarta(size: 17, weight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Conditions réelles : ${module.examSubtitle.toLowerCase()}, progression A2 → B1 → B2.',
            style: AppFonts.jakarta(size: 13, color: AppColors.ink2, height: 1.5),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 18, color: AppColors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Commencer',
                    style: AppFonts.jakarta(size: 13.5, weight: FontWeight.w800, color: AppColors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Section label
// ============================================================================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
      child: Text(
        text,
        style: AppFonts.jakarta(size: 13, weight: FontWeight.w700, color: AppColors.muted),
      ),
    );
  }
}

// ============================================================================
// Ligne niveau (A2 / B1 / B2)
// ============================================================================

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.levelLabel,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.accentBg,
    required this.onTap,
    required this.lotCount,
  });

  final String levelLabel;
  final String title;
  final String subtitle;
  final Color accent;
  final Color accentBg;
  final VoidCallback onTap;
  final int? lotCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: _cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: accentBg, shape: BoxShape.circle),
                  child: Text(
                    levelLabel,
                    style: AppFonts.jakarta(size: 13, weight: FontWeight.w800, color: accent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppFonts.jakarta(size: 14, weight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                if (lotCount != null) ...[
                  Text(
                    '$lotCount lots',
                    style: AppFonts.jakarta(size: 11, color: AppColors.muted2),
                  ),
                  const SizedBox(width: 6),
                ],
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted2, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Section Historique (top 3 récents)
// ============================================================================

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.history,
    required this.onSeeAll,
    required this.onTap,
  });

  final List<AttemptSummary> history;
  final VoidCallback onSeeAll;
  final ValueChanged<AttemptSummary> onTap;

  @override
  Widget build(BuildContext context) {
    final finished = history.where((a) => a.isFinished).toList();
    if (finished.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Text(
            'Aucun examen passé. Lance un examen blanc ou entraîne-toi par niveau.',
            style: AppFonts.jakarta(size: 12.5, color: AppColors.muted, height: 1.4),
          ),
        ),
      );
    }

    final recent = finished.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
          child: Row(
            children: [
              Text(
                'Historique',
                style: AppFonts.jakarta(size: 13, weight: FontWeight.w700, color: AppColors.muted),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'Tout voir',
                  style: AppFonts.jakarta(size: 12, weight: FontWeight.w700, color: AppColors.blue),
                ),
              ),
            ],
          ),
        ),
        for (final attempt in recent)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: _HistoryRow(attempt: attempt, onTap: () => onTap(attempt)),
          ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.attempt, required this.onTap});

  final AttemptSummary attempt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final score = attempt.weightedScore;
    final maxScore = attempt.maxWeightedScore;
    final scoreColor = _scoreColor(score, maxScore);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.blueLight, shape: BoxShape.circle),
                  child: const Icon(Icons.assignment_turned_in_rounded, size: 18, color: AppColors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Examen complet',
                        style: AppFonts.jakarta(size: 13.5, weight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _formatDate(attempt.finishedAt ?? attempt.startedAt),
                        style: AppFonts.jakarta(size: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                if (score != null && maxScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$score/$maxScore',
                      style: AppFonts.jakarta(size: 11, weight: FontWeight.w800, color: scoreColor),
                    ),
                  ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted2, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _scoreColor(int? score, int? max) {
    if (score == null || max == null || max == 0) return AppColors.muted;
    final pct = score / max * 100;
    if (pct >= 70) return AppColors.green;
    if (pct >= 40) return AppColors.amber;
    return AppColors.red;
  }
}

// ============================================================================
// Card Erreurs
// ============================================================================

class _ErrorsCard extends StatelessWidget {
  const _ErrorsCard({required this.wrongCount, required this.onTap});

  final int? wrongCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = wrongCount == null
        ? 'Revoir tes questions ratées'
        : wrongCount! == 0
            ? 'Aucune erreur pour l\'instant'
            : '$wrongCount question${wrongCount! > 1 ? "s" : ""} à revoir';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: _cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Erreurs à revoir',
                        style: AppFonts.jakarta(size: 14, weight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted2, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Bannière notice (module Structure)
// ============================================================================

class _ModuleNoticeBanner extends StatelessWidget {
  const _ModuleNoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blueLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded, color: AppColors.blue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'À SAVOIR',
                  style: AppFonts.mono(size: 9.5, color: AppColors.blue, letterSpacing: 1.8, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppFonts.jakarta(size: 12.5, color: AppColors.ink2, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Widgets partagés entre hub et sous-pages
// ============================================================================

/// Ombre douce partagée entre les cards du hub.
const _cardShadow = [
  BoxShadow(color: Color(0x0A0F1839), blurRadius: 12, offset: Offset(0, 4)),
];

String _formatDate(DateTime d) {
  const months = [
    'janv.', 'févr.', 'mars', 'avril', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

// ============================================================================
// Mini widgets réutilisés par TcfQcmExamsScreen et TcfQcmErrorsScreen
// ============================================================================

/// Tag mini de question (niveau / type).
class QuestionMiniTag extends StatelessWidget {
  const QuestionMiniTag({super.key, required this.label, required this.fg, required this.bg});

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: AppFonts.jakarta(size: 10, weight: FontWeight.w800, color: fg),
      ),
    );
  }
}

/// Card revue d'une question ratée — filet ambre à gauche, chip niveau,
/// statement preview, thème en bas. Tap → reviewQuestion + bottomsheet.
class WrongQuestionCard extends ConsumerWidget {
  const WrongQuestionCard({super.key, required this.question});

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
                      color: AppColors.amber,
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
                                  color: AppColors.amber.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.close_rounded, size: 14, color: AppColors.amber),
                              ),
                              const SizedBox(width: 10),
                              QuestionMiniTag(
                                label: question.difficulty.wire,
                                fg: AppColors.amber,
                                bg: AppColors.amber.withValues(alpha: 0.12),
                              ),
                              const SizedBox(width: 6),
                              QuestionMiniTag(
                                label: question.questionType.displayLabel,
                                fg: AppColors.blue,
                                bg: AppColors.blueLight,
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.muted2, size: 20),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            question.statement,
                            style: AppFonts.jakarta(size: 14, weight: FontWeight.w600, height: 1.4, color: AppColors.ink),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.bookmarks_outlined, size: 12, color: AppColors.muted2),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  question.themeName,
                                  style: AppFonts.mono(size: 10, color: AppColors.muted, letterSpacing: 1.1),
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

/// Box erreur réseau.
class QcmErrorBox extends StatelessWidget {
  const QcmErrorBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: AppFonts.jakarta(size: 12, color: AppColors.redDark)),
    );
  }
}
