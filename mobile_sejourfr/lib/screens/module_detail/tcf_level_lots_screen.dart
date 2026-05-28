import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/lot_models.dart';
import '../../core/providers/lots_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/paywall_sheet.dart';
import 'tcf_qcm_detail_screen.dart' show TcfQcmModule;
import 'widgets/module_detail_widgets.dart';

/// Métadonnées d'un niveau TCF : couleur d'accent, libellé, taille de lot
/// indicative. La taille effective vient du backend (cf. `LotDto.totalQuestions`)
/// — celle-ci ne sert qu'à l'affichage des stats avant le chargement.
class _LevelMeta {
  const _LevelMeta({
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.accentDark,
    required this.indicativeLotSize,
  });

  final String label;
  final String subtitle;
  final Color accent;
  final Color accentDark;
  final int indicativeLotSize;
}

const _levelMetas = <Difficulty, _LevelMeta>{
  Difficulty.a2: _LevelMeta(
    label: 'Niveau débutant',
    subtitle: 'Bases — phrases simples et situations courantes.',
    accent: AppColors.green,
    accentDark: Color(0xFF0E6D43),
    indicativeLotSize: 15,
  ),
  Difficulty.b1: _LevelMeta(
    label: 'Niveau intermédiaire',
    subtitle: 'Intermédiaire — situations du quotidien étendues.',
    accent: AppColors.amber,
    accentDark: Color(0xFFB47A0E),
    indicativeLotSize: 20,
  ),
  Difficulty.b2: _LevelMeta(
    label: 'Niveau avancée',
    subtitle: 'Challenge — textes longs et argumentation.',
    accent: AppColors.red,
    accentDark: AppColors.redDark,
    indicativeLotSize: 25,
  ),
};

/// Écran de la liste des lots pour (module TCF QCM, niveau). Push depuis
/// l'onglet Séries du détail module. Tap d'un lot → POST attempts avec
/// lotNumero → push runner.
class TcfLevelLotsScreen extends ConsumerStatefulWidget {
  const TcfLevelLotsScreen({
    super.key,
    required this.module,
    required this.level,
  });

  final TcfQcmModule module;
  final Difficulty level;

  @override
  ConsumerState<TcfLevelLotsScreen> createState() => _TcfLevelLotsScreenState();
}

class _TcfLevelLotsScreenState extends ConsumerState<TcfLevelLotsScreen> {
  bool _starting = false;

  bool _isPremium() {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated &&
        auth.user.canAccessModule(AppModule.tcf);
  }

  /// Tap sur un lot : si déjà fait → sheet `Voir le détail` / `Reprendre`,
  /// sinon → démarrage direct comme avant.
  void _onLotTap(LotDto lot) {
    if (lot.alreadyAttempted) {
      _openLotDoneSheet(lot);
    } else {
      _startLot(lot);
    }
  }

  void _openLotDoneSheet(LotDto lot) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _LotDoneSheet(
        lot: lot,
        accent: _levelMetas[widget.level]!.accent,
        onViewDetail: () {
          Navigator.of(sheetCtx).pop();
          _openLotReport(lot);
        },
        onResume: () {
          Navigator.of(sheetCtx).pop();
          _startLot(lot);
        },
      ),
    );
  }

  /// « Comme un examen » : on pousse le rapport Q-par-Q (`ExamReportScreen`)
  /// plutôt que le bilan synthétique `TcfLotResultScreen`. Nécessite que le
  /// backend retourne `lot.lastAttemptId` (cf. LotDto/LotService).
  void _openLotReport(LotDto lot) {
    final id = lot.lastAttemptId;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Détail indisponible — le serveur n\'a pas encore fourni la référence.',
              style: AppFonts.jakarta(size: 13, color: AppColors.white)),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }
    context.push(AppRoutes.examReport.replaceFirst(':attemptId', id));
  }

  Future<void> _startLot(LotDto lot) async {
    if (_starting) return;
    // Lot 1 = découverte gratuite par (module, niveau) — accessible aux
    // non-abonnés. Lot 2+ → paywall.
    if (!_isPremium() && lot.numero > 1) {
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
              questionType: widget.module.questionType,
              // TCF uniquement → difficulty toujours présente.
              difficulty: lot.difficulty!,
              lotNumero: lot.numero,
            ),
          );
      if (!mounted) return;
      // On annote le push avec le contexte du lot : le runner relira ces
      // query params à la fin pour pousser vers `TcfLotResultScreen` au
      // lieu d'afficher le dialog de fin d'entraînement standard.
      final runnerPath =
          AppRoutes.runner.replaceFirst(':attemptId', attempt.id);
      context.push(
        '$runnerPath?from=tcfLot'
        '&moduleKey=${widget.module.routeKey}'
        '&level=${widget.level.wire.toLowerCase()}',
      );
    } catch (e) {
      if (!mounted) return;
      final apiErr = ApiClient.toApiException(e);
      if (apiErr.isForbidden) {
        showPaywallSheet(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(apiErr.message), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mod = widget.module;
    final meta = _levelMetas[widget.level]!;
    final isPremium = _isPremium();
    final lotsAsync = ref.watch(lotsProvider(LotsKey(
      questionType: mod.questionType,
      difficulty: widget.level,
    )));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                ModuleDetailTopBar(
                  // L'écran peut être atteint via `context.go` depuis le bilan
                  // de lot — dans ce cas la pile est vide et `pop` crashe.
                  // On retombe sur le détail module en fallback.
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      final fallback = switch (mod) {
                        TcfQcmModule.ce => AppRoutes.tcfCeDetail,
                        TcfQcmModule.structure => AppRoutes.tcfStructureDetail,
                        TcfQcmModule.co => AppRoutes.tcfCoDetail,
                      };
                      context.go(fallback);
                    }
                  },
                  icon: mod.icon,
                  iconColor: meta.accent,
                  iconBg: meta.accent.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 22),
                ModuleDetailTitle(
                  eyebrow: 'Module TCF · ${mod.title}',
                  title: meta.label,
                ),
                const SizedBox(height: 16),
                ModuleDetailStats(
                  items: [
                    (
                      value: '${lotsAsync.valueOrNull?.length ?? 0}',
                      label: 'Lots',
                    ),
                    (
                      value: '${meta.indicativeLotSize}',
                      label: 'Q. par lot',
                    ),
                    (value: widget.level.wire, label: 'Niveau'),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Lots disponibles',
                  style: AppFonts.jakarta(
                    size: 15,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                  ).copyWith(letterSpacing: -0.2),
                ),
                const SizedBox(height: 12),
                lotsAsync.when(
                  loading: () => _Loading(accent: meta.accent),
                  error: (e, _) => _Error(
                    accent: meta.accent,
                    message: ApiClient.toApiException(e).message,
                  ),
                  data: (lots) {
                    if (lots.isEmpty) {
                      return _Empty(meta: meta, level: widget.level);
                    }
                    return Column(
                      children: [
                        for (final lot in lots)
                          ModuleDetailSeriesCard(
                            index: lot.numero,
                            title: 'Lot ${lot.numero}',
                            description: lot.alreadyAttempted
                                ? '${lot.totalQuestions} questions · déjà fait'
                                : '${lot.totalQuestions} questions · ${meta.label.toLowerCase()}',
                            accent: meta.accent,
                            // Lot 1 = découverte gratuite par (module, niveau) ;
                            // Lot 2+ réservés aux abonnés TCF.
                            locked: !isPremium && lot.numero > 1,
                            scoreBadge: lot.lastScore == null
                                ? null
                                : '${lot.lastScore}/${lot.totalQuestions}',
                            scoreColor: _colorForScore(lot),
                            onTap: () => _onLotTap(lot),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
            if (_starting)
              Positioned.fill(
                child: ModuleDetailStartingOverlay(accent: meta.accent),
              ),
          ],
        ),
      ),
    );
  }

  /// Couleur du tint + badge "déjà fait" d'un lot, fonction du ratio score :
  /// rouge < 40 %, ambre 40–69 %, vert ≥ 70 %. Renvoie null quand le lot n'a
  /// pas encore été tenté (le widget retombe alors sur l'accent du niveau).
  Color? _colorForScore(LotDto lot) {
    if (lot.lastScore == null || lot.totalQuestions == 0) return null;
    final ratio = lot.lastScore! / lot.totalQuestions;
    if (ratio >= 0.7) return AppColors.green;
    if (ratio >= 0.4) return AppColors.amber;
    return AppColors.red;
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: accent),
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.accent, required this.message});

  final Color accent;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: AppFonts.jakarta(size: 12.5, color: AppColors.muted),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.meta, required this.level});

  final _LevelMeta meta;
  final Difficulty level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty_rounded, color: meta.accent, size: 28),
          const SizedBox(height: 12),
          Text(
            'Pas encore de lot ${level.wire}',
            style: AppFonts.jakarta(
              size: 14,
              weight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Le pool de questions ${level.wire} grossit régulièrement. Repasse plus tard.',
            textAlign: TextAlign.center,
            style: AppFonts.jakarta(
              size: 12.5,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Sheet « Lot déjà fait » : Voir le détail / Reprendre
// ============================================================================

class _LotDoneSheet extends StatelessWidget {
  const _LotDoneSheet({
    required this.lot,
    required this.accent,
    required this.onViewDetail,
    required this.onResume,
  });

  final LotDto lot;
  final Color accent;
  final VoidCallback onViewDetail;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final score = lot.lastScore;
    final total = lot.totalQuestions;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.line2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Lot ${lot.numero}',
                style: AppFonts.jakarta(
                    size: 18, weight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              if (score != null)
                Text(
                  'Dernier score : $score / $total',
                  style: AppFonts.jakarta(size: 12.5, color: AppColors.muted),
                ),
              const SizedBox(height: 18),
              _LotSheetButton(
                label: 'Voir le détail',
                icon: Icons.description_outlined,
                background: accent.withValues(alpha: 0.10),
                foreground: accent,
                onPressed: onViewDetail,
              ),
              const SizedBox(height: 10),
              _LotSheetButton(
                label: 'Reprendre',
                icon: Icons.refresh_rounded,
                background: AppColors.red,
                foreground: AppColors.white,
                onPressed: onResume,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LotSheetButton extends StatelessWidget {
  const _LotSheetButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
                Text(label,
                    style: AppFonts.jakarta(
                        size: 14, weight: FontWeight.w800, color: foreground)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
