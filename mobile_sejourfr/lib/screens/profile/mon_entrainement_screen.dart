import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/list_group.dart';
import '../../core/widgets/screen_header.dart';

/// Hub « Mon entraînement » accessible depuis le profil. Regroupe les trois
/// surfaces de suivi personnel : l'historique des examens blancs / sessions IA,
/// les questions ratées et les favoris (ces deux dernières existaient avant la
/// refonte 2026 sur l'accueil ; chacune a désormais sa page dédiée :
/// `MesQuestionsScreen` / `MesFavorisScreen`).
class MonEntrainementScreen extends StatelessWidget {
  const MonEntrainementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Mon entraînement',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  ListGroup(
                    children: [
                      ListRow(
                        icon: LucideIcons.history,
                        title: 'Mon historique',
                        sub: 'Examens civique, TCF + sessions IA EE/EO',
                        onTap: () => context.push(AppRoutes.historiques),
                      ),
                      ListRow(
                        icon: LucideIcons.listChecks,
                        iconBg: AppColors.redLight,
                        iconColor: AppColors.red,
                        title: 'Mes questions',
                        sub: 'Revoir vos erreurs récentes',
                        onTap: () => context.push(AppRoutes.mesQuestions),
                      ),
                      ListRow(
                        icon: LucideIcons.bookmark,
                        title: 'Mes favoris',
                        sub: 'Questions épinglées pendant l\'entraînement',
                        onTap: () => context.push(AppRoutes.mesFavoris),
                      ),
                    ],
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
