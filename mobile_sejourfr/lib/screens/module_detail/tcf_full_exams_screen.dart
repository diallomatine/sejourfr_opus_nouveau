import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/models/full_tcf_exam.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/utils/start_failure.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/stat_value_card.dart';
import '../tcf_production/widgets/exam_info_chips.dart';
import '../tcf_production/widgets/exam_slot/full_exam_slot_card.dart';
import 'tcf_full_exam_briefing_sheet.dart';
import 'widgets/exam_done_sheet.dart';

/// Liste des examens blancs TCF complets de l'utilisateur. Chaque examen
/// passé est affiché avec son niveau CECRL plancher, sa date et son statut.
/// Tap :
/// - {@code COMPLETED} / {@code PENDING_EVALUATIONS} → petite modale
///   (Refaire / Voir le détail), comme les examens module et les séries
/// - {@code IN_PROGRESS} → reprend l'examen sur le hub de progression
/// - Bouton "Lancer un nouvel examen" → briefing modal + POST `/api/full-tcf-exams`
///
/// **Distinction backend** : ces examens sont conceptuellement séparés des
/// examens module (CO seul / CE seul) — `attempts.epreuve = TCF_COMPLET`
/// vs `attempts.module_exam_question_type`. L'historique ne se mélange jamais.
final fullExamsHistoryProvider =
    FutureProvider.autoDispose<List<FullTcfExamSummary>>((ref) {
  return ref.watch(fullTcfExamRepositoryProvider).listMine(limit: 50);
});

/// 20 slots disponibles, comme un cahier d'examens blancs. Au-delà, on
/// continue à pouvoir lancer mais on n'affiche plus de slot supplémentaire
/// — l'historique reste consultable via les premiers slots (rotation
/// chronologique : slot 1 = examen le plus ancien).
const int _fullExamSlotsCount = 20;

/// Nombre de slots affichés d'emblée. Au-delà, un bouton « Voir les examens
/// X à Y » déplie le reste (même pattern que les examens blancs Civique).
const int _visibleByDefault = 8;

/// Écran plein des examens blancs TCF complets, avec topbar + back. Atteint
/// depuis le hero Progression, l'historique, le bilan et le hero examen blanc
/// du hub TCF (`AppRoutes.tcfFullExams`). `TcfFullExamsView` (le corps) est
/// le bloc réutilisable des 20 slots.
class TcfFullExamsScreen extends StatelessWidget {
  const TcfFullExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: _TopBar(onBack: () => _back(context)),
            ),
            const Expanded(child: TcfFullExamsView()),
          ],
        ),
      ),
    );
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.reviser);
    }
  }
}

/// Corps réutilisable des 20 slots d'examens blancs TCF complets. Rendu sous
/// la topbar de `TcfFullExamsScreen` (route `/tcf/examens-blancs`).
class TcfFullExamsView extends ConsumerWidget {
  const TcfFullExamsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(fullExamsHistoryProvider);
    final auth = ref.watch(authControllerProvider);
    final isPremium = auth is AuthAuthenticated &&
        auth.user.canAccessModule(AppModule.tcf);

    Future<void> startNew(int slot) async {
      final auth = ref.read(authControllerProvider);
      final isPremium = auth is AuthAuthenticated &&
          auth.user.canAccessModule(AppModule.tcf);
      ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
      // Compte gratuit : examen 1 offert (EE/EO évaluées une fois) ; les examens
      // 2+ restent premium. L'examen 1 reste rejouable (EE/EO verrouillées au
      // refaire, géré côté backend).
      if (!isPremium && slot > 1) {
        showPaywallSheet(context);
        return;
      }
      showTcfFullExamBriefingSheet(
        context,
        slot: slot,
        isFreeAccount: !isPremium,
        onStart: () async {
          try {
            final exam = await ref
                .read(fullTcfExamRepositoryProvider)
                .start(slotNumber: slot);
            if (!context.mounted) return;
            // Force le re-fetch de l'historique quand on revient ici plus tard.
            ref.invalidate(fullExamsHistoryProvider);
            context.go(
              AppRoutes.tcfFullExamProgress
                  .replaceFirst(':parentId', exam.id),
            );
          } catch (e) {
            if (!context.mounted) return;
            // Le backend applique le verrou des slots 2+ : un 403 ouvre le
            // paywall au lieu d'une erreur technique (statut premium périmé
            // côté client, abonnement expiré en cours de session).
            showPaywallOrError(context, e);
          }
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: () async {
        ref.invalidate(fullExamsHistoryProvider);
        await ref.read(fullExamsHistoryProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _ResultStats(history: historyAsync.valueOrNull ?? const []),
          const SizedBox(height: 14),
          const ExamInfoChips(
            accent: AppColors.red,
            soft: AppColors.redLight,
            items: [
              (icon: LucideIcons.zap, label: 'Simulation réelle'),
              (icon: LucideIcons.clock, label: '≈ 1 h 30'),
              (
                icon: LucideIcons.layoutGrid,
                label: '4 épreuves CO · CE · EE · EO'
              ),
              (icon: LucideIcons.graduationCap, label: 'Score final CECRL'),
            ],
          ),
          const SizedBox(height: 20),
          historyAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _ErrorBox(
              message: e.toString(),
              onRetry: () => ref.invalidate(fullExamsHistoryProvider),
            ),
            data: (history) => _SlotsSection(
              history: history,
              isPremium: isPremium,
              onTapDone: (exam) => _openExam(context, exam, startNew),
              onTapEmpty: startNew,
            ),
          ),
        ],
      ),
    );
  }

  void _openExam(
    BuildContext context,
    FullTcfExamSummary exam,
    void Function(int slot) startNew,
  ) {
    // En cours : on reprend directement le hub de progression (ce n'est pas
    // un examen « déjà fait »).
    if (exam.status == FullTcfExamStatus.inProgress) {
      context.go(
        AppRoutes.tcfFullExamProgress.replaceFirst(':parentId', exam.id),
      );
      return;
    }
    // Terminé / éval IA en cours : même petite modale que les examens module
    // et les séries → Refaire (nouvelle session sur le slot) ou Voir le détail
    // (bilan). Plus d'ouverture directe du rapport.
    final slot = exam.slotNumber;
    final level = exam.finalCecrlLevel;
    final subtitle = exam.status == FullTcfExamStatus.pendingEvaluations
        ? 'Évaluation IA en cours'
        : (level != null ? 'Dernier niveau : ${_shortLevel(level)}' : 'Terminé');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => ExamDoneSheet(
        title: slot != null ? 'Examen blanc $slot' : 'Examen blanc',
        subtitle: subtitle,
        accent: AppColors.red,
        onViewDetail: () {
          Navigator.of(sheetCtx).pop();
          // push (pas go) : le bilan se pose au-dessus de la liste → le back
          // du bilan revient bien à la page précédente, pas à Réviser.
          context.push(
            AppRoutes.tcfFullExamBilan.replaceFirst(':parentId', exam.id),
          );
        },
        onResume: () {
          Navigator.of(sheetCtx).pop();
          if (slot != null) startNew(slot);
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onBack,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              alignment: Alignment.center,
              child: const Icon(LucideIcons.chevronLeft,
                  size: 22, color: AppColors.ink),
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.blueLight,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'TCF IRN',
            style: AppFonts.ui(
              size: 12,
              weight: FontWeight.w800,
              color: AppColors.blue,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// 3 stat cards de résultats (cf. `MExamens` maquette) : meilleur niveau,
/// dernier examen, examens terminés. Calculées sur l'historique des examens
/// complets évalués.
class _ResultStats extends StatelessWidget {
  const _ResultStats({required this.history});

  final List<FullTcfExamSummary> history;

  @override
  Widget build(BuildContext context) {
    final completed = history
        .where((e) =>
            e.status == FullTcfExamStatus.completed &&
            e.finalCecrlLevel != null)
        .toList();
    NiveauCecrl? best;
    for (final e in completed) {
      final l = e.finalCecrlLevel!;
      if (best == null || l.scaleIndex > best.scaleIndex) best = l;
    }
    // Historique trié chrono DESC côté backend → le premier terminé = dernier passé.
    final last = completed.isEmpty ? null : completed.first.finalCecrlLevel;
    final doneSlots = history.map((e) => e.slotNumber).whereType<int>().toSet();

    return Row(
      children: [
        Expanded(
          child: StatValueCard(
            value: best == null ? '—' : _shortLevel(best),
            label: 'Meilleur niveau',
            color: AppColors.red,
            valueSize: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatValueCard(
            value: last == null ? '—' : _shortLevel(last),
            label: 'Dernier examen',
            valueSize: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatValueCard(
            value: '${doneSlots.length}/$_fullExamSlotsCount',
            label: 'Terminés',
            color: AppColors.red,
            valueSize: 20,
          ),
        ),
      ],
    );
  }
}

String _shortLevel(NiveauCecrl l) => switch (l) {
      NiveauCecrl.a1NonAtteint => '<A1',
      _ => l.displayName,
    };

/// Section principale : 20 slots numérotés, comme l'onglet Examens du
/// détail TCF QCM/EE/EO. Les examens passés sont triés ASC (le plus ancien
/// occupe le slot 1) et remplissent les slots de gauche à droite. Les slots
/// restants sont vides (clic = nouvelle session).
class _SlotsSection extends StatefulWidget {
  const _SlotsSection({
    required this.history,
    required this.isPremium,
    required this.onTapDone,
    required this.onTapEmpty,
  });

  final List<FullTcfExamSummary> history;
  /// Abonné TCF : tous les slots ouverts. Gratuit : seul le slot 1 est jouable
  /// (examen offert), les slots 2+ affichent un cadenas → paywall.
  final bool isPremium;
  final void Function(FullTcfExamSummary) onTapDone;
  final void Function(int slot) onTapEmpty;

  @override
  State<_SlotsSection> createState() => _SlotsSectionState();
}

class _SlotsSectionState extends State<_SlotsSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    // Group by slot_number (cf. V110) : dernier essai par slot. Refait le
    // slot N → nouvel attempt slot_number=N qui écrase l'ancien dans la grille.
    final bySlot = <int, FullTcfExamSummary>{};
    for (final e in widget.history) {
      if (e.slotNumber == null) continue;
      bySlot.putIfAbsent(e.slotNumber!, () => e);
    }

    final visibleCount =
        _showAll ? _fullExamSlotsCount : _visibleByDefault;
    final hiddenCount = _fullExamSlotsCount - visibleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Tes examens', style: AppFonts.display(size: 17)),
            const Spacer(),
            Text(
              '$_fullExamSlotsCount disponibles',
              style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < visibleCount; i++) ...[
          _ExamSlotCard(
            slot: i + 1,
            exam: bySlot[i + 1],
            locked: !widget.isPremium && i + 1 > 1,
            onTapDone: widget.onTapDone,
            onTapEmpty: () => widget.onTapEmpty(i + 1),
          ),
          if (i != visibleCount - 1) const SizedBox(height: 10),
        ],
        if (hiddenCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextButton.icon(
              onPressed: () => setState(() => _showAll = true),
              icon: Text(
                'Voir les examens ${visibleCount + 1} à $_fullExamSlotsCount',
                style: AppFonts.ui(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.red,
                ),
              ),
              label: const Icon(LucideIcons.chevronDown,
                  size: 16, color: AppColors.red),
            ),
          ),
      ],
    );
  }
}

/// Une card slot (cf. `MExamens` maquette) : chip numéro 50 px — plein
/// accent quand l'examen est passé (rouge terminé, ambre en cours, bleu en
/// évaluation IA) ; à droite pill « Fait », play, spinner ou cadenas.
class _ExamSlotCard extends StatelessWidget {
  const _ExamSlotCard({
    required this.slot,
    required this.exam,
    required this.onTapDone,
    required this.onTapEmpty,
    this.locked = false,
  });

  final int slot;
  final FullTcfExamSummary? exam;
  /// Slot réservé à l'abonnement (compte gratuit, slot > 1) : cadenas + paywall.
  final bool locked;
  final void Function(FullTcfExamSummary) onTapDone;
  final VoidCallback onTapEmpty;

  Color get _accent => switch (exam?.status) {
        FullTcfExamStatus.inProgress => AppColors.amber,
        FullTcfExamStatus.pendingEvaluations => AppColors.blue,
        FullTcfExamStatus.completed => AppColors.red,
        null => AppColors.inkFaint,
      };

  @override
  Widget build(BuildContext context) {
    final done = exam != null;
    final lockedEmpty = locked && !done;
    final level = exam?.finalCecrlLevel;

    return FullExamSlotCard(
      slot: slot,
      filled: done,
      accent: _accent,
      title: 'Examen $slot',
      subtitle: _subtitle(lockedEmpty: lockedEmpty, level: level),
      subtitleColor: done ? _accent : AppColors.inkFaint,
      trailing: _trailing(lockedEmpty: lockedEmpty),
      lockedEmpty: lockedEmpty,
      onTap: done ? () => onTapDone(exam!) : onTapEmpty,
    );
  }

  String _subtitle({required bool lockedEmpty, required NiveauCecrl? level}) {
    final e = exam;
    if (e != null) {
      return switch (e.status) {
        FullTcfExamStatus.inProgress => 'En cours · Reprendre',
        FullTcfExamStatus.pendingEvaluations => 'Évaluation IA en cours',
        FullTcfExamStatus.completed => level != null
            ? 'Dernier niveau : ${_shortLevel(level)}'
            : 'Terminé',
      };
    }
    if (lockedEmpty) return 'Réservé à l\'abonnement Intégral';
    if (slot == 1) return 'Offert · 4 épreuves, 1 h 30';
    return 'Pas encore fait';
  }

  Widget _trailing({required bool lockedEmpty}) {
    final e = exam;
    if (e == null) {
      return Icon(
        lockedEmpty ? LucideIcons.lock : LucideIcons.chevronRight,
        size: 18,
        color: AppColors.inkFaint,
      );
    }
    switch (e.status) {
      case FullTcfExamStatus.inProgress:
        return const Icon(LucideIcons.circlePlay,
            color: AppColors.amber, size: 24);
      case FullTcfExamStatus.pendingEvaluations:
        return const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        );
      case FullTcfExamStatus.completed:
        return FullExamSlotCard.faitPill(AppColors.red,
            bg: AppColors.redLight);
    }
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.cloudOff,
              color: AppColors.red, size: 30),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.ui(color: AppColors.muted, size: 12.5),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Réessayer',
            variant: AppButtonVariant.secondary,
            fullWidth: false,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
