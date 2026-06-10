import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/query_propagation.dart';
import '../../core/widgets/app_button.dart';
import 'audio_recorder_service.dart';
import 'eo_session_controller.dart';
import 'widgets/consigne_card.dart';
import 'widgets/preparation_points.dart';
import 'widgets/production_app_header.dart';
import 'widgets/production_progress_strip.dart';

/// Briefing EO (Ecran 01 du mockup). Charge la session, affiche la consigne
/// de la tache courante + conseils, et lance l'enregistrement au tap "Commencer".
class EoBriefingScreen extends ConsumerStatefulWidget {
  const EoBriefingScreen({super.key, required this.taskIndex});

  final int taskIndex;

  @override
  ConsumerState<EoBriefingScreen> createState() => _EoBriefingScreenState();
}

class _EoBriefingScreenState extends ConsumerState<EoBriefingScreen> {
  bool _requestingPerm = false;

  String _niveauForUser() {
    final auth = ref.read(authControllerProvider);
    if (auth is AuthAuthenticated) {
      final tp = auth.user.targetProcedure;
      if (tp != null) return tp.tcfLevel;
    }
    return 'B1';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Contexte examen blanc complet : sous-attempt EO déjà créé par le
      // backend, on le reprend au lieu d'en créer un nouveau.
      final goState = GoRouterState.of(context);
      final fullExamId = goState.uri.queryParameters['fullExamId'];
      final subAttemptId = goState.uri.queryParameters['subAttemptId'];
      if (fullExamId != null && subAttemptId != null) {
        ref.read(eoSessionProvider.notifier).startInFullExam(
              subAttemptId: subAttemptId,
              niveau: _niveauForUser(),
            );
      } else {
        // Une session déjà en cours (ex: sujet unique lancé via startSingle
        // depuis la fiche) est respectée — on ne la remplace pas par un
        // examen 3-tâches. On ne démarre que s'il n'y a rien (deep-link).
        final current = ref.read(eoSessionProvider).value;
        if (current == null || !current.isStarted || current.isCompleted) {
          ref.read(eoSessionProvider.notifier).start(niveau: _niveauForUser());
        }
      }
    });
  }

  Future<void> _start(BuildContext context) async {
    final recorder = ref.read(recordingControllerProvider.notifier);
    setState(() => _requestingPerm = true);
    final status = await recorder.requestPermission();
    if (!context.mounted) return;
    setState(() => _requestingPerm = false);
    if (status.isGranted) {
      context.push(
        withCurrentQuery(
          context,
          '/tcf/expression-orale/t/${widget.taskIndex}/enregistrement',
        ),
      );
      return;
    }
    // Refus -- 1re fois OU deja "permanently denied" : dans les deux cas on
    // propose un detour par les Reglages systeme (sur iOS, request() ne re-pop
    // jamais le dialog apres un premier refus).
    _showPermissionDeniedSheet(context, status);
  }

  void _showPermissionDeniedSheet(BuildContext context, PermissionStatus status) {
    final canOpenSettings = status.isPermanentlyDenied || status.isDenied || status.isRestricted;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Acces au microphone requis'),
        content: Text(
          status.isPermanentlyDenied
              ? "Vous avez refuse l'acces au microphone. "
                  'Activez-le dans les Reglages > Confidentialite > Microphone > SejourFR.'
              : "SejourFR a besoin d'acceder au microphone pour vous entrainer "
                  "a l'expression orale.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard'),
          ),
          if (canOpenSettings)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(recordingControllerProvider.notifier).openSystemSettings();
              },
              child: const Text('Ouvrir les Reglages'),
            ),
        ],
      ),
    );
  }

  /// Diallo
  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(eoSessionProvider);
    final goState = GoRouterState.of(context);
    final fullExamId = goState.uri.queryParameters['fullExamId'];
    final fallbackRoute = fullExamId != null
        ? '/tcf/examen-blanc/$fullExamId'
        : '/tcf/eo';
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: ProductionAppHeader(
        title: 'Expression orale',
        fallbackRoute: fallbackRoute,
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBox(
          message: ApiClient.toApiException(e).message,
          onRetry: () {
            final goState = GoRouterState.of(context);
            final fullExamId = goState.uri.queryParameters['fullExamId'];
            final subAttemptId = goState.uri.queryParameters['subAttemptId'];
            if (fullExamId != null && subAttemptId != null) {
              ref.read(eoSessionProvider.notifier).startInFullExam(
                    subAttemptId: subAttemptId,
                    niveau: _niveauForUser(),
                  );
            } else {
              ref.read(eoSessionProvider.notifier).start(niveau: _niveauForUser());
            }
          },
        ),
        data: (session) {
          final task = session.taskAt(widget.taskIndex);
          if (!session.isStarted || task == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              ProductionProgressStrip(
                current: widget.taskIndex + 1,
                total: session.totalTasks,
                niveau: task.niveauCible,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                  children: [
                    ConsigneCard(
                      consigne: task.consigne,
                      subTitleHero: task.displayTitle,
                      subtitle: _durationLabel(task.dureeMaxSec),
                      accent: AppColors.red,
                      soft: AppColors.redLight,
                    ),
                    PreparationCard(isEo: true, tache: task.tacheNumero),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.line2, width: 1),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: SafeArea(
                  top: false,
                  child: AppButton(
                    label: 'Commencer',
                    icon: LucideIcons.mic,
                    isLoading: _requestingPerm,
                    onPressed: _requestingPerm ? null : () => _start(context),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _durationLabel(int? sec) {
    if (sec == null || sec <= 0) return 'Durée libre';
    final mins = sec ~/ 60;
    final remain = sec % 60;
    if (remain == 0) return 'Durée attendue : $mins minutes';
    return 'Durée attendue : $mins min $remain s';
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.circleAlert, size: 32, color: AppColors.red),
          const SizedBox(height: 8),
          Text(
            'Impossible de demarrer la session.',
            style: AppFonts.ui(
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Reessayer',
            onPressed: onRetry,
            icon: LucideIcons.refreshCw,
          ),
        ],
      ),
    );
  }
}
