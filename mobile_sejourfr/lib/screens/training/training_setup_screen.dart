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
import '../../core/widgets/eyebrow.dart';
import '../home/widgets/module_switch.dart';
import '../shared/target_path_banner.dart';

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
      setState(() => _selectedTheme = null);
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const _Hero(
              eyebrow: 'Entraînement',
              title: 'Entraînement libre',
              subtitle:
                  'Enchaînez les questions sans limite, à votre rythme. Vous pouvez quitter quand vous voulez.',
            ),
            const SizedBox(height: 18),
            if (targetProcedure != null) ...[
              TargetPathBanner(procedure: targetProcedure),
              const SizedBox(height: 14),
            ],
            const ModuleSwitch(),
            const SizedBox(height: 26),
            const _SectionLabel('Thématique', hint: 'optionnel'),
            const SizedBox(height: 12),
            themes.when(
              loading: () => const _ThemesSkeleton(),
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
                  for (final t in list)
                    _ThemeTile(
                      theme: t,
                      selected: _selectedTheme?.id == t.id,
                      onTap: () => setState(() {
                        _selectedTheme = _selectedTheme?.id == t.id ? null : t;
                      }),
                    ),
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
              const SizedBox(height: 16),
              _InlineError(message: _error!),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: _StickyAction(
        helper: _selectedTheme == null
            ? 'Toutes thématiques · $_kInitialBatchSize questions par session'
            : '${_selectedTheme!.name} · $_kInitialBatchSize questions par session',
        button: AppButton(
          label: 'Commencer l\'entraînement',
          icon: Icons.play_arrow_rounded,
          onPressed: _starting ? null : _start,
          isLoading: _starting,
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(eyebrow),
        const SizedBox(height: 10),
        Text(
          title,
          style: AppFonts.fraunces(
            size: 30,
            weight: FontWeight.w600,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
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
  const _SectionLabel(this.title, {this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: AppFonts.jakarta(size: 14, weight: FontWeight.w800),
        ),
        if (hint != null) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Text(
              hint!,
              style: AppFonts.jakarta(size: 11.5, color: AppColors.muted2),
            ),
          ),
        ],
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final ThemeDto? theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAll = theme == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.blueSoft : AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.blue : AppColors.line,
                width: selected ? 1.4 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.10),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
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
                      ? const Icon(Icons.check,
                          size: 14, color: AppColors.white)
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
                          color: selected ? AppColors.blueDark : AppColors.ink,
                        ),
                      ),
                      if ((isAll
                              ? 'Un mélange varié de toutes les thématiques'
                              : (theme!.description ?? ''))
                          .isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            isAll
                                ? 'Un mélange varié de toutes les thématiques'
                                : theme!.description!,
                            style: AppFonts.jakarta(
                              size: 12,
                              color: AppColors.muted,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isAll) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          selected ? AppColors.white : AppColors.line2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${theme!.questionCount} Q',
                      style: AppFonts.mono(
                        size: 10,
                        color: selected ? AppColors.blue : AppColors.muted,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemesSkeleton extends StatelessWidget {
  const _ThemesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          height: 64,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
        ),
      ),
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

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined,
              color: AppColors.red, size: 28),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppFonts.jakarta(size: 13, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _StickyAction extends StatelessWidget {
  const _StickyAction({required this.helper, required this.button});

  final String helper;
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
            children: [
              const Icon(Icons.info_outline,
                  size: 14, color: AppColors.muted2),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  helper,
                  style: AppFonts.jakarta(
                    size: 11.5,
                    color: AppColors.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
