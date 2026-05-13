import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/question_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/eyebrow.dart';
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('§ Révision'),
                  const SizedBox(height: 8),
                  Text(
                    'Vos questions',
                    style: AppFonts.fraunces(size: 28, weight: FontWeight.w600),
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

class _QuestionItem extends StatelessWidget {
  const _QuestionItem({required this.question});

  final QuestionDto question;

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
