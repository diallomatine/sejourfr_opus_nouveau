import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import 'session_view.dart';
import 'widgets/bilan_hero.dart';
import 'widgets/feedback_block.dart';
import 'widgets/production_app_header.dart';
import 'widgets/tache_bilan_row.dart';

/// Ecran "Bilan global" affiche apres la 3e tache d'une session EO ou EE.
/// Hero bleu avec moyenne + niveau global + barre CECRL, puis liste detaillee
/// par tache, puis bandeau violet "Vos prochaines etapes".
class SessionBilanScreen extends ConsumerWidget {
  const SessionBilanScreen({super.key, required this.epreuve});

  final EpreuveType epreuve;

  String get _moduleTitle => epreuve == EpreuveType.tcfEo
      ? 'Resultats — Expression orale'
      : 'Resultats — Expression ecrite';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = readSessionView(ref, epreuve);
    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: ProductionAppHeader(title: _moduleTitle),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: ProductionAppHeader(
        title: _moduleTitle,
        rightAction: const ProductionAppHeaderInfo(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                children: [
                  BilanHero(
                    moyenneSur20: session.noteMoyenne,
                    niveauGlobal: session.niveauGlobal,
                  ),
                  Text(
                    'Detail par tache',
                    style: AppFonts.jakarta(
                      size: 15,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(session.total, (i) {
                    final task = session.taskAt(i)!;
                    final sub = session.submissions[i];
                    return TacheBilanRow(
                      name: 'Tache ${i + 1} — ${task.displayTitle}',
                      niveauCible: task.niveauCible,
                      score: sub?.evaluation?.noteSurVingt,
                      niveauObtenu: sub?.evaluation?.niveauCecrl,
                    );
                  }),
                  const SizedBox(height: 12),
                  FeedbackBlock(
                    kind: FeedbackKind.suggest,
                    title: 'Vos prochaines etapes',
                    items: [_nextStepsMessage(session)],
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.line2, width: 1)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: SafeArea(
                top: false,
                child: AppButton(
                  label: 'Terminer la session',
                  icon: Icons.check_rounded,
                  onPressed: () {
                    resetSession(ref, epreuve);
                    context.go(AppRoutes.trainingSetup);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _nextStepsMessage(SessionView session) {
    final niveau = session.niveauGlobal;
    if (niveau == null) {
      return "Continuez a vous entrainer pour qu'on puisse evaluer votre niveau "
          "plus precisement.";
    }
    final modaliteAdj = epreuve == EpreuveType.tcfEo ? 'orale' : 'ecrite';
    switch (niveau) {
      case NiveauCecrl.a1NonAtteint:
      case NiveauCecrl.a1:
        return "Niveau $niveau.displayName : revenez aux bases de l'expression "
            "$modaliteAdj. Visez le A2 prochainement.";
      case NiveauCecrl.a2:
        return "Niveau A2 atteint, suffisant pour la Carte de sejour. "
            "Pour viser un niveau superieur, entrainez-vous regulierement.";
      case NiveauCecrl.b1:
        return "Niveau B1 atteint, suffisant pour la Carte de resident. "
            "Visez le B2 pour la naturalisation.";
      case NiveauCecrl.b2:
        return "Excellent : niveau B2 atteint, requis pour la naturalisation francaise.";
      case NiveauCecrl.c1:
      case NiveauCecrl.c2:
        return "Niveau ${niveau.displayName} — bravo, votre francais "
            "$modaliteAdj est avance.";
    }
  }
}
