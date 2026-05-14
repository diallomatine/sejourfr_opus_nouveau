import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/question_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/eyebrow.dart';
import '../home/widgets/module_switch.dart';
import '../shared/target_path_banner.dart';

/// Taille du premier batch de questions chargé en entraînement.
/// La session est ensuite étendue automatiquement par batches identiques.
const _kInitialBatchSize = 30;

final _themesProvider =
    FutureProvider.autoDispose<List<ThemeDto>>((ref) async {
  final module = ref.watch(selectedModuleProvider);
  return ref.watch(themesRepositoryProvider).list(module: module);
});

class TrainingSetupScreen extends ConsumerStatefulWidget {
  const TrainingSetupScreen({super.key});

  @override
  ConsumerState<TrainingSetupScreen> createState() =>
      _TrainingSetupScreenState();
}

class _TrainingSetupScreenState extends ConsumerState<TrainingSetupScreen> {
  ThemeDto? _selectedTheme;
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
              type: AttemptType.training,
              module: module,
              themeId: _selectedTheme?.id,
              size: _kInitialBatchSize,
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
    final themes = ref.watch(_themesProvider);
    final auth = ref.watch(authControllerProvider);
    final targetProcedure =
        auth is AuthAuthenticated ? auth.user.targetProcedure : null;

    ref.listen(selectedModuleProvider, (_, __) {
      setState(() {
        _selectedTheme = null;
      });
    });

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            const Eyebrow('§ 01 — Module'),
            const SizedBox(height: 8),
            Text(
              'Entraînement libre',
              style: AppFonts.fraunces(size: 28, weight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (targetProcedure != null) ...[
              TargetPathBanner(procedure: targetProcedure),
              const SizedBox(height: 16),
            ],
            const ModuleSwitch(),
            const SizedBox(height: 16),
            const _ContinuousModeCard(),
            const SizedBox(height: 24),
            const Eyebrow('§ 02 — Thématique (optionnel)'),
            const SizedBox(height: 10),
            themes.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _ErrorBox(
                message: ApiClient.toApiException(e).message,
                onRetry: () => ref.refresh(_themesProvider),
              ),
              data: (list) => Column(
                children: [
                  _ThemeTile(
                    theme: null,
                    selected: _selectedTheme == null,
                    onTap: () => setState(() => _selectedTheme = null),
                  ),
                  const SizedBox(height: 8),
                  for (final t in list) ...[
                    _ThemeTile(
                      theme: t,
                      selected: _selectedTheme?.id == t.id,
                      onTap: () => setState(() {
                        _selectedTheme = _selectedTheme?.id == t.id ? null : t;
                      }),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Aucune thématique disponible.',
                        style: AppFonts.jakarta(color: AppColors.muted),
                      ),
                    ),
                ],
              ),
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
              label: 'Commencer l\'entraînement',
              onPressed: _starting ? null : _start,
              isLoading: _starting,
            ),
          ],
        ),
      ),
    );
  }
}

/// Petit bandeau qui explique le mode session continue.
class _ContinuousModeCard extends StatelessWidget {
  const _ContinuousModeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.all_inclusive_rounded,
              size: 18,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session continue',
                  style: AppFonts.jakarta(size: 13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enchaînez les questions sans limite. Quittez quand vous voulez.',
                  style: AppFonts.jakarta(size: 11.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  /// Null = "Toutes les thématiques".
  final ThemeDto? theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAll = theme == null;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      border: Border.all(
        color: selected ? AppColors.blue : AppColors.line,
        width: selected ? 1.5 : 1,
      ),
      color: selected ? AppColors.blueSoft : AppColors.white,
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.blue : Colors.transparent,
              border: Border.all(
                color: selected ? AppColors.blue : AppColors.line,
                width: 2,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, size: 14, color: AppColors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAll ? 'Toutes les thématiques' : theme!.name,
                  style: AppFonts.jakarta(
                    size: 14,
                    weight: FontWeight.w700,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    isAll
                        ? 'Mélange de toutes les thématiques disponibles'
                        : (theme!.description ?? ''),
                    style: AppFonts.jakarta(
                      size: 12,
                      color: AppColors.muted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (!isAll) ...[
            const SizedBox(width: 8),
            AppTag(
              label: '${theme!.questionCount} Q',
              tone: TagTone.neutral,
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.red, size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppFonts.jakarta(size: 13, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
