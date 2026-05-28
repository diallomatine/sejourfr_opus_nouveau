import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/enums.dart';
import '../../core/models/question_models.dart';
import '../../core/theme/app_theme.dart';
import 'tcf_qcm_detail_screen.dart' show TcfQcmModule, WrongQuestionCard, QcmErrorBox;
import 'widgets/module_detail_widgets.dart';

/// Provider des questions ratées pour cette page autonome.
final _errorsPageWrongProvider =
    FutureProvider.autoDispose.family<List<QuestionDto>, QuestionType>((ref, qt) {
  return ref.watch(userContentRepositoryProvider).wrongAnswered(
        module: AppModule.tcf,
        questionType: qt,
      );
});

/// Page autonome « Erreurs » pour les modules TCF QCM (CO, CE, Structure).
/// Extrait et étend l'onglet Erreurs de l'ancien hub à onglets.
/// Topbar + back, liste des 20 dernières questions ratées,
/// sheet review au tap.
class TcfQcmErrorsScreen extends ConsumerWidget {
  const TcfQcmErrorsScreen({super.key, required this.module});

  final TcfQcmModule module;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/tcf/${module.routeKey}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncWrong = ref.watch(_errorsPageWrongProvider(module.questionType));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(module: module, onBack: () => _back(context)),
            Expanded(
              child: asyncWrong.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.blue)),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: QcmErrorBox(message: ApiClient.toApiException(e).message),
                ),
                data: (wrongs) => _buildContent(context, ref, wrongs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<QuestionDto> wrongs) {
    if (wrongs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ModuleDetailTabPlaceholder(
          icon: Icons.verified_outlined,
          title: 'Aucune erreur récente',
          description:
              'Bravo — pas de question ratée sur ${module.title} pour l\'instant. Continue les lots pour rester au top.',
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: () async {
        ref.invalidate(_errorsPageWrongProvider(module.questionType));
        await ref.read(_errorsPageWrongProvider(module.questionType).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${wrongs.length} ERREUR${wrongs.length > 1 ? "S" : ""}',
                  style: AppFonts.mono(
                    size: 9.5,
                    color: AppColors.amber,
                    letterSpacing: 1.6,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                module.title,
                style: AppFonts.jakarta(size: 12, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final q in wrongs) WrongQuestionCard(question: q),
        ],
      ),
    );
  }
}

// ============================================================================
// Header
// ============================================================================

class _Header extends StatelessWidget {
  const _Header({required this.module, required this.onBack});

  final TcfQcmModule module;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
      color: AppColors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Erreurs à revoir',
                  style: AppFonts.jakarta(size: 17, weight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 1),
                Text(
                  '${module.title} · TCF IRN',
                  style: AppFonts.jakarta(size: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
