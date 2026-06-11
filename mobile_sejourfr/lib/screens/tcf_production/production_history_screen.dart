import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import 'widgets/history_session_card.dart';
import 'widgets/production_app_header.dart';

/// Charge l'historique des submissions de l'utilisateur pour une epreuve.
/// Limit haute (200) car on groupe ensuite par attempt -> ~60 sessions max.
final _historyProvider = FutureProvider.autoDispose
    .family<List<ProductionSubmissionDto>, EpreuveType>((ref, epreuve) {
  return ref.watch(productionRepositoryProvider).listMine(epreuve: epreuve, limit: 200);
});

/// Ecran d'entree pour EE / EO : liste des sessions passees + bouton pour
/// demarrer une nouvelle session. Si l'utilisateur n'a rien fait, empty state.
class ProductionHistoryScreen extends ConsumerWidget {
  const ProductionHistoryScreen({super.key, required this.epreuve});

  final EpreuveType epreuve;

  String get _moduleTitle =>
      epreuve == EpreuveType.tcfEo ? 'Expression orale' : 'Expression écrite';

  /// Route vers le détail module (parent de cet écran d'historique depuis
  /// la suppression du `ProductionHubScreen` — la sélection T1/T2/T3 vit
  /// désormais sur l'onglet Tâches du détail).
  String _hubRoute() =>
      epreuve == EpreuveType.tcfEo ? '/tcf/eo' : '/tcf/ee';

  String _sessionRoute(String attemptId) => epreuve == EpreuveType.tcfEo
      ? '/tcf/expression-orale/sessions/$attemptId'
      : '/tcf/expression-ecrite/sessions/$attemptId';

  /// Route vers le rapport detaille d'une submission unique (entrainement libre).
  String _singleReportRoute(ProductionSubmissionDto sub) {
    final base = epreuve == EpreuveType.tcfEo
        ? '/tcf/expression-orale/resultats'
        : '/tcf/expression-ecrite/resultats';
    final tache = sub.tacheNumero ?? 1;
    return '$base/${sub.id}?taskIndex=${tache - 1}&history=1';
  }

  /// Une session 1-tache (entrainement libre) ouvre directement le rapport de
  /// la tache ; une session multi-tache (examen blanc) ouvre la vue session.
  void _openSession(
      BuildContext context, List<ProductionSubmissionDto> subs, String attemptId) {
    if (subs.length == 1) {
      context.push(_singleReportRoute(subs.first));
    } else {
      context.push(_sessionRoute(attemptId));
    }
  }

  /// "Nouvelle tache" : retour au hub pour choisir T1/T2/T3.
  void _goToHub(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_hubRoute());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_historyProvider(epreuve));
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: ProductionAppHeader(
        title: _moduleTitle,
        rightAction: IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(LucideIcons.plus, size: 24),
          color: AppColors.blue,
          tooltip: 'Nouvelle session',
          onPressed: () => _goToHub(context),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBox(
          message: ApiClient.toApiException(e).message,
          onRetry: () => ref.invalidate(_historyProvider(epreuve)),
        ),
        data: (submissions) {
          final sessions = _groupByAttempt(submissions);
          if (sessions.isEmpty) {
            return _EmptyState(
              epreuve: epreuve,
              onStart: () => _goToHub(context),
            );
          }
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.blue,
                  onRefresh: () async {
                    ref.invalidate(_historyProvider(epreuve));
                    await ref.read(_historyProvider(epreuve).future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                    children: [
                      Text(
                        'Vos sessions',
                        style: AppFonts.ui(
                          size: 17,
                          weight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sessions.length} session${sessions.length > 1 ? "s" : ""} · les plus recentes en premier',
                        style: AppFonts.ui(size: 12.5, color: AppColors.muted),
                      ),
                      const SizedBox(height: 14),
                      for (final entry in sessions)
                        HistorySessionCard(
                          submissions: entry.value,
                          onTap: () => _openSession(context, entry.value, entry.key),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(top: BorderSide(color: AppColors.line2, width: 1)),
                ),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: SafeArea(
                  top: false,
                  child: AppButton(
                    label: 'Commencer une nouvelle session',
                    icon: LucideIcons.plus,
                    onPressed: () => _goToHub(context),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Groupe les submissions par attemptId. Retourne une liste triee par date
  /// de derniere submission (DESC) pour avoir les sessions les plus recentes
  /// en haut.
  List<MapEntry<String, List<ProductionSubmissionDto>>> _groupByAttempt(
      List<ProductionSubmissionDto> all) {
    final byAttempt = <String, List<ProductionSubmissionDto>>{};
    for (final s in all) {
      final id = s.attemptId;
      if (id == null) continue;
      byAttempt.putIfAbsent(id, () => []).add(s);
    }
    final entries = byAttempt.entries.toList();
    entries.sort((a, b) {
      final dA = a.value
          .map((s) => s.submittedAt)
          .reduce((x, y) => x.isAfter(y) ? x : y);
      final dB = b.value
          .map((s) => s.submittedAt)
          .reduce((x, y) => x.isAfter(y) ? x : y);
      return dB.compareTo(dA);
    });
    return entries;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.epreuve, required this.onStart});

  final EpreuveType epreuve;
  final VoidCallback onStart;

  bool get _isAudio => epreuve == EpreuveType.tcfEo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.blueLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _isAudio ? LucideIcons.mic : LucideIcons.penLine,
                      size: 36,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isAudio
                        ? "Aucune session orale pour l'instant"
                        : "Aucune session ecrite pour l'instant",
                    style: AppFonts.display(
                      size: 20,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isAudio
                        ? "Enregistrez vous sur 3 taches pour recevoir une evaluation IA detaillee."
                        : "Redigez 3 textes pour recevoir une evaluation IA detaillee.",
                    style: AppFonts.ui(
                      size: 13,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.line2, width: 1)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: SafeArea(
            top: false,
            child: AppButton(
              label: 'Commencer ma premiere session',
              icon: _isAudio ? LucideIcons.mic : LucideIcons.penLine,
              onPressed: onStart,
            ),
          ),
        ),
      ],
    );
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
            'Impossible de charger votre historique',
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
