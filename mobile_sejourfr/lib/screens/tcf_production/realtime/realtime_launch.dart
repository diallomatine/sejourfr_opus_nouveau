import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/repositories.dart';
import '../../../core/models/billing_models.dart';
import '../../../core/models/realtime_models.dart';
import '../../../core/widgets/paywall_sheet.dart';
import 'realtime_launch_sheet.dart';

/// Issue de la négociation du mode d'une tâche EO T1/T2.
enum RealtimeDecision { realtime, classic, cancelled }

class RealtimeNegotiation {
  const RealtimeNegotiation(this.decision, {this.descriptor, this.attemptId});

  final RealtimeDecision decision;
  final RealtimeSessionDescriptor? descriptor;
  final String? attemptId;

  static const classic = RealtimeNegotiation(RealtimeDecision.classic);
  static const cancelled = RealtimeNegotiation(RealtimeDecision.cancelled);
}

/// Négocie le mode d'une tâche EO T1/T2, partagé entre l'entraînement isolé et
/// le parcours d'examen : lit le quota, propose le choix (modal §2.3) et — si
/// « temps réel » — résout l'attempt puis démarre la session côté backend.
///
/// Retourne :
/// - [RealtimeDecision.realtime] avec le descripteur prêt + l'attempt ;
/// - [RealtimeDecision.classic] pour basculer sur l'enregistrement classique ;
/// - [RealtimeDecision.cancelled] si le modal a été fermé sans choix.
///
/// Tout échec (quota indisponible, fallback async, erreur réseau) retombe en
/// classique — le candidat n'est jamais bloqué. [resolveAttemptId] n'est appelé
/// QUE si l'utilisateur choisit le temps réel (pas d'attempt orphelin sinon).
Future<RealtimeNegotiation> negotiateRealtimeSession(
  BuildContext context,
  WidgetRef ref, {
  required String productionTaskId,
  required Future<String?> Function() resolveAttemptId,
}) async {
  final repo = ref.read(realtimeRepositoryProvider);
  RealtimeQuota quota;
  try {
    quota = await repo.getQuota();
  } catch (_) {
    return RealtimeNegotiation.classic;
  }
  if (!context.mounted) return RealtimeNegotiation.classic;

  // Le modal s'ouvre TOUJOURS (abonné ou non) : pour un non-abonné la carte
  // temps réel est verrouillée et ouvre le paywall (incitation à s'abonner).
  final choice = await showRealtimeLaunchSheet(
    context,
    remaining: quota.remaining,
    cap: quota.cap,
  );
  if (choice == null) return RealtimeNegotiation.cancelled;
  if (choice == RealtimeLaunchChoice.paywall) {
    if (context.mounted) {
      await showPaywallSheet(context, initialTarget: PlanModuleTarget.integral);
    }
    return RealtimeNegotiation.cancelled;
  }
  if (choice == RealtimeLaunchChoice.classic || !context.mounted) {
    return RealtimeNegotiation.classic;
  }

  final attemptId = await resolveAttemptId();
  if (attemptId == null || !context.mounted) {
    return RealtimeNegotiation.classic;
  }

  try {
    final descriptor = await repo.startSession(
      productionTaskId: productionTaskId,
      attemptId: attemptId,
    );
    if (!descriptor.isRealtime) return RealtimeNegotiation.classic;
    return RealtimeNegotiation(
      RealtimeDecision.realtime,
      descriptor: descriptor,
      attemptId: attemptId,
    );
  } catch (_) {
    return RealtimeNegotiation.classic;
  }
}
