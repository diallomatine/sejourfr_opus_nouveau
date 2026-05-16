import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/enums.dart';
import '../../core/models/exam_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/tcf_paywall.dart';
import '../home/widgets/module_switch.dart';

/// Liste des examens blancs publiés pour le module actif. Le filtre module
/// est dérivé de [selectedModuleProvider] (toggle dans le header).
final examsByModuleProvider =
    FutureProvider.autoDispose.family<List<ExamTemplateSummary>, AppModule>(
  (ref, module) => ref.watch(examsRepositoryProvider).list(module: module),
);

/// Écran "Examens blancs". Liste les 40 examens publiés, avec verrouillage
/// visuel sur les non-gratuits si l'utilisateur n'est pas abonné (1 examen
/// gratuit par module fait office d'aperçu, le reste pousse au paywall).
class ExamSetupScreen extends ConsumerStatefulWidget {
  const ExamSetupScreen({super.key});

  @override
  ConsumerState<ExamSetupScreen> createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends ConsumerState<ExamSetupScreen> {
  bool _starting = false;

  bool get _isPremium {
    final auth = ref.read(authControllerProvider);
    return auth is AuthAuthenticated && auth.user.isPremium;
  }

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

  void _onExamTap(ExamTemplateSummary exam, int number) {
    if (!exam.free && !_isPremium) {
      _showPaywall();
      return;
    }
    _showBriefing(exam, number);
  }

  void _showBriefing(ExamTemplateSummary exam, int number) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.42),
      builder: (_) => _BriefingSheet(
        exam: exam,
        number: number,
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
      barrierColor: AppColors.ink.withValues(alpha: 0.42),
      builder: (_) => const _PaywallSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final module = ref.watch(selectedModuleProvider);
    final examsAsync = ref.watch(examsByModuleProvider(module));
    final auth = ref.watch(authControllerProvider);
    final isPremium = auth is AuthAuthenticated && auth.user.isPremium;
    final tcfBlocked = module == AppModule.tcf &&
        auth is AuthAuthenticated &&
        !auth.user.canAccessModule(AppModule.tcf);

    if (tcfBlocked) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: const [
              SizedBox(height: 8),
              ModuleSwitch(),
              SizedBox(height: 22),
              TcfPaywallCard(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.blue,
          onRefresh: () async => ref.invalidate(examsByModuleProvider(module)),
          child: examsAsync.when(
            loading: () => const _LoadingList(),
            error: (e, _) => _ErrorList(
              message: ApiClient.toApiException(e).message,
              onRetry: () => ref.invalidate(examsByModuleProvider(module)),
            ),
            data: (exams) => _ExamListView(
              exams: exams,
              isPremium: isPremium,
              onTap: _onExamTap,
              onUpgradeTap: _showPaywall,
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
  const _ExamListView({
    required this.exams,
    required this.isPremium,
    required this.onTap,
    required this.onUpgradeTap,
  });

  final List<ExamTemplateSummary> exams;
  final bool isPremium;
  final void Function(ExamTemplateSummary, int) onTap;
  final VoidCallback onUpgradeTap;

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return const _EmptyList();
    }
    final sorted = [...exams]..sort((a, b) => a.position.compareTo(b.position));
    // Numéro affiché "Examen blanc N" : on numérote dans l'ordre de la liste
    // triée par position (1-indexé), peu importe free / premium.
    final numbers = <String, int>{
      for (var i = 0; i < sorted.length; i++) sorted[i].id: i + 1,
    };
    final free = sorted.where((e) => e.free).toList();
    final premium = sorted.where((e) => !e.free).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        const _Header(),
        const SizedBox(height: 16),
        const ModuleSwitch(),
        const SizedBox(height: 22),
        if (!isPremium) ...[
          _UpsellBanner(onTap: onUpgradeTap),
          const SizedBox(height: 18),
        ],
        if (free.isNotEmpty) ...[
          const _SectionLabel('Accès libre'),
          const SizedBox(height: 10),
          ...free.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FreeExamCard(
                exam: e,
                number: numbers[e.id]!,
                onTap: () => onTap(e, numbers[e.id]!),
              ),
            ),
          ),
        ],
        if (premium.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const _SectionLabel('Examens Premium'),
              const Spacer(),
              Text(
                '${premium.length} examens',
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.muted2,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...premium.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PremiumExamCard(
                exam: e,
                number: numbers[e.id]!,
                locked: !isPremium,
                onTap: () => onTap(e, numbers[e.id]!),
              ),
            ),
          ),
        ],
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
          'Le jour J,\nen conditions réelles',
          style: AppFonts.fraunces(
            size: 30,
            weight: FontWeight.w600,
            height: 1.06,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '1 examen offert par module. Le reste se débloque avec l’abonnement.',
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        '§ ${text.toUpperCase()}',
        style: AppFonts.mono(
          size: 10,
          color: AppColors.muted,
          letterSpacing: 2.0,
        ).copyWith(height: 1.0, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bandeau d'upsell
// ---------------------------------------------------------------------------

class _UpsellBanner extends StatelessWidget {
  const _UpsellBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.blue, AppColors.blueDark],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned(
                  right: -28,
                  top: -28,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.08),
                        width: 14,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  top: 18,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.red,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: const Icon(
                          Icons.lock_open_rounded,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Débloquer tous les examens',
                              style: AppFonts.jakarta(
                                size: 14.5,
                                weight: FontWeight.w800,
                                color: AppColors.white,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '40 examens blancs · entraînement illimité',
                              style: AppFonts.jakarta(
                                size: 11.5,
                                color: AppColors.white.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ],
                  ),
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
// Carte d'examen — version "Free" (accent visuel)
// ---------------------------------------------------------------------------

class _FreeExamCard extends StatelessWidget {
  const _FreeExamCard({
    required this.exam,
    required this.number,
    required this.onTap,
  });

  final ExamTemplateSummary exam;
  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTcf = exam.module == AppModule.tcf;
    final accent = isTcf ? AppColors.red : AppColors.blue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.18), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isTcf ? AppColors.redLight : AppColors.blueLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isTcf ? Icons.headphones_rounded : Icons.flag_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppTag(label: 'Offert', tone: TagTone.success),
                        const SizedBox(width: 6),
                        AppTag(
                          label: isTcf ? 'TCF IRN' : 'Civique',
                          tone: isTcf ? TagTone.red : TagTone.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'EXAMEN BLANC ${number.toString().padLeft(2, '0')}',
                      style: AppFonts.mono(
                        size: 10,
                        color: accent,
                        letterSpacing: 1.8,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exam.name,
                      style: AppFonts.fraunces(
                        size: 17,
                        weight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _MetaRow(exam: exam),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.white,
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
// Carte d'examen — version "Premium" (verrouillée ou non)
// ---------------------------------------------------------------------------

class _PremiumExamCard extends StatelessWidget {
  const _PremiumExamCard({
    required this.exam,
    required this.number,
    required this.locked,
    required this.onTap,
  });

  final ExamTemplateSummary exam;
  final int number;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTcf = exam.module == AppModule.tcf;
    final accent = isTcf ? AppColors.red : AppColors.blue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: locked ? 0.92 : 1.0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              color: locked ? AppColors.blueSoft : AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: locked ? AppColors.line : accent.withValues(alpha: 0.16),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: locked
                        ? AppColors.line2
                        : (isTcf ? AppColors.redLight : AppColors.blueLight),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    locked
                        ? Icons.lock_rounded
                        : (isTcf
                            ? Icons.headphones_rounded
                            : Icons.flag_rounded),
                    color: locked ? AppColors.muted : accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXAMEN BLANC ${number.toString().padLeft(2, '0')}',
                        style: AppFonts.mono(
                          size: 9.5,
                          color: locked ? AppColors.muted2 : accent,
                          letterSpacing: 1.6,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        exam.name,
                        style: AppFonts.jakarta(
                          size: 14,
                          weight: FontWeight.w700,
                          color: locked ? AppColors.ink2 : AppColors.ink,
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _MetaRow(exam: exam, compact: true),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (locked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          size: 12,
                          color: AppColors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Premium',
                          style: AppFonts.mono(
                            size: 9,
                            color: AppColors.amber,
                            letterSpacing: 1.2,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: AppColors.muted2,
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
// Ligne meta (target / nb questions / durée)
// ---------------------------------------------------------------------------

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.exam, this.compact = false});

  final ExamTemplateSummary exam;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = compact ? AppColors.muted2 : AppColors.muted;
    final size = compact ? 11.5 : 12.0;
    final iconSize = compact ? 12.0 : 13.0;
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MetaItem(
          icon: Icons.flag_outlined,
          label: exam.targetLabel,
          color: color,
          size: size,
          iconSize: iconSize,
        ),
        _MetaItem(
          icon: Icons.help_outline_rounded,
          label: '${exam.totalQuestions} Q',
          color: color,
          size: size,
          iconSize: iconSize,
        ),
        _MetaItem(
          icon: Icons.schedule_rounded,
          label: '${exam.durationMinutes} min',
          color: color,
          size: size,
          iconSize: iconSize,
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.size,
    required this.iconSize,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppFonts.jakarta(size: size, color: color)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet briefing
// ---------------------------------------------------------------------------

class _BriefingSheet extends StatelessWidget {
  const _BriefingSheet({
    required this.exam,
    required this.number,
    required this.starting,
    required this.onStart,
  });

  final ExamTemplateSummary exam;
  final int number;
  final bool starting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final isTcf = exam.module == AppModule.tcf;
    final accent = isTcf ? AppColors.red : AppColors.blue;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 18),
              Row(
                children: [
                  AppTag(
                    label: isTcf ? 'TCF IRN' : 'Civique',
                    tone: isTcf ? TagTone.red : TagTone.blue,
                  ),
                  const SizedBox(width: 6),
                  AppTag(
                    label: exam.free ? 'Offert' : 'Premium',
                    tone: exam.free ? TagTone.success : TagTone.amber,
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.blueSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'EXAMEN BLANC ${number.toString().padLeft(2, '0')}',
                style: AppFonts.mono(
                  size: 10.5,
                  color: accent,
                  letterSpacing: 1.8,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                exam.name,
                style: AppFonts.fraunces(
                  size: 24,
                  weight: FontWeight.w600,
                  height: 1.18,
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
              const SizedBox(height: 20),
              _BriefingStatsRow(exam: exam),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.blueLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isTcf
                            ? 'Le diagnostic TCF estime votre niveau CECRL (A2 / B1 / B2) à partir de vos bonnes réponses par strate.'
                            : 'Une seule bonne réponse par question. Le chronomètre démarre dès que vous lancez l’examen.',
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
                label: starting ? 'Préparation…' : 'Démarrer l’examen',
                icon: Icons.play_arrow_rounded,
                variant: AppButtonVariant.danger,
                isLoading: starting,
                onPressed: starting ? null : onStart,
              ),
              const SizedBox(height: 4),
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
        isTcf ? 'CECRL' : '${exam.passingScore}/${exam.totalQuestions}',
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            Expanded(child: _StatCell(stat: stats[i])),
            if (i < stats.length - 1)
              Container(width: 1, height: 36, color: AppColors.line),
          ],
        ],
      ),
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
          stat.label.toUpperCase(),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 22),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.blue, AppColors.blueDark],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Passez Premium',
                textAlign: TextAlign.center,
                style: AppFonts.fraunces(size: 24, weight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Un examen gratuit par module pour goûter. L’abonnement débloque tout le reste — sans commission de store.',
                textAlign: TextAlign.center,
                style: AppFonts.jakarta(
                  size: 13,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              const _PaywallPerk(
                icon: Icons.fact_check_rounded,
                label: '40 examens blancs civique + TCF',
              ),
              const SizedBox(height: 8),
              const _PaywallPerk(
                icon: Icons.all_inclusive_rounded,
                label: 'Entraînement illimité sur tous les thèmes',
              ),
              const SizedBox(height: 8),
              const _PaywallPerk(
                icon: Icons.bookmark_added_rounded,
                label: 'Favoris, erreurs et statistiques détaillées',
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'M’abonner sur sejourfr.fr',
                icon: Icons.open_in_new_rounded,
                variant: AppButtonVariant.danger,
                onPressed: () async {
                  await Clipboard.setData(const ClipboardData(text: _checkoutUrl));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.ink,
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Lien copié : $_checkoutUrl',
                        style: AppFonts.jakarta(color: AppColors.white, size: 13),
                      ),
                    ),
                  );
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 4),
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

class _PaywallPerk extends StatelessWidget {
  const _PaywallPerk({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppColors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppFonts.jakarta(
              size: 13,
              color: AppColors.ink2,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: const [
        _Header(),
        SizedBox(height: 16),
        ModuleSwitch(),
        SizedBox(height: 22),
        _SkeletonCard(big: true),
        SizedBox(height: 12),
        _SkeletonCard(),
        SizedBox(height: 10),
        _SkeletonCard(),
        SizedBox(height: 10),
        _SkeletonCard(),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({this.big = false});

  final bool big;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: big ? 100 : 70,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(big ? 16 : 14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: big ? 48 : 38,
              height: big ? 48 : 38,
              decoration: BoxDecoration(
                color: AppColors.line2,
                borderRadius: BorderRadius.circular(big ? 14 : 11),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.line2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 140,
                    decoration: BoxDecoration(
                      color: AppColors.line2,
                      borderRadius: BorderRadius.circular(4),
                    ),
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

class _ErrorList extends StatelessWidget {
  const _ErrorList({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const _Header(),
        const SizedBox(height: 28),
        Center(
          child: Column(
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: AppColors.red,
                size: 40,
              ),
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const _Header(),
        const SizedBox(height: 16),
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
