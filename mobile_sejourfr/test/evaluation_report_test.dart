import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/core/models/production_models.dart';
import 'package:sejourfr_mobile/core/theme/app_theme.dart';
import 'package:sejourfr_mobile/core/widgets/app_tag.dart';
import 'package:sejourfr_mobile/screens/tcf_production/production_result_labels.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/action_plan.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/criterion_row.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/evaluation_report.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/results_hero.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/tcf_note_scale.dart';

Widget _host(
  EvaluationResult eval, {
  bool isOral = false,
  String? productionText,
  String? eyebrow,
  TargetLevel? targetLevel,
}) =>
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EvaluationReport(
            evaluation: eval,
            isOral: isOral,
            eyebrow: eyebrow,
            productionText: productionText,
            targetLevel: targetLevel,
          ),
        ),
      ),
    );

EvaluationResult _eval(Map<String, dynamic> json) =>
    EvaluationResult.fromJson(json);

/// Ouvre la regle de lecture du niveau : elle vit derriere un geste, pas a
/// plat entre le verdict et le premier conseil.
Future<void> _openReadingRule(WidgetTester tester, {String? via}) async {
  final target = find.text(via ?? 'NIVEAU ESTIMÉ');
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Ouvre l'un des deux bandeaux de synthese : ils sont replies par defaut, et
/// leur detail s'affiche DANS le bandeau, juste sous l'en-tete.
Future<void> _openTile(WidgetTester tester, String title) async {
  final header = find.text(title);
  await tester.ensureVisible(header);
  await tester.tap(header);
  await tester.pumpAndSettle();
}

/// Deplie le detail d'un critere : le bouton « Voir pourquoi » de la maquette.
Future<void> _openCriterion(WidgetTester tester) async {
  final button = find.text('Voir pourquoi');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('hero : verdict et niveau dans un seul bloc, aucune note', () {
    Map<String, dynamic> withObjectif(String objectif) => <String, dynamic>{
          'noteSurVingt': 4.5,
          'feedback': <String, dynamic>{
            'accomplissement': <String, dynamic>{
              'objectif': objectif,
              'objectif_resume': 'Vous annoncez la nouvelle mais vous '
                  "n'invitez personne.",
            },
          },
        };

    testWidgets('le verdict et le resume vivent dans le meme hero, en tete du '
        'rapport — et AUCUNE note ne s\'y affiche', (tester) async {
      await tester.pumpWidget(_host(
        _eval(withObjectif('ATTEINT')),
        eyebrow: 'Expression écrite · Tâche 1',
      ));

      expect(find.text('EXPRESSION ÉCRITE · TÂCHE 1'), findsOneWidget);
      expect(find.text('Objectif atteint'), findsOneWidget);
      expect(find.textContaining("vous n'invitez personne"), findsOneWidget);

      // Au TCF, une tache recoit un NIVEAU, jamais une note : le /20 ne porte
      // que sur l'epreuve entiere. Et 4,5/20 y est un A2 parfaitement normal,
      // qu'un francophone lit comme une catastrophe scolaire.
      expect(find.textContaining('/20', findRichText: true), findsNothing);
      expect(find.textContaining('4,5', findRichText: true), findsNothing);

      final hero = find.byType(ProductionResultsHero);
      expect(hero, findsOneWidget);
      expect(
        find.descendant(of: hero, matching: find.text('Objectif atteint')),
        findsOneWidget,
      );
      expect(tester.getTopLeft(hero).dy, lessThan(1));
    });

    testWidgets('partiellement atteint : son propre libellé',
        (tester) async {
      await tester
          .pumpWidget(_host(_eval(withObjectif('PARTIELLEMENT_ATTEINT'))));

      expect(find.text('Objectif partiellement atteint'), findsOneWidget);
      expect(find.text('Objectif atteint'), findsNothing);
    });

    testWidgets('non atteint : son propre libellé', (tester) async {
      await tester.pumpWidget(_host(_eval(withObjectif('NON_ATTEINT'))));

      expect(find.text('Objectif non atteint'), findsOneWidget);
      expect(find.text('Objectif atteint'), findsNothing);
    });

    testWidgets('évaluation legacy sans objectif : titre neutre, hero cohérent',
        (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 4.5,
        'feedback': <String, dynamic>{
          'accomplissement': <String, dynamic>{
            'points_traites': [
              {'libelle': 'Nouvelle annoncée', 'obligatoire': true},
            ],
          },
        },
      })));

      expect(find.textContaining('Objectif '), findsNothing);
      // Le hero reste coherent : titre neutre, et toujours aucune note.
      expect(find.text('Votre correction'), findsOneWidget);
      expect(find.textContaining('/20', findRichText: true), findsNothing);
    });
  });

  // Le rapport se lit sur un telephone etroit, pas sur la fenetre par defaut
  // du harnais de test (800 px). Un debordement y passerait inapercu.
  testWidgets('aucun débordement sur un téléphone étroit (360 px)',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(
      _eval(<String, dynamic>{
        'noteSurVingt': 12.5,
        'niveauObserve': 'B2',
        'confiance': 'MOYENNE',
        'feedback': <String, dynamic>{
          'accomplissement': <String, dynamic>{
            'objectif': 'PARTIELLEMENT_ATTEINT',
            'objectif_resume': 'Vous annoncez la nouvelle mais vous n\'invitez '
                'personne à venir.',
            'points_traites': [
              {'libelle': 'Nouvelle annoncée', 'obligatoire': true},
            ],
            'points_oublies': [
              {'libelle': 'Invitation absente', 'obligatoire': true},
            ],
          },
          'confiance_raisons': ['transcription partiellement incertaine'],
          'points_forts': ['Le passé composé est employé à bon escient.'],
          'points_a_ameliorer': [
            {
              'constat': 'Votre conclusion introduit une idée vague.',
              'comment': 'Reliez-la directement à la séance proposée.',
              'exemple': {
                'avant': 'On va régler ça ensemble.',
                'apres': 'J\'espère que cette date te convient.',
              },
            },
          ],
          'scores_criteres': [
            {
              'code': 'communiquer',
              'note_sur_20': 13,
              'bande': 'SATISFAISANT',
              'commentaire': 'Les idées s\'enchaînent naturellement.',
              'preuve': 'je te propose une autre séance',
            },
          ],
        },
      }),
      eyebrow: 'Expression écrite · Tâche 1',
      productionText: 'Bonjour Khalil, je t\'écris pour m\'excuser.',
      // Le rappel d'enjeu est la ligne la plus longue du hero : il doit tenir
      // sur un 360 px comme le reste.
      targetLevel: TargetLevel.b1,
    ));

    expect(tester.takeException(), isNull);
    expect(find.text('VOTRE DÉMARCHE'), findsOneWidget);
  });

  group('ce qui marche / à corriger en priorité', () {
    testWidgets('deux bandeaux d\'une ligne, repliés, qui ouvrent leur détail '
        'juste en dessous', (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 12,
        'feedback': <String, dynamic>{
          'accomplissement': <String, dynamic>{
            'points_traites': [
              {'libelle': 'Excuse', 'obligatoire': true},
              {'libelle': 'Raison de l\'absence', 'obligatoire': true},
              // Une piste traitee ne gonfle pas le compteur : elle n'etait pas
              // demandee.
              {'libelle': 'Ambiance du quartier', 'obligatoire': false},
            ],
            'points_oublies': [
              {'libelle': 'Nouvelle séance', 'obligatoire': true},
              {'libelle': 'Loyer', 'obligatoire': false},
            ],
          },
          'points_a_ameliorer': [
            {'constat': 'Votre conclusion reste vague.'},
          ],
        },
      })));

      // Chacun tient sur une ligne : un titre, un chiffre, un chevron.
      expect(find.text('Ce qui marche'), findsOneWidget);
      expect(find.text('2/3 points traités'), findsOneWidget);
      expect(find.text('À corriger en priorité'), findsOneWidget);
      expect(find.text('1 priorité'), findsOneWidget);

      // Replies : aucun detail en clair.
      expect(find.text('Excuse'), findsNothing);
      expect(find.text('Votre conclusion reste vague.'), findsNothing);

      await _openTile(tester, 'Ce qui marche');
      expect(find.text('Excuse'), findsOneWidget);
      expect(find.text('Raison de l\'absence'), findsOneWidget);
      // La piste traitee n'a jamais compte : elle n'apparait pas non plus ici.
      expect(find.text('Ambiance du quartier'), findsNothing);

      await _openTile(tester, 'À corriger en priorité');
      // La priorite vit a UN SEUL endroit : plus de resume en haut suivi du
      // meme texte en entier plus bas.
      expect(find.text('Votre conclusion reste vague.'), findsOneWidget);
    });

    testWidgets('rien à résumer : pas de rangée vide', (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 12,
        'feedback': <String, dynamic>{},
      })));

      expect(find.text('Ce qui marche'), findsNothing);
      expect(find.text('À corriger en priorité'), findsNothing);
    });
  });

  group('le niveau, heros de la carte', () {
    testWidgets('le niveau s\'affirme, avec sa barre de paliers et sans une '
        'seule borne chiffree', (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 4.5,
        'niveauObserve': 'A2',
        'confiance': 'HAUTE',
        'feedback': <String, dynamic>{},
      })));

      expect(find.text('NIVEAU ESTIMÉ'), findsOneWidget);
      // « Proche de » veut dire « pas encore » en francais courant, alors que
      // le niveau EST A2 et que la pastille juste a cote le dit.
      expect(find.text('Votre production est au niveau A2'), findsOneWidget);
      expect(find.textContaining('Proche du niveau'), findsNothing);
      // Les 5 paliers du TCF, en une seule ligne de libelles sous la barre.
      expect(find.text('<A1'), findsOneWidget);
      expect(find.text('A2'), findsWidgets);
      // Bornes chiffrees du bareme : nulle part, ni a plat ni dans le repli.
      await _openReadingRule(tester);
      for (final borne in ['0', '1', '2-5', '6-9', '10-20']) {
        expect(find.text(borne), findsNothing, reason: borne);
      }
    });

    test('chaque palier de la table officielle recoit sa note', () {
      expect(TcfNoteScale.bandFor(0)!.niveau, NiveauCecrl.a1NonAtteint);
      expect(TcfNoteScale.bandFor(1)!.niveau, NiveauCecrl.a1);
      expect(TcfNoteScale.bandFor(2)!.niveau, NiveauCecrl.a2);
      expect(TcfNoteScale.bandFor(4.5)!.niveau, NiveauCecrl.a2);
      expect(TcfNoteScale.bandFor(5)!.niveau, NiveauCecrl.a2);
      expect(TcfNoteScale.bandFor(6)!.niveau, NiveauCecrl.b1);
      expect(TcfNoteScale.bandFor(9)!.niveau, NiveauCecrl.b1);
      // 10/20 est deja un B2 au TCF : c'est tout l'enjeu de l'echelle.
      expect(TcfNoteScale.bandFor(10)!.niveau, NiveauCecrl.b2);
      expect(TcfNoteScale.bandFor(20)!.niveau, NiveauCecrl.b2);
    });

    test('une note qui n\'est pas un nombre n\'a aucun palier', () {
      // `NaN >= 0` est faux : une comparaison naive retombait sur l'index 0 et
      // affichait « A1 non atteint », un niveau que personne n'a obtenu.
      expect(TcfNoteScale.bandIndexFor(double.nan), isNull);
      expect(TcfNoteScale.bandFor(double.nan), isNull);
    });

    test('les cinq paliers se suivent, C1/C2 rabattus sur le plafond B2', () {
      expect(
        kTcfPaliers.map((n) => n.tcfPalierIndex).toList(),
        [0, 1, 2, 3, 4],
      );
      expect(NiveauCecrl.c1.tcfPalierIndex, 4);
      expect(NiveauCecrl.c2.tcfPalierIndex, 4);
    });

    testWidgets('le plancher ne se dit pas « proche de », et ne dit pas non '
        'plus « sous le A1 »', (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 0,
        'niveauObserve': 'A1_NON_ATTEINT',
        'confiance': 'MOYENNE',
        'feedback': <String, dynamic>{},
      })));

      expect(
        find.text("Votre production n'atteint pas encore le niveau A1"),
        findsOneWidget,
      );
      expect(find.textContaining('Proche du niveau'), findsNothing);
    });

    testWidgets('une production non notee garde son panneau, sans note ni '
        'palier invente', (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'feedback': <String, dynamic>{},
      })));

      expect(find.text('NIVEAU ESTIMÉ'), findsOneWidget);
      expect(
        find.text('Niveau indisponible pour cette production'),
        findsOneWidget,
      );
      expect(find.textContaining('/20', findRichText: true), findsNothing);
    });
  });

  // La couleur d'une note de production vient de son PALIER TCF, jamais d'un
  // seuil scolaire sur 20. Ce que verrouille ce groupe est la regle appliquee
  // partout ou une note s'affiche — carte de sujet EO/EE comprise, ou un
  // `note <= 12 ? rouge : vert` peignait en rouge le meilleur niveau du TCF.
  group('couleur dérivée du palier TCF', () {
    test('12/20 est un B2 : jamais rouge, jamais un « échec »', () {
      final band = TcfNoteScale.bandFor(12)!;

      expect(band.niveau, NiveauCecrl.b2);
      expect(band.tone, NiveauCecrl.b2.color);
      expect(band.tone, isNot(AppColors.red));
      expect(band.niveau.tagTone, TagTone.success);
      expect(band.niveau.tagTone, isNot(TagTone.red));
    });

    test('chaque palier prend la teinte canonique de son niveau', () {
      for (final note in [0.0, 1.0, 3.0, 5.0, 6.0, 9.0, 10.0, 12.0, 20.0]) {
        final band = TcfNoteScale.bandFor(note)!;
        expect(band.tone, band.niveau.color, reason: 'note $note');
        // Jamais de rouge pour un niveau : la regle du projet, verrouillee ici.
        expect(band.tone, isNot(AppColors.red), reason: 'note $note');
        expect(band.niveau.tagTone, isNot(TagTone.red), reason: 'note $note');
      }
    });

    test('le ton de badge suit exactement CecrlColor', () {
      expect(NiveauCecrl.a1NonAtteint.tagTone, TagTone.amber);
      expect(NiveauCecrl.a1.tagTone, TagTone.amber);
      expect(NiveauCecrl.a2.tagTone, TagTone.amber);
      expect(NiveauCecrl.b1.tagTone, TagTone.blue);
      expect(NiveauCecrl.b2.tagTone, TagTone.success);
    });

    // `tagTone` derive desormais de `color` : les deux formes ne PEUVENT plus
    // diverger. On le verifie explicitement, palier par palier, sur les sept
    // niveaux — c'etait la seule chose qui tenait les deux `switch` d'accord
    // avant la deduplication.
    test('les deux formes de la teinte d\'un niveau restent d\'accord', () {
      final attendu = <Color, TagTone>{
        AppColors.amber: TagTone.amber,
        AppColors.blue: TagTone.blue,
        AppColors.green: TagTone.success,
      };

      for (final niveau in NiveauCecrl.values) {
        expect(
          attendu[niveau.color],
          isNotNull,
          reason: '${niveau.name} : teinte hors de la palette des niveaux',
        );
        expect(
          niveau.tagTone,
          attendu[niveau.color],
          reason: '${niveau.name} : le badge dit autre chose que la couleur',
        );
        expect(niveau.color, isNot(AppColors.red), reason: niveau.name);
        expect(niveau.tagTone, isNot(TagTone.red), reason: niveau.name);
      }
    });

    test('C1 et C2, hors TCF IRN, se lisent comme le B2', () {
      for (final niveau in [NiveauCecrl.c1, NiveauCecrl.c2]) {
        expect(niveau.color, NiveauCecrl.b2.color);
        expect(niveau.tagTone, NiveauCecrl.b2.tagTone);
      }
    });
  });

  group('confiance', () {
    testWidgets('une confiance haute ne s\'affiche pas : c\'est le cas normal',
        (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 12,
        'niveauObserve': 'B2',
        'confiance': 'HAUTE',
        'feedback': <String, dynamic>{
          'confiance_raisons': ['transcription nette'],
        },
      })));

      expect(find.text('Confiance haute'), findsNothing);
      expect(find.text('transcription nette'), findsNothing);
      // Le niveau, lui, reste affiché.
      expect(find.text('NIVEAU ESTIMÉ'), findsOneWidget);
    });

    testWidgets('une confiance moyenne s\'affiche avec ses raisons',
        (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 7,
        'niveauObserve': 'B1',
        'confiance': 'MOYENNE',
        'feedback': <String, dynamic>{
          'confiance_raisons': ['transcription partiellement incertaine'],
        },
      })));

      expect(find.text('Confiance moyenne'), findsOneWidget);
      expect(
          find.text('transcription partiellement incertaine'), findsOneWidget);
      // Le repli n'apparait que faute de raisons.
      expect(find.text(kConfianceSansRaison), findsNothing);
    });

    testWidgets('sans raison fournie, la pastille est expliquée quand même',
        (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 7,
        'niveauObserve': 'B1',
        'confiance': 'FAIBLE',
        'feedback': <String, dynamic>{},
      })));

      expect(find.text('Confiance faible'), findsOneWidget);
      expect(find.text(kConfianceSansRaison), findsOneWidget);
    });

    testWidgets('garde-fou : pas de niveau affiché sans confiance',
        (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 12,
        'niveauObserve': 'B1',
        'feedback': <String, dynamic>{},
      })));

      // Le panneau reste (il porte la regle de lecture), mais il n'attribue
      // aucun niveau : ni libelle affirme, ni pastille, ni barre de paliers.
      expect(
        find.text('Niveau indisponible pour cette production'),
        findsOneWidget,
      );
      expect(find.textContaining('Votre production est au niveau'), findsNothing);
      expect(find.text('<A1'), findsNothing);
      expect(find.text('Confiance moyenne'), findsNothing);
      expect(find.textContaining('/20', findRichText: true), findsNothing);
    });
  });

  group('portée du niveau', () {
    testWidgets('la règle de lecture se consulte, elle ne s\'impose pas entre '
        'le verdict et le premier conseil — et elle explique le NIVEAU, pas '
        'une note invisible', (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 7,
        'feedback': <String, dynamic>{},
      })));

      expect(find.text(kNiveauPorteeTache), findsNothing);
      await _openReadingRule(tester);
      expect(find.text(kNiveauPorteeTache), findsOneWidget);
      expect(kNiveauPorteeTache.contains('note'), isFalse);
      expect(kNiveauPorteeTache.contains('/20'), isFalse);
    });

    testWidgets('avec avertissement du backend : il REMPLACE la générique, '
        'il ne s\'y ajoute pas', (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 7,
        'avertissementNiveau': 'Le niveau qui fait foi est celui du bilan des '
            'trois tâches.',
        'feedback': <String, dynamic>{},
      })));

      await _openReadingRule(tester);
      expect(
        find.text('Le niveau qui fait foi est celui du bilan des trois '
            'tâches.'),
        findsOneWidget,
      );
      // Dire deux fois la meme chose est exactement le defaut que la refonte
      // corrige.
      expect(find.text(kNiveauPorteeTache), findsNothing);
    });
  });

  group('profil par critère', () {
    final json = <String, dynamic>{
      'noteSurVingt': 12.5,
      'feedback': <String, dynamic>{
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
      },
    };

    testWidgets('visible sans déplier, et sous son NOM COURT — la définition '
        'du serveur tient sur deux lignes et chasse la bande', (tester) async {
      await tester.pumpWidget(_host(_eval(json)));

      expect(find.text('Votre profil en un coup d\'œil'), findsOneWidget);
      expect(find.text('Vocabulaire'), findsOneWidget);
      expect(find.text('Étendue du lexique'), findsNothing);
      expect(find.text('Niveau B1'), findsOneWidget);
      // Le critere se lit en bande, jamais en chiffres.
      expect(find.text('13/20', findRichText: true), findsNothing);
    });

    testWidgets('la définition, le commentaire et la preuve se déplient ligne '
        'par ligne', (tester) async {
      await tester.pumpWidget(_host(_eval(json)));

      expect(find.text('Vocabulaire courant.'), findsNothing);
      expect(find.text('« un petit appartement »'), findsNothing);

      await _openCriterion(tester);

      // La definition du serveur n'est pas perdue : elle est rangee ici.
      expect(find.text('Étendue du lexique'), findsOneWidget);
      expect(find.text('Vocabulaire courant.'), findsOneWidget);
      expect(find.text('« un petit appartement »'), findsOneWidget);
    });

    testWidgets('aucun critère : pas de section vide', (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 12,
        'feedback': <String, dynamic>{},
      })));

      expect(find.text('Votre profil en un coup d\'œil'), findsNothing);
    });
  });

  // ⚠️ Test RETOURNE (2026-08-08). Il verrouillait l'affichage de
  // `version_amelioree` en bascule sous la redaction ; il verrouille desormais
  // sa DISPARITION. Motif mesure : un candidat a recopie ce texte — le plus
  // visible et le plus copiable de l'ecran, et sans mention de niveau — l'a
  // resoumis tel quel, et a obtenu exactement la meme note et le meme niveau.
  // C'est `version_ciblee` qui fait monter, pas celle-la.
  group('votre rédaction — aucune version améliorée', () {
    final json = <String, dynamic>{
      'noteSurVingt': 12,
      'feedback': <String, dynamic>{
        'version_amelioree': 'Bonjour Marie, je viens de trouver un '
            'appartement dans le centre-ville.',
      },
    };

    testWidgets('le texte rendu, et RIEN qui le réécrive à son propre niveau',
        (tester) async {
      await tester.pumpWidget(_host(
        _eval(json),
        productionText: 'Bonjour Marie, j\'ai trouvé un appartement.',
      ));

      expect(find.text('Votre rédaction'), findsOneWidget);
      expect(
        find.text('Bonjour Marie, j\'ai trouvé un appartement.'),
        findsOneWidget,
      );
      // Ni le texte, ni la bascule, ni son etiquette : le champ est encore
      // servi par l'API, mais plus aucun widget ne le lit.
      expect(find.textContaining('je viens de trouver'), findsNothing);
      expect(find.text('Voir la version améliorée'), findsNothing);
      expect(find.text('Masquer la version améliorée'), findsNothing);
      expect(find.text('Version améliorée'), findsNothing);
      expect(find.text('VERSION AMÉLIORÉE'), findsNothing);
      // Et pas de promesse de comparaison qui n'a plus d'objet.
      expect(find.textContaining('Comparez'), findsNothing);
    });

    testWidgets('sans texte rendu, aucune carte autonome ne la ramène',
        (tester) async {
      await tester.pumpWidget(_host(_eval(json)));

      expect(find.text('Version améliorée'), findsNothing);
      expect(find.textContaining('je viens de trouver'), findsNothing);
      expect(find.text('Votre rédaction'), findsNothing);
    });

    testWidgets('absente à l\'oral aussi, sans trou visuel', (tester) async {
      await tester.pumpWidget(_host(_eval(json), isOral: true));

      expect(find.text('Version améliorée'), findsNothing);
      expect(find.textContaining('je viens de trouver'), findsNothing);
    });

    testWidgets('les repères de la priorité n° 1 restent, eux', (tester) async {
      await tester.pumpWidget(_host(
        _eval(<String, dynamic>{
          'noteSurVingt': 12,
          'feedback': <String, dynamic>{
            'points_a_ameliorer': [
              {
                'constat': 'Votre conclusion reste vague.',
                'exemple': {
                  'avant': 'on verra bien.',
                  'apres': 'je te confirme la date demain.',
                },
              },
            ],
          },
        }),
        productionText: 'Bonjour Marie, on verra bien.',
      ));

      expect(find.text('Masquer les repères'), findsOneWidget);
      await tester.tap(find.text('Masquer les repères'));
      await tester.pumpAndSettle();
      expect(find.text('Afficher les repères'), findsOneWidget);
    });
  });

  // ⚠️ Groupe RETOURNE (contrat v15/v9) : le correcteur ne produit plus
  // `exemples_corriges` ni `suggestions`, et « Voir l'analyse complète » —
  // que personne n'ouvrait — disparait avec eux. Ce qui vivait dans ce repli
  // sans venir du LLM n'a PAS disparu pour autant : les avertissements
  // remontent en note sous le hero, la check-list de la consigne vit dans
  // « Ce qui marche ».
  group("plus d'analyse complète", () {
    final json = <String, dynamic>{
      'noteSurVingt': 12.5,
      'feedback': <String, dynamic>{
        'accomplissement': <String, dynamic>{
          'objectif': 'PARTIELLEMENT_ATTEINT',
          'objectif_resume': 'Deux points sur trois sont traités.',
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
        // Encore portes par une centaine d'evaluations en base : ils se
        // decodent toujours, aucun ecran candidat ne les affiche.
        'exemples_corriges': [
          {
            'original': 'Il fait beau. Je sors.',
            'corrige': 'Comme il fait beau, je sors.',
            'explication': 'La subordonnée relie les deux idées.',
          },
        ],
        'suggestions': ['Relisez-vous à voix haute.'],
        'avertissements': ['Production plus courte que demandé.'],
      },
    };

    testWidgets('ni repli, ni corrections, ni suggestions — même sur une '
        'évaluation qui les porte encore', (tester) async {
      await tester.pumpWidget(_host(_eval(json)));

      expect(find.text("Voir l'analyse complète"), findsNothing);
      expect(find.text('Corrections'), findsNothing);
      expect(find.text('Suggestions'), findsNothing);
      expect(find.textContaining('Comme il fait beau'), findsNothing);
      expect(find.text('Relisez-vous à voix haute.'), findsNothing);
    });

    testWidgets('à l\'oral non plus : pas de reformulations', (tester) async {
      await tester.pumpWidget(_host(_eval(json), isOral: true));

      expect(find.text('Reformulations pour plus de clarté'), findsNothing);
      expect(find.text("Voir l'analyse complète"), findsNothing);
      expect(find.textContaining('Comme il fait beau'), findsNothing);
    });

    testWidgets('les avertissements du SERVEUR restent, en note sous le '
        'bandeau de résultat', (tester) async {
      await tester.pumpWidget(_host(_eval(json)));

      expect(find.text('À savoir sur cette évaluation'), findsOneWidget);
      expect(find.text('Production plus courte que demandé.'), findsOneWidget);

      // Sous le hero, au-dessus des deux bandeaux de synthese : la note se lit
      // au passage, elle ne dispute pas la premiere lecture au verdict.
      final heroBas = tester.getBottomLeft(find.byType(ProductionResultsHero)).dy;
      final noteY =
          tester.getTopLeft(find.text('À savoir sur cette évaluation')).dy;
      final bandeauY = tester.getTopLeft(find.text('Ce qui marche')).dy;
      expect(noteY, greaterThanOrEqualTo(heroBas));
      expect(noteY, lessThan(bandeauY));
    });

    testWidgets('aucun avertissement à l\'écrit : aucune note, aucun titre '
        'orphelin', (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 12,
        'feedback': <String, dynamic>{},
      })));

      expect(find.text('À savoir sur cette évaluation'), findsNothing);
    });

    testWidgets('la check-list de la consigne vit dans « Ce qui marche » : '
        'les points traités PUIS les oubliés', (tester) async {
      await tester.pumpWidget(_host(_eval(json)));

      // Repliee par defaut, comme le reste du bandeau.
      expect(find.text('Nouvelle annoncée'), findsNothing);
      expect(find.text('1/2 points traités'), findsOneWidget);

      await _openTile(tester, 'Ce qui marche');

      final traiteY = tester.getTopLeft(find.text('Nouvelle annoncée')).dy;
      final oubliesY = tester.getTopLeft(find.text('Points oubliés')).dy;
      final manqueY = tester.getTopLeft(find.text('Invitation absente')).dy;

      // Sans ce second groupe, le candidat lisait « 1/2 » sans jamais savoir
      // lequel manquait — or c'est celui-la qui lui coute des points.
      expect(traiteY, lessThan(oubliesY));
      expect(oubliesY, lessThan(manqueY));

      // Une piste ne coute rien : elle ne compte pas au denominateur, et elle
      // n'est plus rendue du tout.
      expect(find.text('Loyer non mentionné'), findsNothing);
      expect(find.textContaining("n'enlève aucun point"), findsNothing);
      // L'ancienne carte detaillee et ses intertitres ont disparu avec elle.
      expect(find.text('Ce que demandait la consigne'), findsNothing);
      expect(find.text('Manques obligatoires'), findsNothing);
      expect(find.text('Points traités'), findsNothing);
    });

    testWidgets('le détail par critère reste dans le profil, déplié à la '
        'demande', (tester) async {
      await tester.pumpWidget(_host(_eval(json)));

      expect(find.text('Votre profil en un coup d\'œil'), findsOneWidget);
      expect(find.text('Détail par critère'), findsNothing);
    });

    testWidgets('les points forts vivent dans « Ce qui marche », pas en prose',
        (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 12,
        'feedback': <String, dynamic>{
          'points_forts': ['Message clair', 'Temps du passé maîtrisés'],
        },
      })));

      // Deux phrases entieres en clair, c'etait cinq lignes de prose pour une
      // information que le bandeau donne en un chiffre.
      expect(find.text('2 points forts'), findsOneWidget);
      expect(find.text('Temps du passé maîtrisés'), findsNothing);

      await _openTile(tester, 'Ce qui marche');
      expect(find.text('Message clair'), findsOneWidget);
      expect(find.text('Temps du passé maîtrisés'), findsOneWidget);
    });
  });

  group('limite de l\'évaluation orale', () {
    testWidgets('affichée en note quand le correcteur n\'a rien averti',
        (tester) async {
      await tester.pumpWidget(_host(
        _eval(<String, dynamic>{
          'noteSurVingt': 7,
          'feedback': <String, dynamic>{},
        }),
        isOral: true,
      ));

      expect(find.text(kOralEvaluationLimitNotice), findsOneWidget);
    });

    testWidgets('les avertissements du correcteur priment sur le repli',
        (tester) async {
      await tester.pumpWidget(_host(
        _eval(<String, dynamic>{
          'noteSurVingt': 7,
          'feedback': <String, dynamic>{
            'avertissements': ['Plafond A2 appliqué.'],
          },
        }),
        isOral: true,
      ));

      expect(find.text('Plafond A2 appliqué.'), findsOneWidget);
      expect(find.text(kOralEvaluationLimitNotice), findsNothing);
    });

    testWidgets('jamais à l\'écrit : la voix n\'y est pour rien',
        (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 7,
        'feedback': <String, dynamic>{
          'suggestions': ['Relisez-vous.'],
        },
      })));

      expect(find.text(kOralEvaluationLimitNotice), findsNothing);
      expect(find.text('À savoir sur cette évaluation'), findsNothing);
    });
  });

  testWidgets('une priorité enseigne : technique et démonstration visibles',
      (tester) async {
    final eval = _eval(<String, dynamic>{
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
      },
    });

    await tester.pumpWidget(_host(eval));
    await _openTile(tester, 'À corriger en priorité');

    // La demonstration ne se replie JAMAIS : c'est le bloc le plus court et le
    // plus actionnable du rapport.
    expect(find.text('AVANT → APRÈS'), findsOneWidget);
    expect(find.text('Je cherche un travail. Je suis motivé.'), findsOneWidget);
    expect(
      find.text('Je cherche un travail parce que je suis motivé.'),
      findsOneWidget,
    );

    // La technique, elle, est bornee a deux lignes — et se lit en entier d'un
    // geste. Le pave de huit lignes etait le plus gros bloc du rapport.
    final comment = tester.widget<Text>(
      find.textContaining('Reliez-les avec un connecteur'),
    );
    expect(comment.maxLines, 2);
    expect(comment.overflow, TextOverflow.ellipsis);

    await tester.tap(find.text('Comment faire'));
    await tester.pumpAndSettle();

    final ouvert = tester.widget<Text>(
      find.textContaining('Reliez-les avec un connecteur'),
    );
    expect(ouvert.maxLines, isNull);
    expect(find.text('Réduire'), findsOneWidget);
  });

  testWidgets('une priorité déjà en base sous forme de chaîne reste lisible',
      (tester) async {
    final eval = _eval(<String, dynamic>{
      'noteSurVingt': 14,
      'feedback': <String, dynamic>{
        'points_a_ameliorer': ['Penser à inviter', 'Varier les connecteurs'],
      },
    });

    await tester.pumpWidget(_host(eval));

    // Le bandeau annonce le nombre ; le detail les numerote.
    expect(find.text('2 priorités'), findsOneWidget);
    await _openTile(tester, 'À corriger en priorité');
    expect(find.text('PRIORITÉ 1'), findsOneWidget);
    expect(find.text('PRIORITÉ 2'), findsOneWidget);
    expect(find.text('Penser à inviter'), findsOneWidget);
    expect(find.text('Varier les connecteurs'), findsOneWidget);
    // Ni technique repliable ni démonstration : rien à inventer sur l'ancien
    // format, et surtout pas de bloc vide ni de bouton mort.
    expect(find.text('Comment faire'), findsNothing);
    expect(find.text('AVANT → APRÈS'), findsNothing);
  });

  testWidgets('évaluation ancienne : ni objectif, ni niveau, et le critère se '
      'lit en bande — jamais en chiffres', (tester) async {
    final eval = _eval(<String, dynamic>{
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
    expect(find.textContaining('Objectif '), findsNothing);
    // Aucun niveau attribué (pas de confiance) : le panneau le dit au lieu de
    // se rabattre sur la note, qui n'existe plus sur une tâche.
    expect(
      find.text('Niveau indisponible pour cette production'),
      findsOneWidget,
    );
    expect(find.textContaining('/20', findRichText: true), findsNothing);

    expect(find.text('Vocabulaire'), findsOneWidget);
    // 13/20 vaut B2 au TCF : la bande le dit, un « 13/20 » scolaire suggérait
    // l'inverse. Plus aucun chiffre nulle part sur le rapport d'une tâche.
    expect(find.text('Niveau B2'), findsOneWidget);

    // Le libellé complet de la table locale reste atteignable au déplié.
    await _openCriterion(tester);
    expect(find.text('Richesse lexicale'), findsOneWidget);
  });

  testWidgets('chaque code de critère a son icône et son libellé',
      (tester) async {
    // Les 4 codes de la grille courante (cf. production-rubrics-v7.json) + les
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

  // Les évaluations antérieures au contrat v4 ne portent pas de `bande` : leur
  // note était relue avec des seuils scolaires (15 vert / 10 ambre / rouge)
  // hérités du gabarit d'origine. Sur l'échelle du TCF, 12/20 est un B2 — ces
  // seuils affichaient donc « moyen », voire « échec », le meilleur niveau de
  // l'examen. La note est désormais relue sur la table officielle, exactement
  // comme le serveur le fait pour les évaluations récentes.
  group('critère legacy (évaluation sans bande)', () {
    /// Rend un critère et renvoie ce qui se voit : la bande écrite, sa teinte,
    /// et le remplissage de la barre.
    Future<({String bande, Color color, double fill})> render(
      WidgetTester tester, {
      required double note,
      BandeCritere? bande,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CriterionRow(
              criterion: CriterionScore(
                code: 'lexique',
                noteSurVingt: note,
                commentaire: '',
                bande: bande,
              ),
            ),
          ),
        ),
      );

      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      // Libellé + bande, rien d'autre : plus aucune note chiffrée sur un
      // critère, quelle que soit l'ancienneté de l'évaluation.
      expect(texts, hasLength(2), reason: 'note $note');
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      return (
        bande: texts[1].data!,
        color: texts[1].style!.color!,
        fill: bar.value!,
      );
    }

    test('la bande d\'une note vient de la table du TCF, pas de seuils '
        'scolaires', () {
      expect(TcfNoteScale.bandeFor(0), BandeCritere.nonEvaluable);
      expect(TcfNoteScale.bandeFor(1), BandeCritere.fragile);
      expect(TcfNoteScale.bandeFor(2), BandeCritere.enCoursAcquisition);
      expect(TcfNoteScale.bandeFor(5), BandeCritere.enCoursAcquisition);
      expect(TcfNoteScale.bandeFor(6), BandeCritere.satisfaisant);
      expect(TcfNoteScale.bandeFor(9), BandeCritere.satisfaisant);
      // Les notes que l'ancien seuil classait autrement : 12 et 14 tombaient
      // en ambre, 9 en rouge. Toutes valent leur palier TCF, rien d'autre.
      expect(TcfNoteScale.bandeFor(12), BandeCritere.tresBonneMaitrise);
      expect(TcfNoteScale.bandeFor(14), BandeCritere.tresBonneMaitrise);
      expect(TcfNoteScale.bandeFor(15), BandeCritere.tresBonneMaitrise);
      expect(TcfNoteScale.bandeFor(20), BandeCritere.tresBonneMaitrise);
      // Rien à deviner quand la note n'est pas un nombre exploitable.
      expect(TcfNoteScale.bandeFor(double.nan), BandeCritere.nonEvaluable);
    });

    testWidgets('12, 14 et 15 : même bande TCF et même rendu que le critère '
        'moderne équivalent', (tester) async {
      for (final note in [12.0, 14.0, 15.0]) {
        final legacy = await render(tester, note: note);
        final moderne = await render(
          tester,
          note: note,
          bande: BandeCritere.tresBonneMaitrise,
        );

        expect(legacy, moderne, reason: 'note $note');
        expect(legacy.bande, 'Niveau B2', reason: 'note $note');
        expect(legacy.color, AppColors.green, reason: 'note $note');
      }
    });

    testWidgets('un 9/20 n\'est plus un échec : c\'est le haut du B1',
        (tester) async {
      final neuf = await render(tester, note: 9);

      expect(neuf.bande, 'Niveau B1');
      expect(neuf.color, AppColors.blue);
    });

    testWidgets('balayage 0 → 20 : aucune note ne peint un critère en rouge, '
        'et chacune rend ce que rendrait le serveur', (tester) async {
      for (var demis = 0; demis <= 40; demis++) {
        final note = demis / 2;
        final legacy = await render(tester, note: note);
        final moderne = await render(
          tester,
          note: note,
          bande: TcfNoteScale.bandeFor(note),
        );

        expect(legacy, moderne, reason: 'note $note');
        // Seul le plancher (note < 2, sous le A1) reste rouge : c'est le
        // dernier cran de la barre, pas un niveau CECRL peint en échec.
        if (note >= 2) {
          expect(legacy.color, isNot(AppColors.red), reason: 'note $note');
        }
      }
    });

    testWidgets('le plancher se rend comme le serveur le rendrait',
        (tester) async {
      // 0 = hors-sujet, pas un niveau faible : gris, jamais rouge.
      final zero = await render(tester, note: 0);
      expect(zero.bande, 'Non évaluable');
      expect(zero.color, AppColors.muted2);
      expect(zero.fill, 0);

      final un = await render(tester, note: 1);
      expect(un.bande, 'Niveau A1');
      expect(
        un,
        await render(tester, note: 1, bande: BandeCritere.fragile),
      );
    });
  });

  // Ces chaines ne transitent PAS par le reseau : le mobile et le web en
  // tiennent chacun une copie ecrite a la main. Rien n'empeche une couche de
  // deriver — d'ou ce gel, miroir de `lib/production-feedback.test.ts` cote
  // web. Un libelle qui bouge, ce sont deux fichiers et deux tests dans la
  // meme passe.
  group('libellés gelés — bandes de critère (miroir web `bandeCritereLabel`)',
      () {
    test('nomme le palier atteint, jamais un déficit', () {
      expect(BandeCritere.tresBonneMaitrise.displayName, 'Niveau B2');
      expect(BandeCritere.satisfaisant.displayName, 'Niveau B1');
      expect(BandeCritere.enCoursAcquisition.displayName, 'Niveau A2');
      expect(BandeCritere.fragile.displayName, 'Niveau A1');
      expect(BandeCritere.nonEvaluable.displayName, 'Non évaluable');
    });

    test('plus aucun vocabulaire d\'échec sur un palier normal', () {
      // Les bornes des bandes (10 / 6 / 2) sont celles des paliers du TCF :
      // « En cours d'acquisition » couvrait TOUTE la bande A2, donc un
      // candidat A2 ne pouvait voir que ca, quoi qu'il produise.
      for (final b in BandeCritere.values) {
        expect(b.displayName.contains('acquisition'), isFalse, reason: b.name);
        expect(b.displayName.contains('Fragile'), isFalse, reason: b.name);
      }
    });
  });

  group('le niveau d\'UNE tâche remplace sa note partout', () {
    test('nomme le palier comme une bande de critère, au caractère près', () {
      // Un badge doit se lire pareil d'un écran à l'autre : la bande d'un
      // critère et le résultat d'une tâche disent le même palier.
      expect(tacheNiveauLabel(NiveauCecrl.b2), 'Niveau B2');
      expect(tacheNiveauLabel(NiveauCecrl.b1), 'Niveau B1');
      expect(tacheNiveauLabel(NiveauCecrl.a2), 'Niveau A2');
      expect(tacheNiveauLabel(NiveauCecrl.a1), 'Niveau A1');
      expect(BandeCritere.tresBonneMaitrise.displayName,
          tacheNiveauLabel(NiveauCecrl.b2));
      expect(BandeCritere.satisfaisant.displayName,
          tacheNiveauLabel(NiveauCecrl.b1));
      expect(BandeCritere.enCoursAcquisition.displayName,
          tacheNiveauLabel(NiveauCecrl.a2));
      expect(BandeCritere.fragile.displayName,
          tacheNiveauLabel(NiveauCecrl.a1));
    });

    test('ne dit jamais « Niveau A1 non atteint », qui se contredit tout seul',
        () {
      expect(tacheNiveauLabel(NiveauCecrl.a1NonAtteint), 'A1 non atteint');
    });

    test('n\'affiche AUCUN chiffre : une tâche isolée n\'a pas de note au TCF',
        () {
      for (final n in kTcfPaliers) {
        final label = tacheNiveauLabel(n);
        expect(label.contains('/20'), isFalse, reason: n.name);
        expect(label.contains('20'), isFalse, reason: n.name);
      }
    });

    test('garde le niveau muet tant que la confiance manque', () {
      // Miroir du garde-fou serveur : pas de niveau sans confiance.
      expect(tacheNiveau(null), isNull);
      expect(
        tacheNiveau(EvaluationResult.fromJson(const {
          'noteSurVingt': 12,
          'niveauObserve': 'B1',
          'feedback': <String, dynamic>{},
        })),
        isNull,
      );
      expect(
        tacheNiveau(EvaluationResult.fromJson(const {
          'noteSurVingt': 12,
          'confiance': 'HAUTE',
          'feedback': <String, dynamic>{},
        })),
        isNull,
      );
    });

    test('rend le niveau d\'une évaluation complète', () {
      expect(
        tacheNiveau(EvaluationResult.fromJson(const {
          'noteSurVingt': 4.5,
          'niveauObserve': 'A2',
          'confiance': 'MOYENNE',
          'feedback': <String, dynamic>{},
        })),
        NiveauCecrl.a2,
      );
    });
  });

  group('rappel d\'enjeu (niveau atteint ⇄ démarche visée)', () {
    test('dit clairement qu\'un A2 qui vise la carte de séjour est au niveau '
        'demandé', () {
      final r = demarcheRappel(TargetLevel.a2, NiveauCecrl.a2)!;
      expect(r.atteint, isTrue);
      expect(
        r.text,
        'Le niveau A2 est celui demandé pour la carte de séjour '
        "pluriannuelle. Cette production l'atteint.",
      );
    });

    test('nomme la bonne démarche pour chaque palier (seuils du 1er janvier '
        '2026)', () {
      expect(
        demarcheRappel(TargetLevel.a2, NiveauCecrl.b2)!.text,
        contains('la carte de séjour pluriannuelle'),
      );
      expect(
        demarcheRappel(TargetLevel.b1, NiveauCecrl.b2)!.text,
        contains('la carte de résident'),
      );
      expect(
        demarcheRappel(TargetLevel.b2, NiveauCecrl.b2)!.text,
        contains('la naturalisation'),
      );
    });

    test('compte un niveau au-dessus de l\'objectif comme atteint', () {
      expect(demarcheRappel(TargetLevel.a2, NiveauCecrl.b1)!.atteint, isTrue);
      expect(demarcheRappel(TargetLevel.a2, NiveauCecrl.b2)!.atteint, isTrue);
      expect(demarcheRappel(TargetLevel.b1, NiveauCecrl.b2)!.atteint, isTrue);
      expect(demarcheRappel(TargetLevel.b2, NiveauCecrl.c1)!.atteint, isTrue);
    });

    test('dit l\'objectif encore devant sans dramatiser', () {
      final r = demarcheRappel(TargetLevel.b1, NiveauCecrl.a2)!;
      expect(r.atteint, isFalse);
      expect(
        r.text,
        'Le niveau B1 est celui demandé pour la carte de résident. Cette '
        'production est au niveau A2 : continuez à vous entraîner.',
      );
    });

    test('reformule le plancher au lieu d\'écrire « au niveau A1 non '
        'atteint »', () {
      final r = demarcheRappel(TargetLevel.a2, NiveauCecrl.a1NonAtteint)!;
      expect(r.atteint, isFalse);
      expect(r.text, contains("n'atteint pas encore le niveau A1"));
    });

    test('n\'affiche RIEN quand la démarche ou le niveau est inconnu', () {
      // Un message generique parlerait d'une demarche que le candidat n'a pas
      // choisie : mieux vaut se taire.
      expect(demarcheRappel(null, NiveauCecrl.a2), isNull);
      expect(demarcheRappel(TargetLevel.b1, null), isNull);
      expect(demarcheRappel(null, null), isNull);
    });

    test('n\'affiche aucune borne chiffrée de barème', () {
      for (final cible in TargetLevel.values) {
        for (final obtenu in kTcfPaliers) {
          final texte = demarcheRappel(cible, obtenu)!
              .text
              .replaceAll(RegExp('A1|A2|B1|B2'), '');
          expect(RegExp(r'\d').hasMatch(texte), isFalse, reason: texte);
        }
      }
    });

    testWidgets('le hero l\'affiche quand le parcours est connu, et se tait '
        'sinon', (tester) async {
      final json = <String, dynamic>{
        'noteSurVingt': 3.5,
        'niveauObserve': 'A2',
        'confiance': 'HAUTE',
        'feedback': <String, dynamic>{},
      };

      await tester
          .pumpWidget(_host(_eval(json), targetLevel: TargetLevel.a2));
      expect(find.text('VOTRE DÉMARCHE'), findsOneWidget);
      expect(
        find.textContaining('la carte de séjour pluriannuelle'),
        findsOneWidget,
      );

      await tester.pumpWidget(_host(_eval(json)));
      expect(find.text('VOTRE DÉMARCHE'), findsNothing);
    });
  });

  // Ces chaines ne transitent PAS par le reseau (le serveur n'envoie que la
  // forme composee) : chaque front en tient une copie, donc elles sont gelees
  // des deux cotes — miroir de `lib/production-feedback.test.ts`.
  group('situation dans le palier — ce qui remplace la note d\'une tâche', () {
    Map<String, dynamic> json({
      String? cran,
      String? label,
      String? niveau = 'A2',
      String? confiance = 'HAUTE',
    }) =>
        <String, dynamic>{
          'noteSurVingt': 4.5,
          'niveauObserve': niveau,
          'confiance': confiance,
          'situationDansNiveau': cran,
          'situationDansNiveauLabel': label,
          'feedback': <String, dynamic>{},
        };

    test('gèle les trois libellés autonomes, miroir du serveur', () {
      expect(situationLibelle(SituationDansNiveau.entreeDePalier),
          'Palier atteint');
      expect(situationLibelle(SituationDansNiveau.palierConfirme),
          'Palier confirmé');
      expect(
          situationLibelle(SituationDansNiveau.palierSolide), 'Palier solide');
    });

    test('gèle les trois qualificatifs — « A2 solide » se compose avec eux',
        () {
      expect(situationQualificatif(SituationDansNiveau.entreeDePalier),
          'atteint');
      expect(situationQualificatif(SituationDansNiveau.palierConfirme),
          'confirmé');
      expect(
          situationQualificatif(SituationDansNiveau.palierSolide), 'solide');
    });

    test('ne nomme JAMAIS un manque : ni « presque », ni chiffre', () {
      // C'est la contrepartie de la note masquee. Reintroduire « presque B1 »
      // remettrait exactement le vocabulaire de deficit qu'on vient de retirer.
      final interdits = RegExp('presque|pas encore|manqu|faible|insuffis',
          caseSensitive: false);
      for (final cran in SituationDansNiveau.values) {
        for (final texte in [
          situationLibelle(cran),
          situationQualificatif(cran)
        ]) {
          expect(interdits.hasMatch(texte), isFalse, reason: texte);
          expect(RegExp(r'\d').hasMatch(texte), isFalse, reason: texte);
        }
      }
    });

    test('préfère le libellé composé du serveur, recompose sinon', () {
      final avec = situationView(
          _eval(json(cran: 'PALIER_SOLIDE', label: 'A2 solide')))!;
      expect(avec.cran, SituationDansNiveau.palierSolide);
      expect(avec.libelle, 'Palier solide');
      expect(avec.libelleAvecNiveau, 'A2 solide');

      final sans = situationView(_eval(json(cran: 'PALIER_CONFIRME')))!;
      expect(sans.libelleAvecNiveau, 'A2 confirmé');
    });

    test('ne situe rien sans niveau affichable', () {
      // Une position dans une bande qu'on ne nomme pas ne veut rien dire.
      expect(
        situationView(_eval(
            json(cran: 'PALIER_SOLIDE', label: 'A2 solide', niveau: null))),
        isNull,
      );
      expect(
        situationView(_eval(
            json(cran: 'PALIER_SOLIDE', label: 'A2 solide', confiance: null))),
        isNull,
      );
    });

    test('ne rend rien sans cran (legacy, <A1, C1/C2)', () {
      expect(situationView(_eval(json())), isNull);
      expect(situationView(null), isNull);
    });

    testWidgets('le hero affiche la pastille, et rien quand le cran manque',
        (tester) async {
      await tester.pumpWidget(
          _host(_eval(json(cran: 'PALIER_SOLIDE', label: 'A2 solide'))));
      // La forme composee, celle qu'annonce docs/notation-ia-eo-ee.md §6.3 bis.
      expect(find.text('A2 solide'), findsOneWidget);
      // La note reste invisible : la pastille la remplace, elle ne la ramene
      // pas par la bande.
      expect(find.textContaining('/20', findRichText: true), findsNothing);

      await tester.pumpWidget(_host(_eval(json())));
      expect(find.text('A2 solide'), findsNothing);
    });
  });

  group('libellés gelés — sujet rendu sans niveau (miroir web)', () {
    test('dit « Traité » des deux côtés — le mobile disait « Fait »', () {
      expect(kTacheTraiteeLabel, 'Traité');
      expect(kTacheEvalueeLabel, 'Évaluée');
    });

    test('n\'affiche aucun chiffre : c\'est l\'absence de niveau qu\'on nomme',
        () {
      for (final label in [kTacheTraiteeLabel, kTacheEvalueeLabel]) {
        expect(RegExp(r'\d').hasMatch(label), isFalse, reason: label);
      }
    });
  });

  group('plan d\'action — « pour viser X », version plus aboutie, à retenir',
      () {
    Map<String, dynamic> json(Map<String, dynamic>? bloc) => <String, dynamic>{
          'noteSurVingt': 7,
          'niveauObserve': 'B1',
          'confiance': 'HAUTE',
          'feedback': <String, dynamic>{
            if (bloc != null) 'version_ciblee': bloc,
          },
        };

    // Contrat v1 : une centaine d'evaluations en base le portent encore.
    final legacy = <String, dynamic>{
      'niveau_vise': 'B2',
      'niveau_constate': 'B1',
      'texte': 'Madame, Monsieur, je me permets de vous écrire…',
      'ce_qui_manque': [
        'Articuler deux arguments',
        'Varier les temps',
        'Nuancer',
      ],
    };

    // Contrat v2, ORAL : aucune reecriture complete de la production.
    final oral = <String, dynamic>{
      'niveau_vise': 'B2',
      'niveau_constate': 'B1',
      'leviers': [
        {'action': 'Nuance ta position', 'exemple': 'à condition que'},
        {'action': 'Annonce ton objection', 'exemple': 'on pourrait objecter'},
      ],
      'reformulations': [
        {
          'original': 'moi je pense que c\'est bien',
          'reformule': 'Je considère que cette mesure est bénéfique',
          'apport': 'plus nuancé',
        },
        {
          'original': 'et après on fait ça',
          'reformule': 'Ensuite, il conviendrait de procéder ainsi',
          'apport': 'lien logique',
        },
      ],
      'a_retenir': {
        'formule': 'On objectera que…, mais…',
        'explication': 'Pour traiter une objection avant de conclure.',
      },
    };

    test('lit le bloc v1 et PRÉSERVE l\'ordre des leviers', () {
      final v = _eval(json(legacy)).feedback.versionCiblee!;
      expect(v.niveauVise, TargetLevel.b2);
      expect(v.niveauConstate, NiveauCecrl.b1);
      expect(v.texte, startsWith('Madame, Monsieur'));
      expect(v.ceQuiManque, [
        'Articuler deux arguments',
        'Varier les temps',
        'Nuancer',
      ]);
    });

    test('lit le bloc v2 oral : des reformulations, jamais un texte modèle', () {
      final v = _eval(json(oral)).feedback.versionCiblee!;
      expect(v.texte, isNull);
      expect(v.exempleCible, isNull);
      expect(v.leviers.map((l) => l.action),
          ['Nuance ta position', 'Annonce ton objection']);
      expect(v.reformulations.first.original, 'moi je pense que c\'est bien');
      expect(v.aRetenir?.formule, 'On objectera que…, mais…');
    });

    test('reste null quand le bloc est absent ou inexploitable', () {
      // Sans palier vise, on ne saurait pas au nom de quoi ce plan est
      // montre ; sans la moindre section, il n'y a rien a montrer.
      expect(_eval(json(null)).feedback.versionCiblee, isNull);
      for (final bloc in <Map<String, dynamic>>[
        {'texte': 'Un modèle.'},
        {'niveau_vise': 'B2'},
        {'niveau_vise': 'C1', 'texte': 'Un modèle.'},
        {'niveau_vise': 'B2', 'texte': '   '},
      ]) {
        expect(_eval(json(bloc)).feedback.versionCiblee, isNull,
            reason: bloc.toString());
      }
    });

    testWidgets('v1 : l\'objectif est nommé, le texte ne l\'est plus',
        (tester) async {
      await tester.pumpWidget(_host(_eval(json(legacy))));
      await tester.pumpAndSettle();

      expect(find.text('Pour viser B2'), findsOneWidget);
      expect(find.text(kActionPlanExempleTitle), findsOneWidget);
      expect(find.text('Articuler deux arguments'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      // Plus aucune etiquette de palier sur le texte lui-meme.
      expect(find.textContaining('pourrait ressembler'), findsNothing);
      expect(find.textContaining("Ce texte n'est pas le vôtre"), findsNothing);
    });

    testWidgets('l\'oral reçoit le plan, au pluriel et sans texte complet',
        (tester) async {
      await tester.pumpWidget(_host(_eval(json(oral)), isOral: true));
      await tester.pumpAndSettle();

      expect(find.text('Pour viser B2'), findsOneWidget);
      expect(find.text(kActionPlanReformulationsTitle), findsOneWidget);
      expect(find.text(kActionPlanExempleTitle), findsNothing);
      expect(find.text('Je considère que cette mesure est bénéfique'),
          findsOneWidget);
      expect(find.text('À retenir'), findsOneWidget);
    });

    testWidgets('rien du tout quand le bloc est absent (toutes les évals '
        'existantes)', (tester) async {
      await tester.pumpWidget(_host(_eval(json(null))));
      await tester.pumpAndSettle();

      expect(find.text('Pour viser B2'), findsNothing);
      expect(find.text(kActionPlanExempleTitle), findsNothing);
      expect(find.text(kActionPlanReformulationsTitle), findsNothing);
    });

    // Le cas le plus frequent depuis le retrait de `version_amelioree` : une
    // eval EE anterieure, ou dont le second appel a echoue. L'ecran n'a alors
    // AUCUN plan — il doit rester equilibre, sans section vide ni titre
    // orphelin, et sans « non disponible ».
    testWidgets('aucun plan : le rapport reste entier, sans trou',
        (tester) async {
      await tester.pumpWidget(_host(
        _eval(<String, dynamic>{
          'noteSurVingt': 7,
          'niveauObserve': 'B1',
          'confiance': 'HAUTE',
          'feedback': <String, dynamic>{
            // Servie par l'API, jamais rendue.
            'version_amelioree': 'Bonjour Marie, je viens de trouver un '
                'appartement.',
            'points_forts': ['Le ton reste courtois.'],
          },
        }),
        productionText: 'Bonjour Marie, j\'ai trouvé un appartement.',
      ));
      await tester.pumpAndSettle();

      // Le rapport tient debout : hero, synthese, redaction.
      expect(find.text('NIVEAU ESTIMÉ'), findsOneWidget);
      expect(find.text('Ce qui marche'), findsOneWidget);
      expect(find.text('Votre rédaction'), findsOneWidget);
      expect(
        find.text('Bonjour Marie, j\'ai trouvé un appartement.'),
        findsOneWidget,
      );

      // Et pas un seul modele, ni cadre, ni titre, ni excuse.
      expect(find.textContaining('je viens de trouver'), findsNothing);
      expect(find.text(kActionPlanExempleTitle), findsNothing);
      expect(find.textContaining('Pour viser'), findsNothing);
      expect(find.textContaining('non disponible'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------

  group('niveau visé déjà atteint — la victoire, dite', () {
    Map<String, dynamic> json(Map<String, dynamic>? bloc) => <String, dynamic>{
          'noteSurVingt': 14,
          'niveauObserve': 'B2',
          'confiance': 'HAUTE',
          'feedback': <String, dynamic>{
            if (bloc != null) 'niveau_vise_atteint': bloc,
          },
        };

    final atteint = <String, dynamic>{
      'niveau_vise': 'B2',
      'niveau_constate': 'B2',
    };

    test(
        'annonce le palier visé, distinct du bandeau « Objectif atteint » de la consigne',
        () {
      expect(kNiveauViseAtteintEyebrow, 'Palier visé');
      expect(niveauViseAtteintTitle(TargetLevel.b2), 'Objectif B2 : vous y êtes');
      expect(niveauViseAtteintTitle(TargetLevel.a2), 'Objectif A2 : vous y êtes');
    });

    test('explique l\'absence de texte modèle, sans chiffre ni manque', () {
      expect(kNiveauViseAtteintIntro,
          contains("pas de version d'un niveau supérieur"));
      for (final interdit in const [
        '/20',
        'note',
        'manque',
        'insuffis',
        'échec',
        'faible',
      ]) {
        expect(kNiveauViseAtteintIntro.toLowerCase().contains(interdit), isFalse,
            reason: '« $interdit » n\'a rien à faire dans un message de réussite');
      }
    });

    test('ne recopie pas le rappel d\'enjeu du hero', () {
      final rappel = demarcheRappel(TargetLevel.b2, NiveauCecrl.b2)!;
      expect(rappel.atteint, isTrue);
      expect(kNiveauViseAtteintIntro, isNot(rappel.text));
      expect(kNiveauViseAtteintIntro.contains('est celui demandé pour'), isFalse);
      expect(niveauViseAtteintTitle(TargetLevel.b2),
          isNot(niveauAtteintLabel(NiveauCecrl.b2)));
    });

    test('lit le signal serveur, et rien sans palier visé', () {
      final a = _eval(json(atteint)).feedback.niveauViseAtteint!;
      expect(a.niveauVise, TargetLevel.b2);
      expect(a.niveauConstate, NiveauCecrl.b2);
      expect(_eval(json(null)).feedback.niveauViseAtteint, isNull);
      expect(
        _eval(json(<String, dynamic>{'niveau_constate': 'B2'}))
            .feedback
            .niveauViseAtteint,
        isNull,
      );
    });

    testWidgets('la section se rend en EE : plus de trou après une réussite',
        (tester) async {
      await tester.pumpWidget(_host(_eval(json(atteint))));
      await tester.pumpAndSettle();

      expect(find.text('Objectif B2 : vous y êtes'), findsOneWidget);
      expect(find.text(kNiveauViseAtteintEyebrow.toUpperCase()), findsOneWidget);
      expect(find.text(kNiveauViseAtteintIntro), findsOneWidget);
    });

    // Le signal est servi a l'oral aussi depuis le contrat v2 : une reussite
    // orale se dit exactement comme une reussite ecrite.
    testWidgets('se rend aussi à l\'oral', (tester) async {
      await tester.pumpWidget(_host(_eval(json(atteint)), isOral: true));
      await tester.pumpAndSettle();

      expect(find.text(kNiveauViseAtteintEyebrow.toUpperCase()), findsOneWidget);
      expect(find.text('Objectif B2 : vous y êtes'), findsOneWidget);
    });

    testWidgets('rien du tout sur une évaluation qui ne porte pas le bloc',
        (tester) async {
      await tester.pumpWidget(_host(_eval(json(null))));
      await tester.pumpAndSettle();

      expect(find.text(kNiveauViseAtteintEyebrow.toUpperCase()), findsNothing);
    });
  });

  // Le conseil de fin de bilan vivait EN DOUBLE, écrit à la main de chaque
  // côté, et les deux copies avaient divergé : ici on tutoyait (« Continue »,
  // « garde »), le web vouvoyait. Pire : chacune recopiait la table démarche →
  // palier, donnée LÉGALE que `TargetProcedure` interdit de réécrire dans un
  // écran. Miroir web : `lib/production-feedback.test.ts`, sur exactement les
  // mêmes chaînes.
  group('conseil « prochaines étapes » du bilan d\'épreuve', () {
    const niveaux = <NiveauCecrl?>[
      NiveauCecrl.a1NonAtteint,
      NiveauCecrl.a1,
      NiveauCecrl.a2,
      NiveauCecrl.b1,
      NiveauCecrl.b2,
      NiveauCecrl.c1,
      NiveauCecrl.c2,
      null,
    ];

    test('le titre vouvoie, comme tout le reste de la restitution', () {
      expect(kBilanProchainesEtapesTitle, 'Vos prochaines étapes');
    });

    test('chaque palier nomme la démarche qu\'il ouvre, et elle seule', () {
      expect(bilanProchainesEtapesMessage(NiveauCecrl.a2),
          contains('la carte de séjour pluriannuelle'));
      expect(bilanProchainesEtapesMessage(NiveauCecrl.b1),
          contains('la carte de résident'));
      expect(bilanProchainesEtapesMessage(NiveauCecrl.b2),
          contains('la naturalisation'));
      // Un A2 ne doit pas se voir promettre la naturalisation dans la même
      // phrase que son palier : il vise le B1, une marche à la fois.
      expect(bilanProchainesEtapesMessage(NiveauCecrl.a2),
          isNot(contains('naturalisation')));
    });

    test('aucun message ne tutoie', () {
      // ⚠️ Une frontière ASCII coupe avant le « t » de « êtes » : on borne sur
      // les lettres Unicode, sinon le test crie au tutoiement pour rien.
      final tutoiement = RegExp(
        r'(?<!\p{L})(tu|ton|ta|tes|toi|continue|vise|garde|reviens)(?!\p{L})',
        caseSensitive: false,
        unicode: true,
      );
      for (final n in niveaux) {
        final m = bilanProchainesEtapesMessage(n);
        expect(tutoiement.hasMatch(m), isFalse, reason: m);
      }
    });

    test('aucun message n\'affiche un chiffre de barème', () {
      for (final n in niveaux) {
        final m = bilanProchainesEtapesMessage(n);
        expect(m, isNot(contains('/20')));
        expect(m, isNot(contains('sur 20')));
      }
    });

    test('sans niveau, il dit que l\'IA n\'a pas fini — jamais rien', () {
      final m = bilanProchainesEtapesMessage(null);
      expect(m, isNotEmpty);
      expect(m, contains('évalué vos 3 tâches'));
    });

    test('au-dessus du plafond du TCF IRN, il le dit sans reproche', () {
      expect(bilanProchainesEtapesMessage(NiveauCecrl.c1),
          bilanProchainesEtapesMessage(NiveauCecrl.c2));
      expect(bilanProchainesEtapesMessage(NiveauCecrl.c1),
          contains("s'arrête au B2"));
    });
  });
}
