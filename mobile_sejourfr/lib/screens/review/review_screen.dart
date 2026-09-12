import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/question_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import 'widgets/module_switch.dart';

final _favoritesProvider = FutureProvider.autoDispose<List<QuestionDto>>((ref) {
  final module = ref.watch(selectedModuleProvider);
  return ref.watch(userContentRepositoryProvider).favorites(module: module);
});

final _wrongProvider = FutureProvider.autoDispose<List<QuestionDto>>((ref) {
  final module = ref.watch(selectedModuleProvider);
  return ref.watch(userContentRepositoryProvider).wrongAnswered(module: module);
});

enum _Tab { errors, favorites }

/// « Mes questions » : les questions ratées. Page dédiée (cf. hub
/// « Mon entraînement »).
class MesQuestionsScreen extends StatelessWidget {
  const MesQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const _ReviewListScreen(mode: _Tab.errors);
}

/// « Mes favoris » : les questions épinglées. Page dédiée.
class MesFavorisScreen extends StatelessWidget {
  const MesFavorisScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const _ReviewListScreen(mode: _Tab.favorites);
}

/// Corps partagé d'une page de révision (erreurs OU favoris). Chaque mode a sa
/// propre page : plus de toggle segmenté Erreurs/Favoris (qui se superposait au
/// sélecteur de module Civique/TCF).
class _ReviewListScreen extends ConsumerWidget {
  const _ReviewListScreen({required this.mode});

  final _Tab mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isErrors = mode == _Tab.errors;
    final provider = isErrors ? _wrongProvider : _favoritesProvider;

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          isErrors ? 'Mes questions' : 'Mes favoris',
          style: AppFonts.ui(size: 16, weight: FontWeight.w700),
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
                    isErrors
                        ? 'Revoyez les questions auxquelles vous avez mal répondu.'
                        : 'Retrouvez les questions que vous avez marquées.',
                    style: AppFonts.ui(
                      size: 13,
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const ModuleSwitch(),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _QuestionList(provider: provider, mode: mode),
            ),
          ],
        ),
      ),
    );
  }
}

/// Taille de fenêtre de la liste (et palier du bouton « Afficher plus »).
/// Les favoris peuvent être nombreux ; les erreurs sont plafonnées à 30 côté
/// backend. On ne monte qu'une fenêtre à la fois pour éviter de construire des
/// centaines de cards d'un coup.
const int _kReviewPageSize = 20;

class _QuestionList extends ConsumerStatefulWidget {
  const _QuestionList({required this.provider, required this.mode});

  final ProviderListenable<AsyncValue<List<QuestionDto>>> provider;
  final _Tab mode;

  @override
  ConsumerState<_QuestionList> createState() => _QuestionListState();
}

class _QuestionListState extends ConsumerState<_QuestionList> {
  int _visible = _kReviewPageSize;

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(widget.provider);
    return list.when(
      loading: () => const _ListSkeleton(),
      error: (e, _) => _ErrorState(
        message: ApiClient.toApiException(e).message,
        onRetry: () => ref.invalidate(widget.provider as ProviderBase),
      ),
      data: (questions) {
        if (questions.isEmpty) {
          return _EmptyState(mode: widget.mode);
        }
        final shown = questions.length < _visible ? questions.length : _visible;
        final remaining = questions.length - shown;
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(widget.provider as ProviderBase);
            setState(() => _visible = _kReviewPageSize);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            itemCount: shown + (remaining > 0 ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              if (i >= shown) {
                return _ShowMoreButton(
                  remaining: remaining,
                  onTap: () => setState(
                    () => _visible += _kReviewPageSize,
                  ),
                );
              }
              return _QuestionItem(
                question: questions[i],
                mode: widget.mode,
              );
            },
          ),
        );
      },
    );
  }
}

class _ShowMoreButton extends StatelessWidget {
  const _ShowMoreButton({required this.remaining, required this.onTap});

  final int remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Afficher plus ($remaining restante${remaining > 1 ? 's' : ''})',
              style: AppFonts.ui(
                size: 13.5,
                weight: FontWeight.w700,
                color: AppColors.blue,
              ),
            ),
          ),
        ),
      ),
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
        ? LucideIcons.x
        : LucideIcons.bookmarkCheck;

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
                              LucideIcons.chevronRight,
                              color: AppColors.muted2,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          question.statement,
                          style: AppFonts.ui(
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
                              LucideIcons.bookmark,
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
                      ? LucideIcons.bookmarkCheck
                      : LucideIcons.bookmark,
                  size: 16,
                  color: accent,
                ),
              const SizedBox(width: 6),
              Text(
                isFavorite ? 'Favori' : 'Ajouter aux favoris',
                style: AppFonts.ui(
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
          style: AppFonts.display(
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
              style: AppFonts.ui(color: AppColors.red, size: 13),
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
                      LucideIcons.lightbulb,
                      color: AppColors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Explication',
                      style: AppFonts.ui(
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
                  style: AppFonts.ui(
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
              style: AppFonts.ui(
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
              style: AppFonts.ui(
                size: 14,
                weight: FontWeight.w500,
                color: textColor,
                height: 1.35,
              ),
            ),
          ),
          if (correct) ...[
            const SizedBox(width: 8),
            const Icon(LucideIcons.circleCheck, color: AppColors.green),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState({required this.mode});

  final _Tab mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = ref.watch(selectedModuleProvider);
    final hubRoute =
        module == AppModule.civique ? AppRoutes.civique : AppRoutes.tcf;
    final isErrors = mode == _Tab.errors;
    final icon = isErrors
        ? LucideIcons.badgeCheck
        : LucideIcons.bookmark;
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
          style: AppFonts.display(
            size: 22,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: AppFonts.ui(
            size: 13,
            color: AppColors.muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: AppButton(
            label: 'Lancer un entraînement',
            icon: LucideIcons.play,
            variant: AppButtonVariant.secondary,
            fullWidth: false,
            onPressed: () => context.go(hubRoute),
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
            const Icon(LucideIcons.cloudOff,
                size: 36, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.ui(size: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
