import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/question_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../home/widgets/module_switch.dart';

final _favoritesProvider = FutureProvider.autoDispose<List<QuestionDto>>((ref) {
  final module = ref.watch(selectedModuleProvider);
  return ref.watch(userContentRepositoryProvider).favorites(module: module);
});

final _wrongProvider = FutureProvider.autoDispose<List<QuestionDto>>((ref) {
  final module = ref.watch(selectedModuleProvider);
  return ref.watch(userContentRepositoryProvider).wrongAnswered(module: module);
});

enum _Tab { errors, favorites }

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  _Tab _tab = _Tab.errors;

  @override
  Widget build(BuildContext context) {
    final wrong = ref.watch(_wrongProvider);
    final favorites = ref.watch(_favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'Mes questions',
          style: AppFonts.jakarta(size: 16, weight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revoyez vos erreurs et les questions que vous avez marquées.',
                    style: AppFonts.jakarta(
                      size: 13,
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const ModuleSwitch(),
                  const SizedBox(height: 16),
                  _SegmentedTabs(
                    current: _tab,
                    errorsCount: wrong.maybeWhen(
                      data: (q) => q.length,
                      orElse: () => null,
                    ),
                    favoritesCount: favorites.maybeWhen(
                      data: (q) => q.length,
                      orElse: () => null,
                    ),
                    onChanged: (t) => setState(() => _tab = t),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                child: KeyedSubtree(
                  key: ValueKey(_tab),
                  child: _tab == _Tab.errors
                      ? _QuestionList(
                          provider: _wrongProvider,
                          mode: _Tab.errors,
                        )
                      : _QuestionList(
                          provider: _favoritesProvider,
                          mode: _Tab.favorites,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.current,
    required this.errorsCount,
    required this.favoritesCount,
    required this.onChanged,
  });

  final _Tab current;
  final int? errorsCount;
  final int? favoritesCount;
  final ValueChanged<_Tab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _SegmentTab(
            label: 'Erreurs',
            count: errorsCount,
            active: current == _Tab.errors,
            activeColor: AppColors.red,
            onTap: () => onChanged(_Tab.errors),
          ),
          _SegmentTab(
            label: 'Favoris',
            count: favoritesCount,
            active: current == _Tab.favorites,
            activeColor: AppColors.blue,
            onTap: () => onChanged(_Tab.favorites),
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.count,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppFonts.jakarta(
                    size: 13,
                    weight: FontWeight.w700,
                    color: active ? AppColors.white : AppColors.muted,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.white.withValues(alpha: 0.22)
                          : AppColors.line2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$count',
                      style: AppFonts.mono(
                        size: 10,
                        color: active ? AppColors.white : AppColors.muted,
                        letterSpacing: 0.5,
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

class _QuestionList extends ConsumerWidget {
  const _QuestionList({required this.provider, required this.mode});

  final ProviderListenable<AsyncValue<List<QuestionDto>>> provider;
  final _Tab mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(provider);
    return list.when(
      loading: () => const _ListSkeleton(),
      error: (e, _) => _ErrorState(
        message: ApiClient.toApiException(e).message,
        onRetry: () => ref.invalidate(provider as ProviderBase),
      ),
      data: (questions) {
        if (questions.isEmpty) {
          return _EmptyState(mode: mode);
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider as ProviderBase),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _QuestionItem(
              question: questions[i],
              mode: mode,
            ),
          ),
        );
      },
    );
  }
}

class _QuestionItem extends ConsumerWidget {
  const _QuestionItem({required this.question, required this.mode});

  final QuestionDto question;
  final _Tab mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = mode == _Tab.errors ? AppColors.red : AppColors.blue;
    final accentBg =
        mode == _Tab.errors ? AppColors.redLight : AppColors.blueLight;
    final accentIcon = mode == _Tab.errors
        ? Icons.close_rounded
        : Icons.bookmark_rounded;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDetail(context, ref),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: accentBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(accentIcon,
                                  size: 14, color: accent),
                            ),
                            const SizedBox(width: 10),
                            AppTag(
                              label: question.difficulty.wire,
                              tone: TagTone.red,
                            ),
                            const SizedBox(width: 6),
                            AppTag(
                              label: question.questionType.displayLabel,
                              tone: TagTone.blue,
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.muted2,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          question.statement,
                          style: AppFonts.jakarta(
                            size: 14,
                            weight: FontWeight.w600,
                            height: 1.4,
                            color: AppColors.ink,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.bookmarks_outlined,
                              size: 12,
                              color: AppColors.muted2,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                question.themeName,
                                style: AppFonts.mono(
                                  size: 10,
                                  color: AppColors.muted,
                                  letterSpacing: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref) {
    final future =
        ref.read(userContentRepositoryProvider).reviewQuestion(question.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuestionDetailSheet(
        fallback: question,
        future: future,
      ),
    );
  }
}

class _QuestionDetailSheet extends ConsumerStatefulWidget {
  const _QuestionDetailSheet({
    required this.fallback,
    required this.future,
  });

  final QuestionDto fallback;
  final Future<QuestionDto> future;

  @override
  ConsumerState<_QuestionDetailSheet> createState() =>
      _QuestionDetailSheetState();
}

class _QuestionDetailSheetState extends ConsumerState<_QuestionDetailSheet> {
  late bool _isFavorite;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    // L'écran parent watch déjà _favoritesProvider pour le compteur de l'onglet,
    // donc la liste est en cache au moment où l'on ouvre le sheet.
    final favs = ref.read(_favoritesProvider).valueOrNull;
    _isFavorite =
        favs?.any((q) => q.id == widget.fallback.id) ?? false;
  }

  Future<void> _toggleFavorite() async {
    if (_toggling) return;
    final qId = widget.fallback.id;
    final wasFavorite = _isFavorite;
    setState(() {
      _isFavorite = !wasFavorite;
      _toggling = true;
    });
    try {
      final repo = ref.read(userContentRepositoryProvider);
      if (wasFavorite) {
        await repo.removeFavorite(qId);
      } else {
        await repo.addFavorite(qId);
      }
      ref.invalidate(_favoritesProvider);
    } catch (_) {
      if (mounted) setState(() => _isFavorite = wasFavorite);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 0),
            child: Row(
              children: [
                Text(
                  'DÉTAIL · ${widget.fallback.module.wire}',
                  style: AppFonts.mono(
                    size: 9,
                    color: AppColors.muted,
                    letterSpacing: 1.6,
                  ),
                ),
                const Spacer(),
                _FavoriteToggleButton(
                  isFavorite: _isFavorite,
                  loading: _toggling,
                  onTap: _toggleFavorite,
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<QuestionDto>(
              future: widget.future,
              builder: (context, snapshot) {
                final loaded = snapshot.data;
                final question = loaded ?? widget.fallback;
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;
                final hasExplanation = loaded != null &&
                    loaded.explanation != null &&
                    loaded.explanation!.isNotEmpty;
                return _DetailContent(
                  controller: controller,
                  question: question,
                  isLoading: isLoading,
                  hasExplanation: hasExplanation,
                  error: snapshot.hasError
                      ? ApiClient.toApiException(snapshot.error!).message
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteToggleButton extends StatelessWidget {
  const _FavoriteToggleButton({
    required this.isFavorite,
    required this.loading,
    required this.onTap,
  });

  final bool isFavorite;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isFavorite ? AppColors.red : AppColors.muted;
    final accentBg = isFavorite ? AppColors.redLight : AppColors.line2;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: accentBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isFavorite
                  ? AppColors.red.withValues(alpha: 0.25)
                  : AppColors.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                )
              else
                Icon(
                  isFavorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline,
                  size: 16,
                  color: accent,
                ),
              const SizedBox(width: 6),
              Text(
                isFavorite ? 'Favori' : 'Ajouter aux favoris',
                style: AppFonts.jakarta(
                  size: 12,
                  weight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.controller,
    required this.question,
    required this.isLoading,
    required this.hasExplanation,
    required this.error,
  });

  final ScrollController controller;
  final QuestionDto question;
  final bool isLoading;
  final bool hasExplanation;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Row(
          children: [
            AppTag(label: question.difficulty.wire, tone: TagTone.red),
            const SizedBox(width: 6),
            AppTag(
              label: question.questionType.displayLabel,
              tone: TagTone.blue,
            ),
            const Spacer(),
            Flexible(
              child: Text(
                question.themeName,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.mono(
                  size: 10,
                  color: AppColors.muted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          question.statement,
          style: AppFonts.fraunces(
            size: 19,
            weight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(question.choices.length, (i) {
          final c = question.choices[i];
          return Padding(
            padding: EdgeInsets.only(
              bottom: i == question.choices.length - 1 ? 0 : 10,
            ),
            child: _ReviewChoiceTile(choice: c, index: i),
          );
        }),
        if (isLoading) ...[
          const SizedBox(height: 20),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.redLight,
              border:
                  Border.all(color: AppColors.red.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              error!,
              style: AppFonts.jakarta(color: AppColors.red, size: 13),
            ),
          ),
        ],
        if (hasExplanation) ...[
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.all(16),
            border: Border.all(
              color: AppColors.green.withValues(alpha: 0.35),
            ),
            color: AppColors.green.withValues(alpha: 0.05),
            boxShadow: const [],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Explication',
                      style: AppFonts.jakarta(
                        size: 14,
                        weight: FontWeight.w800,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  question.explanation!,
                  style: AppFonts.jakarta(
                    size: 13.5,
                    color: AppColors.ink2,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ReviewChoiceTile extends StatelessWidget {
  const _ReviewChoiceTile({required this.choice, required this.index});

  final ChoiceDto choice;
  final int index;

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode('A'.codeUnitAt(0) + index);
    final correct = choice.correct;

    final background =
        correct ? AppColors.green.withValues(alpha: 0.07) : AppColors.white;
    final border = correct ? AppColors.green : AppColors.line;
    final letterBg = correct ? AppColors.green : AppColors.line2;
    final letterColor = correct ? AppColors.white : AppColors.muted;
    final textColor = correct ? AppColors.ink : AppColors.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border, width: correct ? 1.5 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration:
                BoxDecoration(color: letterBg, shape: BoxShape.circle),
            child: Text(
              letter,
              style: AppFonts.jakarta(
                size: 13,
                weight: FontWeight.w800,
                color: letterColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              choice.label,
              style: AppFonts.jakarta(
                size: 14,
                weight: FontWeight.w500,
                color: textColor,
                height: 1.35,
              ),
            ),
          ),
          if (correct) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check_circle, color: AppColors.green),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.mode});

  final _Tab mode;

  @override
  Widget build(BuildContext context) {
    final isErrors = mode == _Tab.errors;
    final icon = isErrors
        ? Icons.verified_rounded
        : Icons.bookmark_border_rounded;
    final iconColor = isErrors ? AppColors.green : AppColors.blue;
    final iconBg = isErrors
        ? AppColors.green.withValues(alpha: 0.10)
        : AppColors.blueLight;
    final title = isErrors ? 'Aucune erreur récente' : 'Aucun favori';
    final hint = isErrors
        ? 'Vos erreurs s\'afficheront ici pour que vous puissiez les revoir.'
        : 'Pendant un entraînement, appuyez sur l\'icône marque-page pour épingler une question.';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: iconColor, size: 34),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppFonts.fraunces(
            size: 22,
            weight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: AppFonts.jakarta(
            size: 13,
            color: AppColors.muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: AppButton(
            label: 'Lancer un entraînement',
            icon: Icons.play_arrow_rounded,
            variant: AppButtonVariant.secondary,
            fullWidth: false,
            onPressed: () => context.go(AppRoutes.trainingSetup),
          ),
        ),
      ],
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        height: 112,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 36, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.jakarta(size: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
