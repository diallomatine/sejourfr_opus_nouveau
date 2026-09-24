import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/question_models.dart';
import '../../core/router/app_router.dart';
import '../../core/router/retour.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/question_detail_sheet.dart';
import '../../core/widgets/screen_header.dart';
import 'favoris_labels.dart';
import 'widgets/module_switch.dart';

final _favoritesProvider = FutureProvider.autoDispose<List<QuestionDto>>((ref) {
  final module = ref.watch(selectedModuleProvider);
  return ref.watch(userContentRepositoryProvider).favorites(module: module);
});

/// « Mes favoris », ouvert depuis le Profil (« Mon compte ») : les questions
/// épinglées pendant un entraînement, par parcours.
///
/// Miroir web : `FavorisView` (`/favoris`) — même titre, même bascule
/// Civique / TCF, mêmes cartes, même état vide, même détail. Textes :
/// `favoris_labels.dart`.
class MesFavorisScreen extends StatelessWidget {
  const MesFavorisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: kFavorisTitle,
              onBack: () => retourOuRepli(context, repli: AppRoutes.profile),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kFavorisLead,
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
            const Expanded(child: _FavorisList()),
          ],
        ),
      ),
    );
  }
}

class _FavorisList extends ConsumerStatefulWidget {
  const _FavorisList();

  @override
  ConsumerState<_FavorisList> createState() => _FavorisListState();
}

class _FavorisListState extends ConsumerState<_FavorisList> {
  int _visible = kFavorisPageSize;

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedModuleProvider, (_, __) {
      setState(() => _visible = kFavorisPageSize);
    });
    final list = ref.watch(_favoritesProvider);
    return list.when(
      loading: () => const _ListSkeleton(),
      error: (e, _) => _ErrorState(
        message: ApiClient.toApiException(e).message,
        onRetry: () => ref.invalidate(_favoritesProvider),
      ),
      data: (questions) {
        if (questions.isEmpty) return const _EmptyState();
        final shown = questions.length < _visible ? questions.length : _visible;
        final remaining = questions.length - shown;
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_favoritesProvider);
            setState(() => _visible = kFavorisPageSize);
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
                  onTap: () => setState(() => _visible += kFavorisPageSize),
                );
              }
              return _FavoriCard(question: questions[i]);
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
              favorisShowMore(remaining),
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

class _FavoriCard extends ConsumerWidget {
  const _FavoriCard({required this.question});

  final QuestionDto question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDetail(context),
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
                  decoration: const BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.only(
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
                                color: AppColors.blueLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                LucideIcons.bookmarkCheck,
                                size: 14,
                                color: AppColors.blue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            AppTag(
                              label: question.difficulty.wire,
                              tone: TagTone.red,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: AppTag(
                                label: question.questionType.displayLabel,
                                tone: TagTone.blue,
                              ),
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

  void _openDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FavoriDetail(fallback: question),
    );
  }
}

/// Détail d'un favori : la feuille partagée [QuestionDetailSheet] (média,
/// passage, propositions résolues, explication) avec le bouton favori en tête.
/// La liste renvoie la version publique (sans correction) : on relit
/// `/api/me/questions/{id}/review`.
class _FavoriDetail extends ConsumerStatefulWidget {
  const _FavoriDetail({required this.fallback});

  final QuestionDto fallback;

  @override
  ConsumerState<_FavoriDetail> createState() => _FavoriDetailState();
}

class _FavoriDetailState extends ConsumerState<_FavoriDetail> {
  late final Future<QuestionDto> _future;
  late bool _isFavorite;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(userContentRepositoryProvider)
        .reviewQuestion(widget.fallback.id);
    final favs = ref.read(_favoritesProvider).valueOrNull;
    _isFavorite = favs?.any((q) => q.id == widget.fallback.id) ?? true;
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
    return FutureBuilder<QuestionDto>(
      future: _future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        return QuestionDetailSheet(
          question: snapshot.data ?? widget.fallback,
          // Un favori n'est pas un corrigé : on ne marque pas l'ancien choix.
          userSelectedChoiceIdsOverride: const [],
          headerAction: _FavoriteToggleButton(
            isFavorite: _isFavorite,
            loading: _toggling,
            onTap: _toggleFavorite,
          ),
          status: loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : snapshot.hasError
                  ? _DetailError(
                      message:
                          ApiClient.toApiException(snapshot.error!).message,
                    )
                  : null,
        );
      },
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: AppFonts.ui(color: AppColors.red, size: 13),
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
                  isFavorite ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                  size: 16,
                  color: accent,
                ),
              const SizedBox(width: 6),
              Text(
                isFavorite ? kFavoriOn : kFavoriAdd,
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

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = ref.watch(selectedModuleProvider);
    final hubRoute =
        module == AppModule.civique ? AppRoutes.civique : AppRoutes.tcf;
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
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              LucideIcons.bookmark,
              color: AppColors.blue,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          kFavorisEmptyTitle,
          textAlign: TextAlign.center,
          style: AppFonts.display(size: 22, weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          kFavorisEmptyHint,
          textAlign: TextAlign.center,
          style: AppFonts.ui(size: 13, color: AppColors.muted, height: 1.45),
        ),
        const SizedBox(height: 22),
        Center(
          child: AppButton(
            label: kFavorisEmptyCta,
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
            const Icon(LucideIcons.cloudOff, size: 36, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.ui(size: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text(kFavorisRetry)),
          ],
        ),
      ),
    );
  }
}
