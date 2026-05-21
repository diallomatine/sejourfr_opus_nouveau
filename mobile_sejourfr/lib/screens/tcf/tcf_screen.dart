import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/repositories.dart';
import '../../core/api/user_content_repository.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/selected_module.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../hub/widgets/hub_widgets.dart';

final _tcfStatsProvider = FutureProvider.autoDispose<UserStats>((ref) {
  return ref.watch(userContentRepositoryProvider).stats(module: AppModule.tcf);
});

class TcfScreen extends ConsumerWidget {
  const TcfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final stats = ref.watch(_tcfStatsProvider);

    final target = user?.targetProcedure;
    final level = target?.tcfLevel;
    final badgeText = level ?? 'TCF';
    final objectiveValue =
        level == null ? 'Définis ton niveau cible' : 'Niveau $level visé';

    final percent = stats.maybeWhen(
      data: (s) {
        if (s.byTheme.isEmpty) return 0;
        final correct = s.byTheme.fold<int>(0, (sum, t) => sum + t.correct);
        final total = s.byTheme.fold<int>(0, (sum, t) => sum + t.total);
        return total == 0 ? 0 : ((correct / total) * 100).round();
      },
      orElse: () => 0,
    );

    void openDetail(String route) {
      ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
      context.push(route);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.red,
          onRefresh: () async {
            ref.invalidate(_tcfStatsProvider);
            await ref.read(_tcfStatsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              HubTopBar(
                badgeText: badgeText,
                badgeColor: AppColors.red,
              ),
              const SizedBox(height: 18),
              const HubHero(
                eyebrow: 'Entraînement officiel',
                titleTop: 'Prépare ton',
                titleBottom: 'TCF IRN',
                description:
                    'Compréhension orale et écrite, expression orale et écrite avec correction IA.',
                colors: [AppColors.red, AppColors.redDark],
              ),
              const SizedBox(height: 14),
              HubProgressCard(
                objectiveLabel: 'Objectif actuel',
                objectiveValue: objectiveValue,
                percent: percent,
                accent: AppColors.red,
                hint: percent == 0
                    ? 'Commence par une épreuve pour voir ta progression.'
                    : 'Continue 15 min aujourd\'hui pour garder ton avance.',
              ),
              const SizedBox(height: 22),
              const HubSectionTitle('Modules d\'entraînement'),
              const SizedBox(height: 12),
              HubModuleCard(
                icon: Icons.headphones_rounded,
                iconColor: AppColors.blue,
                iconBg: AppColors.blueLight,
                title: 'Compréhension orale',
                description: 'Dialogues, annonces et messages audio',
                meta: '$kInitialBatchSize QUESTIONS · ≈ 20 MIN',
                onTap: () => openDetail(AppRoutes.tcfCoDetail),
              ),
              HubModuleCard(
                icon: Icons.menu_book_rounded,
                iconColor: AppColors.amber,
                iconBg: AppColors.amber.withValues(alpha: 0.12),
                title: 'Compréhension écrite',
                description: 'Textes courts et structure de la langue',
                meta: '$kInitialBatchSize QUESTIONS · ≈ 35 MIN',
                onTap: () => openDetail(AppRoutes.tcfCeDetail),
              ),
              HubModuleCard(
                icon: Icons.edit_note_rounded,
                iconColor: AppColors.green,
                iconBg: AppColors.green.withValues(alpha: 0.12),
                title: 'Expression écrite',
                description:
                    '3 tâches corrigées par IA avec feedback détaillé',
                meta: '3 TÂCHES · ≈ 30 MIN',
                aiTag: true,
                onTap: () => openDetail(AppRoutes.tcfEeDetail),
              ),
              HubModuleCard(
                icon: Icons.mic_rounded,
                iconColor: AppColors.red,
                iconBg: AppColors.redLight,
                title: 'Expression orale',
                description: 'Parle, enregistre, reçois ton niveau CECRL',
                meta: '3 TÂCHES · ≈ 10 MIN',
                aiTag: true,
                onTap: () => openDetail(AppRoutes.tcfEoDetail),
              ),
              const SizedBox(height: 8),
              HubExamCard(
                title: 'Examen blanc complet',
                subtitle: 'CO + CE + EE + EO en conditions réelles · 90 min',
                ctaLabel: 'Lancer',
                onTap: () => context.push(AppRoutes.tcfFullExams),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
