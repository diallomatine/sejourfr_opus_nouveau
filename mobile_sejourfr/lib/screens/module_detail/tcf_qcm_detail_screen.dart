import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/models/attempt_summary.dart';
import '../../core/models/enums.dart';
import '../../core/models/lot_models.dart';
import '../../core/providers/lots_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/epreuve_duration.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/fixed_action_bar.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/screen_header.dart';
import 'qcm_hub_data.dart';
import 'tcf_module_exam_briefing_screen.dart';
import 'widgets/exam_done_sheet.dart';
import 'widgets/qcm_hub/qcm_history_section.dart';
import 'widgets/qcm_hub/qcm_notice_banner.dart';

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
    icon: LucideIcons.ear,
    epreuve: EpreuveType.tcfCo,
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
    icon: LucideIcons.fileText,
    epreuve: EpreuveType.tcfCe,
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
    icon: LucideIcons.layoutGrid,
    epreuve: EpreuveType.tcfStructure,
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
    required this.epreuve,
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

  /// Épreuve TCF correspondante — **la clé de la durée**. Elle n'est plus écrite
  /// en dur ici : [durationLabel] et [examSubtitle] la lisent dans
  /// `kEpreuveDurationSeconds`, la seule table de l'app (miroir de
  /// `DureeEpreuve` côté backend). Une épreuve a la même durée où qu'elle soit
  /// jouée — c'est ce qui avait dérivé sur la CE (30 min ici, 35 là).
  final EpreuveType epreuve;

  /// Durée annoncée sur la carte du module (« ≈ 35 min »).
  String get durationLabel => '≈ ${epreuveDurationLabelFor(epreuve)}';

  /// Sous-titre affiché dans le briefing examen (ex: "25 questions · 35 min").
  String get examSubtitle =>
      '25 questions · ${epreuveDurationLabelFor(epreuve)}';

  /// Fragment de phrase utilisé dans la description du briefing examen.
  final String heroProgressLine;

  /// Message d'avertissement affiché en haut du détail quand ce module n'est
  /// pas une épreuve officielle TCF IRN. `null` pour CO/CE.
  final String? notice;
}

/// Descriptif d'un niveau pour les cartes de l'écran (cf. `MLevels` maquette).
class _LevelMeta {
  const _LevelMeta({
    required this.level,
    required this.title,
    required this.desc,
    required this.accent,
    required this.soft,
  });

  final Difficulty level;
  final String title;
  final String desc;
  final Color accent;
  final Color soft;
}

const _levels = <_LevelMeta>[
  _LevelMeta(
    level: Difficulty.a2,
    title: 'Niveau A2',
    desc: 'Bases — phrases simples et situations courantes.',
    accent: AppColors.green,
    soft: AppColors.greenLight,
  ),
  _LevelMeta(
    level: Difficulty.b1,
    title: 'Niveau B1',
    desc: 'Intermédiaire — situations du quotidien étendues.',
    accent: AppColors.amber,
    soft: AppColors.amberLight,
  ),
  _LevelMeta(
    level: Difficulty.b2,
    title: 'Niveau B2',
    desc: 'Avancé — textes longs et argumentation.',
    accent: AppColors.red,
    soft: AppColors.redLight,
  ),
];

/// Détail d'une épreuve TCF QCM (cf. `MLevels` maquette) : choisir un niveau
/// (3 cartes A2/B1/B2 avec compteur de séries faites), historique des examens
/// du module en dessous, bouton « Examens blancs » fixé en bas.
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
          _resumeExam(attempt);
        },
      ),
    );
  }

  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated &&
        auth.user.canAccessModule(AppModule.tcf);
  }

  /// « Reprendre » un examen de l'historique : on relance le briefing de CE
  /// slot précis (puis nouvel attempt), comme la page Examens. Le slot 1 est
  /// offert et rejouable à volonté pour tout compte inscrit ; seuls les slots
  /// 2+ sont réservés au premium (même règle que le backend).
  void _resumeExam(AttemptSummary attempt) {
    final isSlot1 = (attempt.slotNumber ?? 1) == 1;
    if (!_isPremium() && !isSlot1) {
      showPaywallSheet(context);
      return;
    }
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
    showModuleExamBriefingSheet(context, widget.module,
        slotNumber: attempt.slotNumber);
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
    final mod = widget.module;
    final qt = mod.questionType;
    final historyAsync = ref.watch(qcmExamsHistoryProvider(qt));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: mod.title,
              sub: 'Choisir un niveau · TCF IRN',
              onBack: _back,
            ),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      if (mod.notice != null) ...[
                        QcmNoticeBanner(message: mod.notice!),
                        const SizedBox(height: 12),
                      ],
                      for (final meta in _levels) ...[
                        _LevelCard(
                          meta: meta,
                          lots: ref
                              .watch(lotsProvider(LotsKey(
                                  questionType: qt, difficulty: meta.level)))
                              .valueOrNull,
                          onTap: () => _openLevel(meta.level),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 4),
                      historyAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (history) => QcmHistorySection(
                          history: history,
                          moduleTitle: widget.module.title,
                          onSeeAll: _openExamsPage,
                          onTap: _showExamSheet,
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
                        onPressed: _openExamsPage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte d'un niveau (cf. `MLevels` maquette) : chip CECRL 50 px coloré,
/// titre + description + « X/N séries faites », chevron.
class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.meta,
    required this.lots,
    required this.onTap,
  });

  final _LevelMeta meta;
  final List<LotDto>? lots;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = lots?.length;
    final done = lots?.where((l) => l.lastScore != null).length;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: meta.soft,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Center(
              child: Text(
                meta.level.wire,
                style: AppFonts.display(size: 20, color: meta.accent),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meta.title,
                    style: AppFonts.ui(size: 16, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  meta.desc,
                  style: AppFonts.ui(size: 12.5, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 6),
                Text(
                  total == null
                      ? 'Chargement des séries…'
                      : '$done/$total séries faites',
                  style: AppFonts.ui(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.inkFaint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.chevronRight,
              size: 18, color: AppColors.inkFaint),
        ],
      ),
    );
  }
}
