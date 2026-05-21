import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/paywall_sheet.dart';
import 'tcf_full_exam_briefing_sheet.dart';

const int _fullExamSlotsCount = 20;

/// Écran "Examens blancs TCF IRN" — liste 20 slots numérotés d'examens
/// blancs complets (chacun = CO + CE + EE + EO enchaînées, 90 min total).
/// Tap slot → briefing modal puis lancement (orchestration à venir).
///
/// **Important** : ces examens sont conceptuellement distincts des examens
/// module (CO seul ou CE seul) — le backend les sépare via
/// `attempts.epreuve = TCF_COMPLET` vs `attempts.module_exam_question_type`.
/// L'historique de chaque liste ne doit jamais être mélangé.
class TcfFullExamsScreen extends ConsumerWidget {
  const TcfFullExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void openBriefing(int slot) {
      final auth = ref.read(authControllerProvider);
      final isPremium = auth is AuthAuthenticated &&
          auth.user.canAccessModule(AppModule.tcf);
      ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
      if (!isPremium) {
        showPaywallSheet(context);
        return;
      }
      showTcfFullExamBriefingSheet(
        context,
        slot: slot,
        onStart: () {
          // Orchestration 4-épreuves enchaînées : arrive dans un lot dédié
          // (backend `POST /api/full-tcf-exams` + écran progression + bilan
          // agrégé). Pour l'instant on signale juste que c'est en cours.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Examen blanc complet bientôt disponible — l\'orchestration des 4 épreuves est en cours de finalisation.',
              ),
              backgroundColor: AppColors.blue,
              duration: Duration(seconds: 4),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            _TopBar(onBack: () => _back(context)),
            const SizedBox(height: 22),
            const _Hero(),
            const SizedBox(height: 16),
            const _Stats(),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  'Examens disponibles',
                  style: AppFonts.jakarta(
                    size: 16,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                  ).copyWith(letterSpacing: -0.2),
                ),
                const Spacer(),
                Text(
                  '$_fullExamSlotsCount slots',
                  style: AppFonts.mono(
                    size: 10,
                    color: AppColors.muted,
                    letterSpacing: 1.4,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (int i = 1; i <= _fullExamSlotsCount; i++)
              _FullExamSlotCard(
                slot: i,
                onTap: () => openBriefing(i),
              ),
          ],
        ),
      ),
    );
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.tcf);
    }
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
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: AppColors.ink,
              ),
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
            style: AppFonts.jakarta(
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

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // Hero rouge — convention SejourFR : tous les hero de la partie
          // TCF sont en rouge, distinct du bleu civique.
          colors: [AppColors.red, AppColors.redDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.red.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXAMENS BLANCS',
            style: AppFonts.mono(
              size: 10,
              color: AppColors.white.withValues(alpha: 0.85),
              letterSpacing: 1.8,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Simule le vrai',
            style: AppFonts.jakarta(
              size: 26,
              weight: FontWeight.w800,
              color: AppColors.white,
              height: 1.1,
            ).copyWith(letterSpacing: -0.5),
          ),
          Text(
            'TCF IRN',
            style: AppFonts.jakarta(
              size: 26,
              weight: FontWeight.w800,
              color: AppColors.white,
              height: 1.1,
            ).copyWith(letterSpacing: -0.5),
          ),
          const SizedBox(height: 10),
          Text(
            'Enchaîne les 4 épreuves (CO + CE + EE + EO) en conditions réelles. Score final en niveau CECRL.',
            style: AppFonts.jakarta(
              size: 13.5,
              color: AppColors.white.withValues(alpha: 0.9),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _StatCell(value: '$_fullExamSlotsCount', label: 'Examens')),
        SizedBox(width: 10),
        Expanded(child: _StatCell(value: '90', label: 'Minutes')),
        SizedBox(width: 10),
        Expanded(child: _StatCell(value: 'CECRL', label: 'Score final')),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppFonts.jakarta(
              size: 17,
              weight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppFonts.mono(
              size: 9.5,
              color: AppColors.muted,
              letterSpacing: 1.4,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card slot d'examen blanc complet. Pour cette itération tous restent
/// "Disponible" — l'historique des examens TCF_COMPLET passés sera affiché
/// quand l'orchestration sera branchée.
class _FullExamSlotCard extends StatelessWidget {
  const _FullExamSlotCard({required this.slot, required this.onTap});

  final int slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$slot',
                      style: AppFonts.jakarta(
                        size: 14,
                        weight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Examen blanc $slot',
                          style: AppFonts.jakarta(
                            size: 14.5,
                            weight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '4 épreuves · 90 min · CECRL',
                          style: AppFonts.jakarta(
                            size: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted2,
                    size: 22,
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
