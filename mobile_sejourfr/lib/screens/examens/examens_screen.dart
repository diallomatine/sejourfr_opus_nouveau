import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../civique/civique_full_exams_screen.dart';
import '../module_detail/tcf_full_exams_screen.dart';

/// Parcours affiché sur l'onglet Examens (partagé pour permettre aux CTAs
/// d'arriver sur le bon parcours via `context.go`).
final examensParcoursProvider =
    StateProvider<AppModule>((_) => AppModule.tcf);

/// Onglet racine « Examens » de la refonte 2026 (cf. `MExamens` maquette) :
/// examens blancs complets des deux parcours derrière un toggle TCF/Civique.
/// TCF = examen complet orchestré CO→CE→EE→EO (20 slots) ;
/// Civique = 40 Q tous thèmes (20 slots).
class ExamensScreen extends ConsumerWidget {
  const ExamensScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parcours = ref.watch(examensParcoursProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader(
              title: 'Examens blancs',
              sub: 'Épreuves complètes, conditions réelles',
              large: true,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SegmentedTabs<AppModule>(
                tabs: parcoursSegments(
                  tcf: AppModule.tcf,
                  civique: AppModule.civique,
                ),
                value: parcours,
                onChanged: (p) =>
                    ref.read(examensParcoursProvider.notifier).state = p,
              ),
            ),
            Expanded(
              child: parcours == AppModule.tcf
                  ? const TcfFullExamsView()
                  : const CiviqueFullExamsView(),
            ),
          ],
        ),
      ),
    );
  }
}
