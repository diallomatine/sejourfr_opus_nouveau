import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/eyebrow.dart';
import '../home/widgets/module_switch.dart';

class ExamSetupScreen extends ConsumerStatefulWidget {
  const ExamSetupScreen({super.key});

  @override
  ConsumerState<ExamSetupScreen> createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends ConsumerState<ExamSetupScreen> {
  Difficulty? _difficulty;
  bool _starting = false;
  String? _error;

  Future<void> _start() async {
    if (_difficulty == null) {
      setState(() => _error = 'Choisissez d\'abord une mention.');
      return;
    }
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
              difficulty: _difficulty,
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
    final levels = module == AppModule.civique
        ? Difficulty.civique
        : Difficulty.tcf;

    // Reset du niveau quand on change de module
    ref.listen(selectedModuleProvider, (_, __) {
      setState(() => _difficulty = null);
    });

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            const Eyebrow('§ Examen blanc'),
            const SizedBox(height: 8),
            Text(
              'En conditions réelles',
              style: AppFonts.fraunces(size: 28, weight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const ModuleSwitch(),
            const SizedBox(height: 24),
            _RulesCard(module: module),
            const SizedBox(height: 22),
            Eyebrow(
              module == AppModule.civique
                  ? '§ Choisir une mention'
                  : '§ Choisir un niveau',
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                for (final d in levels) ...[
                  _LevelCard(
                    level: d,
                    isCivique: module == AppModule.civique,
                    selected: _difficulty == d,
                    onTap: () => setState(() => _difficulty = d),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  border: Border.all(
                      color: AppColors.red.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: AppFonts.jakarta(color: AppColors.red, size: 13),
                ),
              ),
            ],
            const SizedBox(height: 28),
            AppButton(
              label: 'Commencer l\'examen',
              variant: AppButtonVariant.danger,
              onPressed: _starting ? null : _start,
              isLoading: _starting,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Une fois lancé, le chronomètre démarre.',
                style: AppFonts.jakarta(size: 12, color: AppColors.muted2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.module});
  final AppModule module;

  @override
  Widget build(BuildContext context) {
    final rules = module == AppModule.civique
        ? const [
            ('40', 'questions'),
            ('45', 'minutes'),
            ('32', 'requises'),
          ]
        : const [
            ('60', 'questions'),
            ('1h30', 'durée'),
            ('—', 'score sur 699'),
          ];

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.red, size: 18),
              const SizedBox(width: 8),
              Text(
                'Règles de l\'épreuve',
                style: AppFonts.jakarta(size: 14, weight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < rules.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        rules[i].$1,
                        style: AppFonts.fraunces(
                          size: 28,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rules[i].$2,
                        style: AppFonts.mono(
                          size: 9,
                          color: AppColors.muted,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < rules.length - 1)
                  Container(
                    height: 36,
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

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.isCivique,
    required this.selected,
    required this.onTap,
  });

  final Difficulty level;
  final bool isCivique;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = level.wire;
    final description = _description();

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      border: Border.all(
        color: selected ? AppColors.red : AppColors.line,
        width: selected ? 1.5 : 1,
      ),
      color: selected ? AppColors.redLight : AppColors.white,
      child: Row(
        children: [
          AppTag(
            label: label,
            tone: selected ? TagTone.red : TagTone.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: AppFonts.jakarta(size: 13.5),
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle, color: AppColors.red, size: 22)
          else
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line2, width: 2),
              ),
            ),
        ],
      ),
    );
  }

  String _description() {
    if (isCivique) {
      switch (level) {
        case Difficulty.csp:
          return 'Carte de séjour pluriannuelle';
        case Difficulty.cr:
          return 'Carte de résident';
        case Difficulty.nat:
          return 'Naturalisation';
        default:
          return level.wire;
      }
    } else {
      switch (level) {
        case Difficulty.a2:
          return 'A2 — exigé pour la CSP';
        case Difficulty.b1:
          return 'B1 — exigé pour la CR';
        case Difficulty.b2:
          return 'B2 — exigé pour la naturalisation';
        default:
          return level.wire;
      }
    }
  }
}
