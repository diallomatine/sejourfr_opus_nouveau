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

/// Une série d'entraînement TCF QCM = un sous-ensemble du pool de questions
/// filtré par niveau de difficulté. Permet de scaffolder l'apprentissage
/// alors qu'à l'examen réel toutes les questions sont mélangées.
class _TcfSeries {
  const _TcfSeries({
    required this.index,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.size,
  });

  final int index;
  final String title;
  final String description;
  final Difficulty difficulty;
  final int size;
}

const _tcfSeries = <_TcfSeries>[
  _TcfSeries(
    index: 1,
    title: 'Série découverte',
    description: '10 questions · niveau A2 · ≈ 8 min',
    difficulty: Difficulty.a2,
    size: 10,
  ),
  _TcfSeries(
    index: 2,
    title: 'Série intermédiaire',
    description: '15 questions · niveau B1 · ≈ 12 min',
    difficulty: Difficulty.b1,
    size: 15,
  ),
  _TcfSeries(
    index: 3,
    title: 'Questions difficiles',
    description: '15 questions · niveau B2 · ≈ 15 min',
    difficulty: Difficulty.b2,
    size: 15,
  ),
];

final _tcfStatsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  return ref.watch(userContentRepositoryProvider).stats(module: AppModule.tcf);
});

enum _DetailTab { series, exams, errors }

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

  /// Démarre un attempt TCF QCM. Si `series` est fourni, l'attempt est
  /// filtré par sa difficulté ; sinon c'est un attempt 25 Q standard.
  /// En démo (non premium) : seul le démarrage standard est autorisé, les
  /// séries déclenchent un paywall (le backend ignorerait le filtre).
  Future<void> _start({_TcfSeries? series}) async {
    if (_starting) return;
    final isPremium = _isPremium();

    if (series != null && !isPremium) {
      showPaywallSheet(context);
      return;
    }

    setState(() => _starting = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;

    try {
      final attempt = await ref.read(attemptsRepositoryProvider).start(
            StartAttemptRequest(
              type: AttemptType.training,
              module: AppModule.tcf,
              questionType: isPremium ? widget.module.questionType : null,
              difficulty: isPremium ? series?.difficulty : null,
              size: isPremium ? (series?.size ?? kInitialBatchSize) : kDemoBatchSize,
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

  @override
  Widget build(BuildContext context) {
    final mod = widget.module;
    final statsAsync = ref.watch(_tcfStatsProvider);
    final isPremium = _isPremium();

    // Maîtrise globale TCF (somme byTheme) en attendant un découpage par
    // épreuve côté backend.
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
                  isPremium: isPremium,
                  onStartSeries: (s) => _start(series: s),
                ),
                if (_tab == _DetailTab.series) ...[
                  const SizedBox(height: 18),
                  AppButton(
                    label: 'Commencer l\'entraînement',
                    icon: Icons.play_arrow_rounded,
                    isLoading: _starting,
                    onPressed: _starting ? null : () => _start(),
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
  const _TabContent({
    required this.tab,
    required this.isPremium,
    required this.onStartSeries,
  });

  final _DetailTab tab;
  final bool isPremium;
  final ValueChanged<_TcfSeries> onStartSeries;

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case _DetailTab.series:
        return Column(
          children: [
            for (final s in _tcfSeries)
              ModuleDetailSeriesCard(
                index: s.index,
                title: s.title,
                description: s.description,
                accent: AppColors.red,
                locked: !isPremium,
                onTap: () => onStartSeries(s),
              ),
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
