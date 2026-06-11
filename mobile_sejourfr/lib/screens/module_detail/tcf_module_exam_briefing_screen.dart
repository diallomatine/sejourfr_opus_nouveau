import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/paywall_sheet.dart';
import 'tcf_qcm_detail_screen.dart' show TcfQcmModule;

/// Briefing avant le démarrage d'un examen module TCF (CO ou CE). Présenté
/// en bottomsheet modal — plus léger qu'un push de route, garde le détail
/// module visible en arrière-plan. Reproduit le pattern du design HTML
/// (écran 4 du parcours TCF) en restant strictement dans la palette
/// bleu / blanc / rouge de SejourFR.
///
/// Au tap "Commencer maintenant" : ferme le sheet, POST /api/attempts,
/// puis push runner. Réservé premium TCF — 403 → showPaywallSheet.
class ModuleExamBriefingSheet extends ConsumerStatefulWidget {
  const ModuleExamBriefingSheet({
    super.key,
    required this.module,
    this.slotNumber,
  });

  final TcfQcmModule module;

  /// Slot d'examen visé dans la grille (1..10). Propagé au backend pour que
  /// refaire l'examen N préserve la position du slot N. Cf. V110.
  final int? slotNumber;

  @override
  ConsumerState<ModuleExamBriefingSheet> createState() =>
      _ModuleExamBriefingSheetState();
}

class _ModuleExamBriefingSheetState
    extends ConsumerState<ModuleExamBriefingSheet> {
  bool _starting = false;

  Future<void> _start() async {
    if (_starting) return;
    final auth = ref.read(authControllerProvider);
    final isPremium =
        auth is AuthAuthenticated && auth.user.canAccessModule(AppModule.tcf);
    if (!isPremium) {
      // On ferme le briefing avant de montrer le paywall pour éviter
      // l'empilement de deux sheets.
      Navigator.of(context).pop();
      showPaywallSheet(context);
      return;
    }

    setState(() => _starting = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;

    try {
      final attempt = await ref.read(attemptsRepositoryProvider).start(
            StartAttemptRequest(
              type: AttemptType.mockExam,
              module: AppModule.tcf,
              moduleExamQuestionType: widget.module.questionType,
              slotNumber: widget.slotNumber,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      // Le push runner se fait depuis le caller (le BuildContext du sheet
      // est en train d'être disposé après le pop) — on utilise le router
      // au niveau racine pour pousser.
      GoRouter.of(context).push(
        AppRoutes.runner.replaceFirst(':attemptId', attempt.id),
      );
    } catch (e) {
      if (!mounted) return;
      final apiErr = ApiClient.toApiException(e);
      if (apiErr.isForbidden) {
        Navigator.of(context).pop();
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
    final copy = _BriefingCopy.forModule(mod);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Row(
                    children: [
                      Text(
                        'EXAMEN ${mod.title.toUpperCase()}',
                        style: AppFonts.mono(
                          size: 9.5,
                          color: AppColors.muted,
                          letterSpacing: 1.8,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      _DurationBadge(label: copy.durationLabel),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _BriefingHero(
                    icon: copy.heroIcon,
                    title: copy.heroTitle,
                    description: copy.heroDescription,
                  ),
                  if (copy.notice != null) ...[
                    const SizedBox(height: 12),
                    _NoticeCard(text: copy.notice!),
                  ],
                  const SizedBox(height: 16),
                  _ConsignesCard(items: copy.consignes),
                  const SizedBox(height: 12),
                  _ConseilCard(text: copy.conseil),
                  const SizedBox(height: 22),
                  AppButton(
                    label: 'Commencer maintenant',
                    icon: LucideIcons.play,
                    isLoading: _starting,
                    onPressed: _starting ? null : _start,
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Annuler',
                    variant: AppButtonVariant.ghost,
                    onPressed: _starting
                        ? null
                        : () => Navigator.of(context).pop(),
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

/// Helper : ouvre le briefing en bottomsheet modal.
/// `slotNumber` sert à stabiliser la numérotation côté grille examens
/// (refaire le slot N → nouvel attempt avec slot_number=N).
void showModuleExamBriefingSheet(
  BuildContext context,
  TcfQcmModule module, {
  int? slotNumber,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ModuleExamBriefingSheet(
      module: module,
      slotNumber: slotNumber,
    ),
  );
}

class _ConsigneLine {
  const _ConsigneLine({required this.label, required this.icon});

  final String label;
  final String icon;
}

/// Textes du briefing dérivés du module. Centralise les variations entre CO,
/// CE et STRUCTURE (durée, hero, consignes, conseil) — évite les ternaires
/// imbriqués dans `build()`. `notice` est non-null uniquement pour STRUCTURE
/// (rappel : module hors TCF IRN).
class _BriefingCopy {
  const _BriefingCopy({
    required this.durationLabel,
    required this.heroIcon,
    required this.heroTitle,
    required this.heroDescription,
    required this.consignes,
    required this.conseil,
    this.notice,
  });

  final String durationLabel;
  final IconData heroIcon;
  final String heroTitle;
  final String heroDescription;
  final List<_ConsigneLine> consignes;
  final String conseil;
  final String? notice;

  static _BriefingCopy forModule(TcfQcmModule mod) {
    switch (mod.questionType) {
      case QuestionType.co:
        return const _BriefingCopy(
          durationLabel: '20 min',
          heroIcon: LucideIcons.headphones,
          heroTitle: 'Prêt à écouter ?',
          heroDescription:
              'Tu vas répondre à 25 questions audio. Chaque document peut être écouté une seule fois, comme en condition d\'examen.',
          consignes: [
            _ConsigneLine(label: '1 audio par question', icon: '🎧'),
            _ConsigneLine(label: '4 réponses possibles', icon: 'ABCD'),
            _ConsigneLine(label: 'Pas de retour en arrière', icon: '⏭'),
            _ConsigneLine(label: 'Correction à la fin', icon: '✅'),
          ],
          conseil:
              'Lis rapidement les réponses avant d\'écouter. Concentre-toi sur l\'idée principale, pas chaque mot.',
        );
      case QuestionType.ce:
        return const _BriefingCopy(
          durationLabel: '35 min',
          heroIcon: LucideIcons.bookOpen,
          heroTitle: 'Prêt à lire ?',
          heroDescription:
              'Tu vas répondre à 25 questions sur textes courts. Lis attentivement avant de choisir, comme en condition d\'examen.',
          consignes: [
            _ConsigneLine(label: '1 texte par question', icon: '📖'),
            _ConsigneLine(label: '4 réponses possibles', icon: 'ABCD'),
            _ConsigneLine(label: 'Pas de retour en arrière', icon: '⏭'),
            _ConsigneLine(label: 'Correction à la fin', icon: '✅'),
          ],
          conseil:
              'Repère les mots-clés de la question avant de lire le texte. Une seule réponse est correcte.',
        );
      case QuestionType.structure:
        return const _BriefingCopy(
          durationLabel: '20 min',
          heroIcon: LucideIcons.spellCheck,
          heroTitle: 'Prêt à analyser ?',
          heroDescription:
              'Tu vas répondre à 25 questions de grammaire et de lexique : conjugaison, accords, prépositions, connecteurs.',
          consignes: [
            _ConsigneLine(label: '1 phrase à compléter', icon: '✏️'),
            _ConsigneLine(label: '4 réponses possibles', icon: 'ABCD'),
            _ConsigneLine(label: 'Pas de retour en arrière', icon: '⏭'),
            _ConsigneLine(label: 'Correction à la fin', icon: '✅'),
          ],
          conseil:
              'Lis la phrase entière avant de choisir : le bon mot dépend souvent du contexte autour du trou.',
          notice:
              'La structure de la langue n\'est pas évaluée au TCF IRN officiel. Cet entraînement reste très utile pour renforcer ta grammaire.',
        );
      case QuestionType.connaissance:
      case QuestionType.miseSituation:
      case QuestionType.coImage:
        // Ces types ne sont pas exposés via le briefing module exam (cf.
        // validation backend `startModuleExam`). Garde un fallback pour
        // l'exhaustivité du switch.
        return const _BriefingCopy(
          durationLabel: '20 min',
          heroIcon: LucideIcons.circleHelp,
          heroTitle: 'Prêt à commencer ?',
          heroDescription: '25 questions à enchaîner sans retour en arrière.',
          consignes: [
            _ConsigneLine(label: '4 réponses possibles', icon: 'ABCD'),
            _ConsigneLine(label: 'Pas de retour en arrière', icon: '⏭'),
            _ConsigneLine(label: 'Correction à la fin', icon: '✅'),
          ],
          conseil: 'Lis chaque question attentivement avant de répondre.',
        );
    }
  }
}

/// Bandeau d'avertissement rendu sous le hero quand le module n'est pas
/// officiellement évalué au TCF IRN (cf. STRUCTURE).
class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blueLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.info,
              color: AppColors.blue,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppFonts.ui(
                size: 12.5,
                color: AppColors.ink2,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BriefingHero extends StatelessWidget {
  const _BriefingHero({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 30, color: AppColors.white),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppFonts.ui(
              size: 22,
              weight: FontWeight.w800,
              color: AppColors.white,
              height: 1.15,
            ).copyWith(letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: AppFonts.ui(
              size: 13.5,
              color: AppColors.white.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  const _DurationBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.timer, size: 13, color: AppColors.blue),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppFonts.ui(
              size: 12,
              weight: FontWeight.w800,
              color: AppColors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsignesCard extends StatelessWidget {
  const _ConsignesCard({required this.items});

  final List<_ConsigneLine> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONSIGNES',
            style: AppFonts.mono(
              size: 9.5,
              color: AppColors.muted,
              letterSpacing: 1.8,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < items.length; i++) ...[
            _ConsigneRow(line: items[i]),
            if (i != items.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ConsigneRow extends StatelessWidget {
  const _ConsigneRow({required this.line});

  final _ConsigneLine line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              line.label,
              style: AppFonts.ui(
                size: 13.5,
                color: AppColors.ink2,
                weight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            line.icon,
            style: AppFonts.ui(size: 16, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ConseilCard extends StatelessWidget {
  const _ConseilCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        // Rouge léger en accent secondaire (palette française : on évite
        // d'empiler du bleu partout sur ce sheet).
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.lightbulb,
                size: 14,
                color: AppColors.red,
              ),
              const SizedBox(width: 6),
              Text(
                'CONSEIL',
                style: AppFonts.mono(
                  size: 9.5,
                  color: AppColors.red,
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppFonts.ui(
              size: 13,
              color: AppColors.ink2,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
