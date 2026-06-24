import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
import '../../core/widgets/app_card.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/screen_header.dart';
import 'tcf_qcm_detail_screen.dart' show TcfQcmModule;
import 'widgets/lot_done_sheet.dart';
import 'widgets/serie_card.dart';
import 'widgets/module_detail_widgets.dart';

/// Couleur d'accent d'un niveau (chip + tint des séries faites).
class _LevelMeta {
  const _LevelMeta({required this.accent, required this.soft});

  final Color accent;
  final Color soft;
}

const _levelMetas = <Difficulty, _LevelMeta>{
  Difficulty.a2: _LevelMeta(accent: AppColors.green, soft: AppColors.greenLight),
  Difficulty.b1: _LevelMeta(accent: AppColors.amber, soft: AppColors.amberLight),
  Difficulty.b2: _LevelMeta(accent: AppColors.red, soft: AppColors.redLight),
};

/// Écran « Séries » d'un (module TCF QCM, niveau) — cf. `MSeries` maquette.
/// Une carte par lot : numéro en chip, badge meilleur score ou « Pas encore
/// commencé », cadenas paywall sur les séries 2+. Tap → POST attempts avec
/// `lotNumero` → runner en mode batch fixe.
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
  /// sinon → démarrage direct.
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
      builder: (sheetCtx) => LotDoneSheet(
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
              style: AppFonts.ui(size: 13, color: AppColors.white)),
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

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      final fallback = switch (widget.module) {
        TcfQcmModule.ce => AppRoutes.tcfCeDetail,
        TcfQcmModule.structure => AppRoutes.tcfStructureDetail,
        TcfQcmModule.co => AppRoutes.tcfCoDetail,
      };
      context.go(fallback);
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
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Séries',
              sub: '${mod.title} · ${widget.level.wire}',
              onBack: _back,
            ),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      lotsAsync.when(
                        loading: () => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: meta.accent),
                          ),
                        ),
                        error: (e, _) => AppCard(
                          child: Text(
                            ApiClient.toApiException(e).message,
                            style: AppFonts.ui(
                                size: 13, color: AppColors.inkSoft),
                          ),
                        ),
                        data: (lots) {
                          if (lots.isEmpty) {
                            return _Empty(
                                accent: meta.accent, level: widget.level);
                          }
                          return Column(
                            children: [
                              for (final lot in lots) ...[
                                SerieCard(
                                  lot: lot,
                                  accent: meta.accent,
                                  soft: meta.soft,
                                  locked: !isPremium && lot.numero > 1,
                                  onTap: () => _onLotTap(lot),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  if (_starting)
                    Positioned.fill(
                      child: ModuleDetailStartingOverlay(accent: meta.accent),
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

class _Empty extends StatelessWidget {
  const _Empty({required this.accent, required this.level});

  final Color accent;
  final Difficulty level;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      child: Column(
        children: [
          Icon(LucideIcons.hourglass, color: accent, size: 28),
          const SizedBox(height: 12),
          Text('Pas encore de série ${level.wire}',
              style: AppFonts.display(size: 16)),
          const SizedBox(height: 6),
          Text(
            'Le pool de questions ${level.wire} grossit régulièrement. Repasse plus tard.',
            textAlign: TextAlign.center,
            style: AppFonts.ui(
                size: 12.5, color: AppColors.inkSoft, height: 1.4),
          ),
        ],
      ),
    );
  }
}
