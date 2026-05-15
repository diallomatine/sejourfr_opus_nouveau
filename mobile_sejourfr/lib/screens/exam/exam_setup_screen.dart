import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/exam_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/eyebrow.dart';
import '../home/widgets/module_switch.dart';

/// Liste des examens blancs publiés pour le module actif. Le filtre module
/// est dérivé de [selectedModuleProvider] (toggle dans l'AppBar).
final examsByModuleProvider =
    FutureProvider.autoDispose.family<List<ExamTemplateSummary>, AppModule>(
  (ref, module) => ref.watch(examsRepositoryProvider).list(module: module),
);

/// L'écran exam dans le shell : remplace l'ancien ExamSetupScreen (start direct
/// au hasard) par la vitrine des 40 examens blancs. Le démarrage passe
/// désormais par un briefing en bottom sheet et un examTemplateId.
class ExamSetupScreen extends ConsumerStatefulWidget {
  const ExamSetupScreen({super.key});

  @override
  ConsumerState<ExamSetupScreen> createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends ConsumerState<ExamSetupScreen> {
  bool _starting = false;

  Future<void> _startExam(ExamTemplateSummary exam) async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final attempt = await ref.read(attemptsRepositoryProvider).start(
            StartAttemptRequest(
              type: AttemptType.mockExam,
              module: exam.module,
              examTemplateId: exam.id,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop(); // ferme le briefing
      context.push(AppRoutes.runner.replaceFirst(':attemptId', attempt.id));
    } catch (e) {
      final apiErr = ApiClient.toApiException(e);
      if (!mounted) return;
      Navigator.of(context).pop(); // ferme le briefing
      if (apiErr.isForbidden) {
        _showPaywall();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErr.message), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _showBriefing(ExamTemplateSummary exam) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BriefingSheet(
        exam: exam,
        starting: _starting,
        onStart: () => _startExam(exam),
      ),
    );
  }

  void _showPaywall() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PaywallSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final module = ref.watch(selectedModuleProvider);
    final examsAsync = ref.watch(examsByModuleProvider(module));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(examsByModuleProvider(module)),
          child: examsAsync.when(
            loading: () => const _LoadingList(),
            error: (e, _) => _ErrorList(
              message: ApiClient.toApiException(e).message,
              onRetry: () => ref.invalidate(examsByModuleProvider(module)),
            ),
            data: (exams) => _ExamListView(
              exams: exams,
              onTap: _showBriefing,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header + liste
// ---------------------------------------------------------------------------

class _ExamListView extends StatelessWidget {
  const _ExamListView({required this.exams, required this.onTap});

  final List<ExamTemplateSummary> exams;
  final void Function(ExamTemplateSummary) onTap;

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return const _EmptyList();
    }
    final sorted = [...exams]..sort((a, b) => a.position.compareTo(b.position));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const _Header(),
        const SizedBox(height: 14),
        const ModuleSwitch(),
        const SizedBox(height: 18),
        ...sorted.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ExamCard(exam: e, onTap: () => onTap(e)),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Examens blancs', color: AppColors.red),
        const SizedBox(height: 10),
        Text(
          'En conditions réelles',
          style: AppFonts.fraunces(
            size: 30,
            weight: FontWeight.w600,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '1 examen gratuit par module. Les autres se débloquent avec l\'abonnement Premium.',
          style: AppFonts.jakarta(
            size: 13.5,
            color: AppColors.muted,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam, required this.onTap});

  final ExamTemplateSummary exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppTag(
                      label: exam.module == AppModule.civique ? 'Civique' : 'TCF IRN',
                      tone: exam.module == AppModule.civique ? TagTone.blue : TagTone.red,
                    ),
                    const Spacer(),
                    AppTag(
                      label: exam.free ? 'Gratuit' : '🔒 Premium',
                      tone: exam.free ? TagTone.success : TagTone.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  exam.name,
                  style: AppFonts.fraunces(
                    size: 17,
                    weight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                if (exam.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    exam.subtitle!,
                    style: AppFonts.mono(
                      size: 11,
                      color: AppColors.muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 13, color: AppColors.muted2),
                    const SizedBox(width: 4),
                    Text(
                      exam.targetLabel,
                      style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.help_outline_rounded, size: 13, color: AppColors.muted2),
                    const SizedBox(width: 4),
                    Text(
                      '${exam.totalQuestions} Q',
                      style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.schedule_rounded, size: 13, color: AppColors.muted2),
                    const SizedBox(width: 4),
                    Text(
                      '${exam.durationMinutes} min',
                      style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: exam.free ? AppColors.red : AppColors.muted2,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet briefing
// ---------------------------------------------------------------------------

class _BriefingSheet extends StatelessWidget {
  const _BriefingSheet({
    required this.exam,
    required this.starting,
    required this.onStart,
  });

  final ExamTemplateSummary exam;
  final bool starting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final isTcf = exam.module == AppModule.tcf;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  AppTag(
                    label: isTcf ? 'TCF IRN' : 'Civique',
                    tone: isTcf ? TagTone.red : TagTone.blue,
                  ),
                  const SizedBox(width: 6),
                  AppTag(
                    label: exam.free ? 'Gratuit' : 'Premium',
                    tone: exam.free ? TagTone.success : TagTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                exam.name,
                style: AppFonts.fraunces(
                  size: 22,
                  weight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              if (exam.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  exam.description!,
                  style: AppFonts.jakarta(
                    size: 13,
                    color: AppColors.ink2,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _BriefingStatsRow(exam: exam),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isTcf
                            ? 'Le diagnostic TCF estime votre niveau CECRL (A2 / B1 / B2) à partir de vos bonnes réponses par strate.'
                            : 'Une seule bonne réponse par question. Le chronomètre démarre dès que vous lancez l\'examen.',
                        style: AppFonts.jakarta(
                          size: 12.5,
                          color: AppColors.ink2,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppButton(
                label: starting ? 'Préparation…' : 'Démarrer l\'examen',
                icon: Icons.timer_rounded,
                variant: AppButtonVariant.danger,
                isLoading: starting,
                onPressed: starting ? null : onStart,
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Annuler',
                  style: AppFonts.jakarta(size: 13, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BriefingStatsRow extends StatelessWidget {
  const _BriefingStatsRow({required this.exam});

  final ExamTemplateSummary exam;

  @override
  Widget build(BuildContext context) {
    final isTcf = exam.module == AppModule.tcf;
    final stats = [
      _Stat('Questions', '${exam.totalQuestions}'),
      _Stat('Durée', '${exam.durationMinutes} min'),
      _Stat(
        isTcf ? 'Restitution' : 'Seuil',
        isTcf ? 'Niveau CECRL' : '${exam.passingScore}/${exam.totalQuestions}',
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          Expanded(child: _StatCell(stat: stats[i])),
          if (i < stats.length - 1)
            Container(width: 1, height: 36, color: AppColors.line),
        ],
      ],
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value);
  final String label;
  final String value;
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          stat.value,
          textAlign: TextAlign.center,
          style: AppFonts.fraunces(
            size: 18,
            weight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          stat.label,
          style: AppFonts.mono(
            size: 9,
            color: AppColors.muted,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Paywall
// ---------------------------------------------------------------------------

class _PaywallSheet extends StatelessWidget {
  const _PaywallSheet();

  static const _checkoutUrl = 'https://sejourfr.fr/paiement';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline, color: AppColors.red, size: 28),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Examen réservé aux abonnés',
                textAlign: TextAlign.center,
                style: AppFonts.fraunces(size: 22, weight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                'Débloquez tous les examens blancs et l\'entraînement illimité avec un abonnement Premium. La souscription se fait sur le web pour éviter les commissions des stores.',
                textAlign: TextAlign.center,
                style: AppFonts.jakarta(
                  size: 13,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'M\'abonner sur sejourfr.fr',
                icon: Icons.open_in_new_rounded,
                variant: AppButtonVariant.danger,
                onPressed: () async {
                  await Clipboard.setData(const ClipboardData(text: _checkoutUrl));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Lien copié : $_checkoutUrl',
                        style: AppFonts.jakarta(color: AppColors.white, size: 13),
                      ),
                      backgroundColor: AppColors.ink,
                    ),
                  );
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Plus tard',
                  style: AppFonts.jakarta(size: 13, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// États de chargement / erreur / vide
// ---------------------------------------------------------------------------

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: const [
        _Header(),
        SizedBox(height: 14),
        ModuleSwitch(),
        SizedBox(height: 60),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ErrorList extends StatelessWidget {
  const _ErrorList({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const _Header(),
        const SizedBox(height: 28),
        Center(
          child: Column(
            children: [
              const Icon(Icons.cloud_off_outlined,
                  color: AppColors.red, size: 40),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppFonts.jakarta(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Réessayer',
                variant: AppButtonVariant.secondary,
                fullWidth: false,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const _Header(),
        const SizedBox(height: 14),
        const ModuleSwitch(),
        const SizedBox(height: 48),
        Center(
          child: Text(
            'Aucun examen blanc publié pour ce module.',
            style: AppFonts.jakarta(color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}
