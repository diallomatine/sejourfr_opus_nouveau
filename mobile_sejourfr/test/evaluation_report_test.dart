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

  testWidgets('le niveau observé passe avant la note et ses précautions',
      (tester) async {
    final eval = EvaluationResult.fromJson(<String, dynamic>{
      'noteSurVingt': 12.5,
      'niveauObserve': 'B1',
      'confiance': 'MOYENNE',
      'avertissementNiveau': 'Le niveau qui fait foi est celui du bilan.',
      'feedback': <String, dynamic>{'note_globale': 12.5},
    });

    await tester.pumpWidget(_host(eval));

    expect(find.text('Proche du niveau B1'), findsOneWidget);
    expect(find.text('Confiance moyenne'), findsOneWidget);
    // La décimale du contrat courant n'est pas arrondie à l'affichage.
    expect(find.text('12,5/20', findRichText: true), findsOneWidget);

    final niveauY = tester.getTopLeft(find.text('Proche du niveau B1')).dy;
    final noteY =
        tester.getTopLeft(find.text('Note de la tâche')).dy;
    final avertissementY =
        tester.getTopLeft(find.text('Le niveau qui fait foi est celui du bilan.')).dy;
    expect(niveauY, lessThan(noteY));
    expect(niveauY, lessThan(avertissementY));
  });

  testWidgets('accomplissement avant les critères, bande et preuve',
      (tester) async {
    final eval = EvaluationResult.fromJson(<String, dynamic>{
      'noteSurVingt': 12.5,
      'niveauObserve': 'B1',
      'confiance': 'MOYENNE',
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
        'avertissements': ['Évaluation fondée sur la transcription.'],
      },
    });

    await tester.pumpWidget(_host(eval));

    expect(find.text('Évaluation fondée sur la transcription.'), findsOneWidget);
    expect(find.text('Invitation absente'), findsOneWidget);
    expect(find.text('Loyer non mentionné'), findsOneWidget);
    expect(find.textContaining("n'enlève aucun point"), findsOneWidget);

    // Bande affichée, note du critère jamais chiffrée.
    expect(find.text('Satisfaisant'), findsOneWidget);
    expect(find.text('13/20', findRichText: true), findsNothing);
    expect(find.text('« un petit appartement »'), findsOneWidget);

    final accomplissementY =
        tester.getTopLeft(find.text('Ce que demandait la consigne')).dy;
    final criteresY = tester.getTopLeft(find.text('Détail par critères')).dy;
    expect(accomplissementY, lessThan(criteresY));
  });

  testWidgets('une priorité enseigne : technique et démonstration visibles',
      (tester) async {
    final eval = EvaluationResult.fromJson(<String, dynamic>{
      'noteSurVingt': 12.5,
      'feedback': <String, dynamic>{
        'points_a_ameliorer': [
          {
            'constat': 'Vos idées sont posées les unes après les autres.',
            'comment': 'Reliez-les avec un connecteur : remplacez le point '
                'entre deux idées liées par « et » ou « parce que ».',
            'exemple': {
              'avant': 'Je cherche un travail. Je suis motivé.',
              'apres': 'Je cherche un travail parce que je suis motivé.',
            },
          },
        ],
        'exemples_corriges': [
          {
            'original': 'Il fait beau. Je sors.',
            'corrige': 'Comme il fait beau, je sors.',
            'explication': 'La subordonnée relie la cause et la conséquence.',
            'gain': 'emploie une subordonnée, marqueur attendu au B1',
          },
        ],
      },
    });

    await tester.pumpWidget(_host(eval));

    expect(find.text('Votre priorité'), findsOneWidget);
    expect(find.text('COMMENT FAIRE'), findsOneWidget);
    expect(find.textContaining('Reliez-les avec un connecteur'), findsOneWidget);
    expect(
      find.text('Votre phrase : Je cherche un travail. Je suis motivé.',
          findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('Réécrite : Je cherche un travail parce que je suis motivé.',
          findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('emploie une subordonnée, marqueur attendu au B1'),
      findsOneWidget,
    );
  });

  testWidgets('une priorité déjà en base sous forme de chaîne reste lisible',
      (tester) async {
    final eval = EvaluationResult.fromJson(<String, dynamic>{
      'noteSurVingt': 14,
      'feedback': <String, dynamic>{
        'points_a_ameliorer': ['Penser à inviter', 'Varier les connecteurs'],
        'exemples_corriges': [
          {
            'original': 'jai fini',
            'corrige': "j'ai fini",
            'explication': 'Apostrophe manquante.',
          },
        ],
      },
    });

    await tester.pumpWidget(_host(eval));

    expect(find.text('Vos priorités'), findsOneWidget);
    expect(find.text('Penser à inviter'), findsOneWidget);
    expect(find.text('Varier les connecteurs'), findsOneWidget);
    // Ni encadré technique ni démonstration : rien à inventer sur l'ancien
    // format, et surtout pas de bloc vide.
    expect(find.text('COMMENT FAIRE'), findsNothing);
    expect(find.text('SUR VOTRE PRODUCTION'), findsNothing);
  });

  testWidgets('évaluation ancienne : ni niveau, ni accomplissement, note du '
      'critère chiffrée', (tester) async {
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

    expect(find.textContaining('Proche du niveau'), findsNothing);
    expect(find.text('Ce que demandait la consigne'), findsNothing);
    expect(find.text('Détail par critères'), findsOneWidget);
    expect(find.text('Richesse lexicale'), findsOneWidget);
    expect(find.text('13/20', findRichText: true), findsOneWidget);
  });

  testWidgets('chaque code de critère a son icône et son libellé',
      (tester) async {
    // Les 4 codes de la grille courante (cf. production-rubrics-v5.json) + les
    // codes des grilles précédentes, encore portés par les évaluations en base.
    const codes = [
      'communiquer',
      'interagir',
      'lexique',
      'morphosyntaxe',
      'realisation_consigne',
      'adequation_destinataire',
      'chronologie_recit',
      'developpement_reponses',
      'prise_position',
      'argumentation',
      'conduite_echange',
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

    expect(find.textContaining('Proche du niveau'), findsNothing);
    // Aucun niveau ATTRIBUÉ à la production : ni l'en-tête de la carte, ni la
    // pastille. La légende de l'échelle du TCF (« 6 à 9 à B1 ») cite les
    // paliers sans en attribuer un — elle dit comment lire la note, pas où se
    // situe le candidat ; d'où la recherche exacte et non `textContaining`.
    expect(find.text('NIVEAU OBSERVÉ SUR CETTE TÂCHE'), findsNothing);
    expect(find.text('B1'), findsNothing);
  });
}
