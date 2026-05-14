import 'package:flutter/material.dart';
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
import '../../core/widgets/eyebrow.dart';
import '../home/widgets/module_switch.dart';
import '../shared/target_path_banner.dart';

class ExamSetupScreen extends ConsumerStatefulWidget {
  const ExamSetupScreen({super.key});

  @override
  ConsumerState<ExamSetupScreen> createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends ConsumerState<ExamSetupScreen> {
  bool _starting = false;
  String? _error;

  Future<void> _start() async {
    setState(() {
      _error = null;
      _starting = true;
    });
    try {
      final module = ref.read(selectedModuleProvider);
      final attempt = await ref.read(attemptsRepositoryProvider).start(
            StartAttemptRequest(
              type: AttemptType.mockExam,
              module: module,
            ),
          );
      if (!mounted) return;
      context.push(AppRoutes.runner.replaceFirst(':attemptId', attempt.id));
    } catch (e) {
      setState(() => _error = ApiClient.toApiException(e).message);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final module = ref.watch(selectedModuleProvider);
    final auth = ref.watch(authControllerProvider);
    final targetProcedure =
        auth is AuthAuthenticated ? auth.user.targetProcedure : null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const _Hero(),
            const SizedBox(height: 18),
            if (targetProcedure != null) ...[
              TargetPathBanner(procedure: targetProcedure),
              const SizedBox(height: 14),
            ],
            const ModuleSwitch(),
            const SizedBox(height: 22),
            _RulesCard(module: module),
            const SizedBox(height: 18),
            const _Expectations(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _InlineError(message: _error!),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: _StickyAction(
        button: AppButton(
          label: 'Commencer l\'examen',
          icon: Icons.timer_rounded,
          variant: AppButtonVariant.danger,
          onPressed: _starting ? null : _start,
          isLoading: _starting,
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Examen blanc', color: AppColors.red),
        const SizedBox(height: 10),
        Text(
          'En conditions réelles',
          style: AppFonts.fraunces(
            size: 30,
            weight: FontWeight.w600,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Chronomètre, pas de correction immédiate, comme le jour J. Vous verrez votre score à la fin.',
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

class _RuleStat {
  const _RuleStat(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.module});
  final AppModule module;

  @override
  Widget build(BuildContext context) {
    final stats = module == AppModule.civique
        ? const [
            _RuleStat(Icons.help_outline_rounded, '40', 'questions'),
            _RuleStat(Icons.schedule_rounded, '45', 'minutes'),
            _RuleStat(Icons.flag_rounded, '32', 'requises'),
          ]
        : const [
            _RuleStat(Icons.help_outline_rounded, '60', 'questions'),
            _RuleStat(Icons.schedule_rounded, '1h30', 'durée'),
            _RuleStat(Icons.stacked_bar_chart_rounded, '/699', 'score'),
          ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  color: AppColors.red,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Règles de l\'épreuve',
                style: AppFonts.jakarta(size: 14, weight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                Expanded(child: _StatCell(stat: stats[i])),
                if (i < stats.length - 1)
                  Container(
                    height: 56,
                    width: 1,
                    color: AppColors.line,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.stat});
  final _RuleStat stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(stat.icon, size: 16, color: AppColors.muted2),
        const SizedBox(height: 6),
        Text(
          stat.value,
          style: AppFonts.fraunces(
            size: 26,
            weight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stat.label,
          style: AppFonts.mono(
            size: 9,
            color: AppColors.muted,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _Expectations extends StatelessWidget {
  const _Expectations();

  static const _items = [
    (Icons.lock_clock_rounded, 'Le chrono démarre au lancement'),
    (Icons.visibility_off_rounded, 'Pas de correction pendant l\'épreuve'),
    (Icons.assessment_rounded, 'Score et bilan à la fin'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.$1,
                      size: 15, color: AppColors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.$2,
                    style: AppFonts.jakarta(
                      size: 13,
                      color: AppColors.ink2,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppFonts.jakarta(color: AppColors.red, size: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyAction extends StatelessWidget {
  const _StickyAction({required this.button});

  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined,
                  size: 14, color: AppColors.muted2),
              const SizedBox(width: 6),
              Text(
                'Une fois lancé, le chronomètre démarre.',
                style: AppFonts.jakarta(
                  size: 11.5,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          button,
        ],
      ),
    );
  }
}
