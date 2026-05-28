import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/attempt_summary.dart';
import '../../core/models/enums.dart';
import '../../core/providers/lots_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../tcf_production/widgets/module_screen_header.dart';
import 'qcm_hub_data.dart';
import 'widgets/exam_done_sheet.dart';
import 'widgets/qcm_hub/qcm_exam_hero.dart';
import 'widgets/qcm_hub/qcm_history_section.dart';
import 'widgets/qcm_hub/qcm_level_row.dart';
import 'widgets/qcm_hub/qcm_notice_banner.dart';
import 'widgets/qcm_hub/qcm_section_label.dart';

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
    heroProgressLine: 'progression A2 → B1 → B2',
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
    heroProgressLine: 'progression A2 → B1 → B2',
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
    heroProgressLine: 'grammaire en conditions réelles',
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
    required this.heroProgressLine,
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

  /// Fragment de phrase utilisé dans la description du hero examen.
  /// CO/CE → "progression A2 → B1 → B2", Structure → "grammaire en
  /// conditions réelles" (pas de palier CECRL officiel sur ce module).
  final String heroProgressLine;

  /// Message d'avertissement affiché en haut du détail (juste sous le titre)
  /// quand ce module n'est pas une épreuve officielle TCF IRN. `null` pour
  /// CO/CE.
  final String? notice;
}

/// Hub d'épreuve pour les modules TCF QCM (CO, CE, Structure). Un seul
/// scroll : header, bannière notice (Structure), hero examen blanc bleu,
/// section niveaux A2/B1/B2, historique des 3 derniers examens, card erreurs.
class TcfQcmDetailScreen extends ConsumerStatefulWidget {
  const TcfQcmDetailScreen({super.key, required this.module});

  final TcfQcmModule module;

  @override
  ConsumerState<TcfQcmDetailScreen> createState() =>
      _TcfQcmDetailScreenState();
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

  /// Tap sur un examen de l'historique : ouvre le sheet « Voir le détail
  /// (rapport Q-par-Q) » / « Reprendre (nouveau briefing) », en miroir des
  /// lots. Plus de saut direct vers le bilan synthétique.
  void _showExamSheet(AttemptSummary attempt) {
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
        onResume: () {
          Navigator.of(sheetCtx).pop();
          _openExamsPage();
        },
      ),
    );
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
    final qt = mod.questionType;

    // Lot counts pour A2/B1/B2 en parallèle. Riverpod déduplique le fetch
    // côté repository (3 family providers indépendants partagent le cache).
    final lotsA2 = ref.watch(
        lotsProvider(LotsKey(questionType: qt, difficulty: Difficulty.a2)));
    final lotsB1 = ref.watch(
        lotsProvider(LotsKey(questionType: qt, difficulty: Difficulty.b1)));
    final lotsB2 = ref.watch(
        lotsProvider(LotsKey(questionType: qt, difficulty: Difficulty.b2)));
    final countA2 = lotsA2.valueOrNull?.length;
    final countB1 = lotsB1.valueOrNull?.length;
    final countB2 = lotsB2.valueOrNull?.length;

    final historyAsync = ref.watch(qcmExamsHistoryProvider(qt));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            ModuleScreenHeader(
              title: mod.title,
              subtitle: 'TCF IRN · QCM',
              onBack: _back,
            ),
            if (mod.notice != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: QcmNoticeBanner(message: mod.notice!),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: QcmExamHero(
                icon: mod.icon,
                examSubtitle: mod.examSubtitle,
                description:
                    'Conditions réelles : ${mod.examSubtitle.toLowerCase()}, ${mod.heroProgressLine}.',
                onStart: _openExamsPage,
              ),
            ),
            const SizedBox(height: 16),
            const QcmSectionLabel('S\'entraîner par niveau'),
            QcmLevelRow(
              levelLabel: 'A2',
              title: 'Niveau A2',
              subtitle:
                  'Débutant · ${countA2 != null ? "$countA2 lots" : "—"}',
              accent: AppColors.green,
              accentBg: AppColors.green.withValues(alpha: 0.14),
              onTap: () => _openLevel(Difficulty.a2),
              lotCount: countA2,
            ),
            QcmLevelRow(
              levelLabel: 'B1',
              title: 'Niveau B1',
              subtitle:
                  'Intermédiaire · ${countB1 != null ? "$countB1 lots" : "—"}',
              accent: AppColors.amber,
              accentBg: AppColors.amber.withValues(alpha: 0.14),
              onTap: () => _openLevel(Difficulty.b1),
              lotCount: countB1,
            ),
            QcmLevelRow(
              levelLabel: 'B2',
              title: 'Niveau B2',
              subtitle:
                  'Avancé · ${countB2 != null ? "$countB2 lots" : "—"}',
              accent: AppColors.red,
              accentBg: AppColors.red.withValues(alpha: 0.12),
              onTap: () => _openLevel(Difficulty.b2),
              lotCount: countB2,
            ),
            const SizedBox(height: 8),
            historyAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (history) => QcmHistorySection(
                history: history,
                onSeeAll: _openExamsPage,
                onTap: _showExamSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
