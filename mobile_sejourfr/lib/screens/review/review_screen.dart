import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/question_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
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

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Favoris et erreurs récentes',
                    style: AppFonts.jakarta(
                      size: 13.5,
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const ModuleSwitch(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(10),
                color: AppColors.white,
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorPadding: const EdgeInsets.all(4),
                dividerColor: Colors.transparent,
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.muted,
                labelStyle: AppFonts.jakarta(
                  size: 13,
                  weight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(text: 'Mes erreurs'),
                  Tab(text: 'Favoris'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _QuestionList(
                    provider: _wrongProvider,
                    emptyTitle: 'Aucune erreur',
                    emptyHint: 'Quand vous vous tromperez, vos questions apparaîtront ici pour révision.',
                  ),
                  _QuestionList(
                    provider: _favoritesProvider,
                    emptyTitle: 'Aucun favori',
                    emptyHint: 'Marquez une question en favori depuis l\'entraînement.',
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

class _QuestionList extends ConsumerWidget {
  const _QuestionList({
    required this.provider,
    required this.emptyTitle,
    required this.emptyHint,
  });

  final ProviderListenable<AsyncValue<List<QuestionDto>>> provider;
  final String emptyTitle;
  final String emptyHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(provider);
    return list.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: ApiClient.toApiException(e).message,
        onRetry: () => ref.invalidate(provider as ProviderBase),
      ),
      data: (questions) {
        if (questions.isEmpty) {
          return _EmptyState(title: emptyTitle, hint: emptyHint);
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider as ProviderBase),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _QuestionItem(question: questions[i]),
          ),
        );
      },
    );
  }
}

class _QuestionItem extends ConsumerWidget {
  const _QuestionItem({required this.question});

  final QuestionDto question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openDetail(context, ref),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.muted2,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              question.statement,
              style: AppFonts.jakarta(
                size: 14,
                weight: FontWeight.w600,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              question.themeName,
              style: AppFonts.mono(
                size: 10,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref) {
    final future = ref.read(userContentRepositoryProvider).reviewQuestion(question.id);
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

class _QuestionDetailSheet extends StatelessWidget {
  const _QuestionDetailSheet({
    required this.fallback,
    required this.future,
  });

  /// Version "publique" déjà chargée dans la liste — affichée tant que la
  /// version détaillée (avec explication + bonnes réponses) n'est pas arrivée.
  final QuestionDto fallback;
  final Future<QuestionDto> future;

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
          Expanded(
            child: FutureBuilder<QuestionDto>(
              future: future,
              builder: (context, snapshot) {
                final loaded = snapshot.data;
                final question = loaded ?? fallback;
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                final hasExplanation =
                    loaded != null && loaded.explanation != null && loaded.explanation!.isNotEmpty;
                return _DetailContent(
                  controller: controller,
                  question: question,
                  isLoading: isLoading,
                  hasExplanation: hasExplanation,
                  error: snapshot.hasError ? ApiClient.toApiException(snapshot.error!).message : null,
                );
              },
            ),
          ),
        ],
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
              border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
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

    final background = correct ? AppColors.green.withValues(alpha: 0.07) : AppColors.white;
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
            decoration: BoxDecoration(color: letterBg, shape: BoxShape.circle),
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
  const _EmptyState({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories_outlined, size: 48, color: AppColors.muted2),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppFonts.fraunces(
                size: 20,
                weight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: AppFonts.jakarta(
                size: 13,
                color: AppColors.muted2,
              ),
            ),
          ],
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
            const Icon(Icons.cloud_off_outlined, size: 36, color: AppColors.red),
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
