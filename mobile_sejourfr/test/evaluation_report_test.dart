import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/core/models/production_models.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/criterion_row.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/evaluation_report.dart';

Widget _host(EvaluationResult eval) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: EvaluationReport(evaluation: eval)),
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('v4 : accomplissement avant les critères, bande et preuve',
      (tester) async {
    final eval = EvaluationResult.fromJson(<String, dynamic>{
      'noteSurVingt': 13,
      'niveauObserve': 'B1',
      'confiance': 'MOYENNE',
      'avertissementNiveau': 'Le niveau qui fait foi est celui du bilan.',
      'feedback': <String, dynamic>{
        'accomplissement': <String, dynamic>{
          'points_traites': [
            {'libelle': 'Nouvelle annoncée', 'obligatoire': true},
          ],
          'points_oublies': [
            {'libelle': 'Invitation absente', 'obligatoire': true},
            {'libelle': 'Loyer non mentionné', 'obligatoire': false},
          ],
        },
        'scores_criteres': [
          {
            'code': 'lexique',
            'label': 'Étendue du lexique',
            'note_sur_20': 13,
            'bande': 'SATISFAISANT',
            'commentaire': 'Vocabulaire courant.',
            'preuve': 'un petit appartement',
          },
        ],
        'points_a_ameliorer': ['Penser à inviter', 'Varier les connecteurs'],
        'avertissements': ['Évaluation fondée sur la transcription.'],
      },
    });

    await tester.pumpWidget(_host(eval));

    expect(
      find.text('Performance observée sur cette tâche : proche du niveau B1'),
      findsOneWidget,
    );
    expect(find.textContaining('confiance moyenne'), findsOneWidget);
    expect(find.text('Évaluation fondée sur la transcription.'), findsOneWidget);
    expect(find.text('Invitation absente'), findsOneWidget);
    expect(find.text('Loyer non mentionné'), findsOneWidget);
    expect(find.textContaining("n'enlève aucun point"), findsOneWidget);

    // Bande affichée, note du critère jamais chiffrée.
    expect(find.text('Satisfaisant'), findsOneWidget);
    expect(find.textContaining('13', findRichText: true), findsNothing);
    expect(find.text('« un petit appartement »'), findsOneWidget);

    expect(find.text('Vos priorités'), findsOneWidget);

    // L'accomplissement passe avant le détail de langue.
    final accomplissementY =
        tester.getTopLeft(find.text('Ce que demandait la consigne')).dy;
    final criteresY = tester.getTopLeft(find.text('Détail par critères')).dy;
    expect(accomplissementY, lessThan(criteresY));
  });

  testWidgets('v3 : ni niveau ni accomplissement, note du critère chiffrée',
      (tester) async {
    final eval = EvaluationResult.fromJson(<String, dynamic>{
      'noteSurVingt': 14,
      'feedback': <String, dynamic>{
        'scores_criteres': [
          {
            'code': 'lexique',
            'note_sur_20': 13,
            'commentaire': 'Vocabulaire correct.',
          },
        ],
      },
    });

    await tester.pumpWidget(_host(eval));

    expect(find.textContaining('Performance observée'), findsNothing);
    expect(find.text('Ce que demandait la consigne'), findsNothing);
    expect(find.text('Détail par critères'), findsOneWidget);
    expect(find.text('Richesse lexicale'), findsOneWidget);
    expect(find.text('13/20', findRichText: true), findsOneWidget);
  });

  testWidgets('chaque code de critère v4 a son icône et son libellé',
      (tester) async {
    // Les 10 codes distincts des rubriques v4 (cf. production-rubrics-v4.json)
    // + `pertinence`, encore porté par les évaluations déjà en base.
    const codes = [
      'realisation_consigne',
      'adequation_destinataire',
      'chronologie_recit',
      'developpement_reponses',
      'prise_position',
      'argumentation',
      'conduite_echange',
      'lexique',
      'morphosyntaxe',
      'coherence',
      'pertinence',
    ];

    for (final code in codes) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CriterionRow(
              criterion: CriterionScore(
                code: code,
                noteSurVingt: 13,
                commentaire: '',
                bande: BandeCritere.satisfaisant,
              ),
            ),
          ),
        ),
      );

      // L'icône par défaut signalerait un code non couvert par la table.
      expect(
        find.byIcon(LucideIcons.listChecks),
        findsNothing,
        reason: 'Code $code : icône par défaut',
      );
      // Un libellé absent de la table retomberait sur le code brut.
      expect(find.text(code), findsNothing, reason: 'Code $code : libellé brut');
    }
  });

  testWidgets('garde-fou : pas de niveau affiché sans confiance',
      (tester) async {
    final eval = EvaluationResult.fromJson(<String, dynamic>{
      'noteSurVingt': 12,
      'niveauObserve': 'B1',
      'feedback': <String, dynamic>{},
    });

    await tester.pumpWidget(_host(eval));

    expect(find.textContaining('Performance observée'), findsNothing);
    expect(find.textContaining('B1'), findsNothing);
  });
}
