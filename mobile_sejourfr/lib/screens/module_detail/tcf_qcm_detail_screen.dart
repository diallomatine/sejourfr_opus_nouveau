import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/api/user_content_repository.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/paywall_sheet.dart';
import 'widgets/module_detail_widgets.dart';

/// Identifie le module TCF QCM exposé via `/tcf/co` ou `/tcf/ce`. Restreint
/// volontairement à CO et CE — EE/EO ont leur propre détail.
enum TcfQcmModule {
  co(
    routeKey: 'co',
    questionType: QuestionType.co,
    eyebrow: 'Module TCF',
    title: 'Compréhension orale',
    headline: '25 questions audio',
    description:
        'Écoute des dialogues courts, annonces ou messages, puis choisis la bonne réponse.',
    icon: Icons.headphones_rounded,
    durationLabel: '≈ 20 min',
  ),
  ce(
    routeKey: 'ce',
    questionType: QuestionType.ce,
    eyebrow: 'Module TCF',
    title: 'Compréhension écrite',
    headline: '25 questions sur textes courts',
    description:
        'Affiches, articles, courriels, structure de la langue — lis et identifie la bonne réponse.',
    icon: Icons.menu_book_rounded,
    durationLabel: '≈ 35 min',
  );

  const TcfQcmModule({
    required this.routeKey,
    required this.questionType,
    required this.eyebrow,
    required this.title,
    required this.headline,
    required this.description,
    required this.icon,
    required this.durationLabel,
  });

  final String routeKey;
  final QuestionType questionType;
  final String eyebrow;
  final String title;
  final String headline;
  final String description;
  final IconData icon;
  final String durationLabel;
}

final _tcfStatsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  return ref.watch(userContentRepositoryProvider).stats(module: AppModule.tcf);
});

enum _DetailTab { series, exams, errors }

/// Carte de niveau exposée dans l'onglet Séries. Tap → push l'écran lots.
class _SeriesLevel {
  const _SeriesLevel({
    required this.difficulty,
    required this.label,
    required this.subtitle,
    required this.lotSize,
    required this.accent,
    required this.accentBg,
  });

  final Difficulty difficulty;
  final String label;
  final String subtitle;
  final int lotSize;
  final Color accent;
  final Color accentBg;
}

const _seriesLevels = <_SeriesLevel>[
  _SeriesLevel(
    difficulty: Difficulty.a2,
    label: 'Niveau A2',
    subtitle: 'Bases — 15 questions par lot',
    lotSize: 15,
    accent: AppColors.green,
    accentBg: Color(0xFFE6F4EC),
  ),
  _SeriesLevel(
    difficulty: Difficulty.b1,
    label: 'Niveau B1',
    subtitle: 'Intermédiaire — 20 questions par lot',
    lotSize: 20,
    accent: AppColors.amber,
    accentBg: Color(0xFFFEF3DD),
  ),
  _SeriesLevel(
    difficulty: Difficulty.b2,
    label: 'Niveau B2',
    subtitle: 'Challenge — 25 questions par lot',
    lotSize: 25,
    accent: AppColors.red,
    accentBg: AppColors.redLight,
  ),
];

class TcfQcmDetailScreen extends ConsumerStatefulWidget {
  const TcfQcmDetailScreen({super.key, required this.module});

  final TcfQcmModule module;

  @override
  ConsumerState<TcfQcmDetailScreen> createState() =>
      _TcfQcmDetailScreenState();
}

class _TcfQcmDetailScreenState extends ConsumerState<TcfQcmDetailScreen> {
  bool _starting = false;
  _DetailTab _tab = _DetailTab.series;

  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated && auth.user.canAccessModule(AppModule.tcf);
  }

  /// Démarre un entraînement standard 25 Q sur le module (sans filtre niveau)
  /// — accroché au bouton du bas. Le tap niveau, lui, push vers l'écran lots
  /// (cf. `_LevelCard.onTap`).
  Future<void> _startStandard() async {
    if (_starting) return;
    final isPremium = _isPremium();

    setState(() => _starting = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;

    try {
      final attempt = await ref.read(attemptsRepositoryProvider).start(
            StartAttemptRequest(
              type: AttemptType.training,
              module: AppModule.tcf,
              questionType: isPremium ? widget.module.questionType : null,
              size: isPremium ? kInitialBatchSize : null,
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

  void _openLevel(_SeriesLevel level) {
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
    final route = AppRoutes.tcfLevelLots
        .replaceFirst(':moduleKey', widget.module.routeKey)
        .replaceFirst(':level', level.difficulty.wire.toLowerCase());
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final mod = widget.module;
    final statsAsync = ref.watch(_tcfStatsProvider);

    final tcfStats = statsAsync.maybeWhen(
      data: (s) {
        final correct = s.byTheme.fold<int>(0, (sum, t) => sum + t.correct);
        final total = s.byTheme.fold<int>(0, (sum, t) => sum + t.total);
        return (
          percent: total == 0 ? 0 : ((correct / total) * 100).round(),
          attempts: s.attemptsTotal,
        );
      },
      orElse: () => (percent: 0, attempts: 0),
    );

    final auth = ref.watch(authControllerProvider);
    final target = auth is AuthAuthenticated
        ? auth.user.targetProcedure?.tcfLevel
        : null;
    final niveauLabel = target == null ? 'A2-B2' : 'Cible $target';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                ModuleDetailTopBar(
                  onBack: () => context.pop(),
                  icon: mod.icon,
                  iconColor: AppColors.red,
                  iconBg: AppColors.redLight,
                ),
                const SizedBox(height: 22),
                ModuleDetailTitle(eyebrow: mod.eyebrow, title: mod.title),
                const SizedBox(height: 22),
                ModuleDetailHero(
                  icon: mod.icon,
                  headline: mod.headline,
                  description: mod.description,
                  gradient: const [AppColors.red, AppColors.redDark],
                ),
                const SizedBox(height: 16),
                ModuleDetailStats(
                  items: [
                    (value: '$kInitialBatchSize', label: 'Questions'),
                    (value: mod.durationLabel, label: 'Durée'),
                    (value: niveauLabel, label: 'Niveau'),
                  ],
                ),
                const SizedBox(height: 14),
                ModuleDetailScoreCard(
                  percent: tcfStats.percent,
                  attemptsCount: tcfStats.attempts,
                  accent: AppColors.red,
                ),
                const SizedBox(height: 18),
                ModuleDetailTabs(
                  labels: const ['Séries', 'Examens', 'Erreurs'],
                  activeIndex: _tab.index,
                  onChanged: (i) =>
                      setState(() => _tab = _DetailTab.values[i]),
                  accent: AppColors.red,
                ),
                const SizedBox(height: 14),
                _TabContent(
                  tab: _tab,
                  onLevelTap: _openLevel,
                ),
                if (_tab == _DetailTab.series) ...[
                  const SizedBox(height: 18),
                  AppButton(
                    label: 'Commencer l\'entraînement',
                    icon: Icons.play_arrow_rounded,
                    isLoading: _starting,
                    onPressed: _starting ? null : _startStandard,
                  ),
                ],
              ],
            ),
            if (_starting)
              const Positioned.fill(
                child: ModuleDetailStartingOverlay(accent: AppColors.red),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({required this.tab, required this.onLevelTap});

  final _DetailTab tab;
  final ValueChanged<_SeriesLevel> onLevelTap;

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case _DetailTab.series:
        return Column(
          children: [
            for (final level in _seriesLevels)
              _LevelCard(level: level, onTap: () => onLevelTap(level)),
          ],
        );
      case _DetailTab.exams:
        return const ModuleDetailTabPlaceholder(
          icon: Icons.timer_outlined,
          title: 'Examens blancs CO/CE',
          description:
              'Simulations 25 questions et examen aléatoire arrivent dans la prochaine itération.',
        );
      case _DetailTab.errors:
        return const ModuleDetailTabPlaceholder(
          icon: Icons.warning_amber_rounded,
          title: 'Révision des erreurs',
          description:
              'La revue de tes questions ratées (avec création de série ciblée) arrive bientôt.',
        );
    }
  }
}

/// Une carte de niveau dans l'onglet Séries : chip niveau coloré + libellé +
/// sous-titre + chevron. Tap → push l'écran de la liste des lots de ce niveau.
class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.onTap});

  final _SeriesLevel level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: level.accent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      level.difficulty.wire,
                      style: AppFonts.jakarta(
                        size: 16,
                        weight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          level.label,
                          style: AppFonts.jakarta(
                            size: 16,
                            weight: FontWeight.w800,
                            color: AppColors.ink,
                          ).copyWith(letterSpacing: -0.2),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          level.subtitle,
                          style: AppFonts.jakarta(
                            size: 12.5,
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: level.accentBg,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: level.accent,
                      size: 20,
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
}
