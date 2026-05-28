import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/models/question_models.dart';
import '../../core/theme/app_theme.dart';
import '../tcf_production/widgets/module_screen_header.dart';
import 'qcm_hub_data.dart';
import 'tcf_qcm_detail_screen.dart' show TcfQcmModule;
import 'widgets/module_detail_widgets.dart';
import 'widgets/wrong_question_card.dart';

/// Page autonome « Erreurs » pour les modules TCF QCM (CO, CE, Structure).
/// Header + liste des 20 dernières questions ratées, sheet review au tap.
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
    final asyncWrong = ref.watch(qcmWrongQuestionsProvider(module.questionType));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ModuleScreenHeader(
              title: 'Erreurs à revoir',
              subtitle: '${module.title} · TCF IRN',
              onBack: () => _back(context),
            ),
            Expanded(
              child: asyncWrong.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.blue)),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child:
                      QcmErrorBox(message: ApiClient.toApiException(e).message),
                ),
                data: (wrongs) => _buildContent(context, ref, wrongs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, List<QuestionDto> wrongs) {
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
        ref.invalidate(qcmWrongQuestionsProvider(module.questionType));
        await ref.read(qcmWrongQuestionsProvider(module.questionType).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
