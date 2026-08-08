import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/core/models/production_models.dart';
import 'package:sejourfr_mobile/core/theme/app_theme.dart';
import 'package:sejourfr_mobile/core/widgets/app_tag.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/criterion_row.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/evaluation_report.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/results_hero.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/tcf_note_scale.dart';

Widget _host(
  EvaluationResult eval, {
  bool isOral = false,
  String? productionText,
  String? eyebrow,
}) =>
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EvaluationReport(
            evaluation: eval,
            isOral: isOral,
            eyebrow: eyebrow,
            productionText: productionText,
          ),
        ),
      ),
    );

EvaluationResult _eval(Map<String, dynamic> json) =>
    EvaluationResult.fromJson(json);

/// L'échelle en version CLAIRE, hors hero : c'est là que vivent le curseur et
/// les bornes chiffrées. Le hero, lui, la rend sur fond sombre.
Widget _scaleHost(double note) => MaterialApp(
      home: Scaffold(body: TcfNoteScale(note: note)),
    );

/// Deplie « Voir l'analyse complete » : le detail exhaustif y vit, replie par
/// defaut.
Future<void> _openFullAnalysis(WidgetTester tester) async {
  final header = find.text("Voir l'analyse complète");
  await tester.ensureVisible(header);
  await tester.tap(header);
  await tester.pumpAndSettle();
}

/// Ouvre la regle de lecture de la note : elle vit derriere un geste, pas a
/// plat entre la note et le premier conseil.
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

  group('hero : verdict, note et niveau dans un seul bloc', () {
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

    testWidgets('le verdict, le resume et la note vivent dans le meme hero, '
        'en tete du rapport', (tester) async {
      await tester.pumpWidget(_host(
        _eval(withObjectif('ATTEINT')),
        eyebrow: 'Expression écrite · Tâche 1',
      ));

      expect(find.text('EXPRESSION ÉCRITE · TÂCHE 1'), findsOneWidget);
      expect(find.text('Objectif atteint'), findsOneWidget);
      expect(find.textContaining("vous n'invitez personne"), findsOneWidget);
      expect(find.text('4,5/20', findRichText: true), findsOneWidget);

      // Un seul bloc : le verdict et la note sont dans le meme widget, et ce
      // widget ouvre le rapport.
      final hero = find.byType(ProductionResultsHero);
      expect(hero, findsOneWidget);
      expect(
        find.descendant(of: hero, matching: find.text('Objectif atteint')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: hero,
          matching: find.text('4,5/20', findRichText: true),
        ),
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

    testWidgets('évaluation legacy sans objectif : titre neutre, note intacte',
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
      // Le hero reste coherent : titre neutre, note et echelle a leur place.
      expect(find.text('Votre correction'), findsOneWidget);
      expect(find.text('4,5/20', findRichText: true), findsOneWidget);
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
    ));

    expect(tester.takeException(), isNull);
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

  group('note et échelle du TCF', () {
    testWidgets('la note et le niveau vivent dans le MÊME bloc, avec la règle '
        'de lecture', (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 4.5,
        'niveauObserve': 'A2',
        'confiance': 'HAUTE',
        'feedback': <String, dynamic>{},
      })));

      expect(find.text('4,5/20', findRichText: true), findsOneWidget);
      expect(find.text('NIVEAU ESTIMÉ'), findsOneWidget);
      // Notre niveau est une estimation : on ne l'affirme pas sec.
      expect(find.text('Proche du niveau A2'), findsOneWidget);
      // Les 5 paliers du TCF, en une seule ligne de libellés sous la barre :
      // le palier atteint se lit sans déplier, ses bornes chiffrées non.
      expect(find.text('<A1'), findsOneWidget);
      expect(find.text('A2'), findsWidgets);
      expect(find.text('2-5'), findsNothing);
      expect(find.text('10-20'), findsNothing);

      // Les bornes vivent dans la règle de lecture, avec la table complète.
      await _openReadingRule(tester);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('2-5'), findsOneWidget);
      expect(find.text('6-9'), findsOneWidget);
      expect(find.text('10-20'), findsOneWidget);
      expect(find.text('A1 non atteint'), findsOneWidget);
    });

    test('chaque palier de la table officielle reçoit sa note', () {
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

    testWidgets('une note qui n\'est pas un nombre garde la règle de lecture, '
        'sans curseur', (tester) async {
      await tester.pumpWidget(_scaleHost(double.nan));

      expect(find.byKey(TcfNoteScale.cursorKey), findsNothing);
      // Les cinq paliers restent affiches : la regle vaut toujours.
      expect(find.text('10-20'), findsOneWidget);
      expect(find.text('A1 non atteint'), findsOneWidget);
    });

    testWidgets('le curseur avance avec la note, palier après palier',
        (tester) async {
      final positions = <double>[];
      for (final note in [0.0, 1.0, 4.5, 7.0, 15.0]) {
        await tester.pumpWidget(_scaleHost(note));
        positions
            .add(tester.getTopLeft(find.byKey(TcfNoteScale.cursorKey)).dx);
      }

      for (var i = 1; i < positions.length; i++) {
        expect(
          positions[i],
          greaterThan(positions[i - 1]),
          reason: 'curseur non monotone entre les paliers',
        );
      }
    });

    testWidgets('le plancher ne se dit pas « proche de » : on n\'est pas '
        'proche d\'un niveau non atteint', (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 0,
        'niveauObserve': 'A1_NON_ATTEINT',
        'confiance': 'MOYENNE',
        'feedback': <String, dynamic>{},
      })));

      expect(find.text('Niveau A1 non atteint'), findsOneWidget);
      expect(find.textContaining('Proche du niveau'), findsNothing);
    });

    test('les paliers à valeur unique centrent le curseur dans leur case', () {
      // 0 et 1 ne valent qu'une note : sans centrage, le curseur se colle au
      // bord gauche et se lit dans le palier d'en dessous.
      expect(TcfNoteScale.positionInBand(0, 0), 0.5);
      expect(TcfNoteScale.positionInBand(1, 1), 0.5);
      // Les paliers à étendue gardent une position proportionnelle, insérée de
      // 10 % de chaque côté (mêmes chiffres que le web).
      expect(TcfNoteScale.positionInBand(2, 2), closeTo(0.1, 1e-9));
      expect(TcfNoteScale.positionInBand(5, 2), closeTo(0.7, 1e-9));
      expect(TcfNoteScale.positionInBand(6, 3), closeTo(0.1, 1e-9));
      // Dernier palier : dénominateur `max + 1` = 21, jamais 20 — un 20/20 ne
      // doit pas se coller à la bordure droite de la barre.
      expect(TcfNoteScale.positionInBand(20, 4),
          closeTo(0.1 + 10 / 11 * 0.8, 1e-9));
      expect(TcfNoteScale.positionInBand(20, 4), lessThan(0.9));
    });

    testWidgets('curseur centré : un 0/20 tombe au milieu de sa case, pas au '
        'bord', (tester) async {
      await tester.pumpWidget(_scaleHost(0));

      final cursor = tester.getRect(find.byKey(TcfNoteScale.cursorKey));
      final scale = tester.getRect(find.byType(TcfNoteScale));
      const gap = 4.0;
      final segment = (scale.width - gap * (kTcfNoteBands.length - 1)) /
          kTcfNoteBands.length;

      expect(cursor.center.dx - scale.left, closeTo(segment / 2, 0.5));
    });

    testWidgets('une production non notée garde la règle de lecture, sans '
        'curseur', (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'feedback': <String, dynamic>{},
      })));

      expect(find.text('—/20', findRichText: true), findsOneWidget);
      // Le hero rend l'échelle, sans palier actif ni curseur.
      expect(find.byType(TcfNoteScale), findsOneWidget);
      expect(find.byKey(TcfNoteScale.cursorKey), findsNothing);
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

      // Ni l'en-tête de la pastille, ni son libellé. Les paliers de l'échelle
      // citent bien « B1 », mais ils disent comment lire la note — ils
      // n'attribuent aucun niveau au candidat.
      expect(find.text('NIVEAU ESTIMÉ'), findsNothing);
      expect(find.text('NOTE SUR L\'ÉCHELLE DU TCF'), findsOneWidget);
      expect(find.text('Confiance moyenne'), findsNothing);
      expect(find.text('12/20', findRichText: true), findsOneWidget);
    });
  });

  group('portée de la note', () {
    testWidgets('la règle de lecture se consulte, elle ne s\'impose pas entre '
        'la note et le premier conseil', (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 7,
        'feedback': <String, dynamic>{},
      })));

      expect(find.text(kNotePorteeSurLaTache), findsNothing);
      await _openReadingRule(tester, via: 'NOTE SUR L\'ÉCHELLE DU TCF');
      expect(find.text(kNotePorteeSurLaTache), findsOneWidget);
    });

    testWidgets('avec avertissement du backend : il REMPLACE la générique, '
        'il ne s\'y ajoute pas', (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 7,
        'avertissementNiveau': 'Le niveau qui fait foi est celui du bilan des '
            'trois tâches.',
        'feedback': <String, dynamic>{},
      })));

      await _openReadingRule(tester, via: 'NOTE SUR L\'ÉCHELLE DU TCF');
      expect(
        find.text('Le niveau qui fait foi est celui du bilan des trois '
            'tâches.'),
        findsOneWidget,
      );
      // Dire deux fois la meme chose est exactement le defaut que la refonte
      // corrige.
      expect(find.text(kNotePorteeSurLaTache), findsNothing);
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
      expect(find.text('Satisfaisant'), findsOneWidget);
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

  group('votre rédaction', () {
    final json = <String, dynamic>{
      'noteSurVingt': 12,
      'feedback': <String, dynamic>{
        'version_amelioree': 'Bonjour Marie, je viens de trouver un '
            'appartement dans le centre-ville.',
      },
    };

    testWidgets('le texte rendu et sa réécriture au même endroit, une seule '
        'à la fois', (tester) async {
      await tester.pumpWidget(_host(
        _eval(json),
        productionText: 'Bonjour Marie, j\'ai trouvé un appartement.',
      ));

      expect(find.text('Votre rédaction'), findsOneWidget);
      expect(
        find.text('Bonjour Marie, j\'ai trouvé un appartement.'),
        findsOneWidget,
      );
      // La comparaison se demande : elle ne s'impose pas.
      expect(find.textContaining('je viens de trouver'), findsNothing);

      await tester.tap(find.text('Voir la version améliorée'));
      await tester.pumpAndSettle();

      expect(find.textContaining('je viens de trouver'), findsOneWidget);
      expect(find.text('Masquer la version améliorée'), findsOneWidget);
    });

    testWidgets('sans texte rendu, la version améliorée garde sa carte',
        (tester) async {
      await tester.pumpWidget(_host(_eval(json)));

      expect(find.text('Version améliorée'), findsOneWidget);
      expect(find.textContaining('je viens de trouver'), findsOneWidget);
    });

    testWidgets('absente à l\'oral, sans trou visuel', (tester) async {
      // Meme charge utile : c'est l'epreuve qui decide, pas la presence du
      // champ — une eval orale ne doit jamais rendre ce bloc.
      await tester.pumpWidget(_host(_eval(json), isOral: true));

      expect(find.text('Version améliorée'), findsNothing);
      expect(find.textContaining('je viens de trouver'), findsNothing);
    });
  });

  group('analyse complète', () {
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

    testWidgets('repliée par défaut', (tester) async {
      await tester.pumpWidget(_host(_eval(json)));

      expect(find.text("Voir l'analyse complète"), findsOneWidget);
      expect(find.text('Ce que demandait la consigne'), findsNothing);
      expect(find.text('Production plus courte que demandé.'), findsNothing);
      expect(find.text('Suggestions'), findsNothing);
    });

    testWidgets('dépliée : rien n\'est perdu, dans l\'ordre du web',
        (tester) async {
      await tester.pumpWidget(_host(_eval(json)));
      await _openFullAnalysis(tester);

      final avertissementY = tester
          .getTopLeft(find.text('Production plus courte que demandé.'))
          .dy;
      final accomplissementY =
          tester.getTopLeft(find.text('Ce que demandait la consigne')).dy;
      final exemplesY = tester.getTopLeft(find.text('Corrections')).dy;
      final suggestionsY = tester.getTopLeft(find.text('Suggestions')).dy;

      expect(avertissementY, lessThan(accomplissementY));
      expect(accomplissementY, lessThan(exemplesY));
      expect(exemplesY, lessThan(suggestionsY));

      // Les trois groupes de l'accomplissement restent distincts.
      expect(find.text('Invitation absente'), findsOneWidget);
      expect(find.text('Loyer non mentionné'), findsOneWidget);
      expect(find.textContaining("n'enlève aucun point"), findsOneWidget);
    });

    testWidgets('le détail par critère a quitté le repli pour le profil',
        (tester) async {
      await tester.pumpWidget(_host(_eval(json)));

      expect(find.text('Votre profil en un coup d\'œil'), findsOneWidget);
      await _openFullAnalysis(tester);
      expect(find.text('Détail par critère'), findsNothing);
    });

    testWidgets('la consigne est rendue en TROIS groupes titrés et comptés',
        (tester) async {
      await tester.pumpWidget(_host(_eval(json)));
      await _openFullAnalysis(tester);

      final traitesY = tester.getTopLeft(find.text('Points traités')).dy;
      final manquesY = tester.getTopLeft(find.text('Manques obligatoires')).dy;
      final pistesY = tester.getTopLeft(find.text('Pistes non abordées')).dy;

      // L'ordre porte le sens : ce qui est fait, ce qui coûte des points, ce
      // qui n'en coûte aucun.
      expect(traitesY, lessThan(manquesY));
      expect(manquesY, lessThan(pistesY));

      // Chaque groupe annonce son compteur avant qu'on lise le détail.
      expect(find.text('1'), findsNWidgets(3)); // les 3 compteurs de groupe

      // Un manque reste au-dessus de sa piste : le regroupement n'a pas
      // melange les deux.
      expect(
        tester.getTopLeft(find.text('Invitation absente')).dy,
        lessThan(tester.getTopLeft(find.text('Loyer non mentionné')).dy),
      );

      // Le tag dit d'où vient le point, dans les mots du web.
      expect(find.text('demandé par la consigne'), findsNWidgets(2));
      expect(find.text('piste'), findsOneWidget);
      expect(find.text('piste abordée'), findsNothing);
      expect(find.text('demandé'), findsNothing);

      // Le pied vit sous les pistes, et nulle part ailleurs.
      final footY =
          tester.getTopLeft(find.textContaining("n'enlève aucun point")).dy;
      expect(footY, greaterThan(pistesY));
    });

    testWidgets('à l\'oral, les exemples sont des reformulations',
        (tester) async {
      await tester.pumpWidget(_host(_eval(json), isOral: true));
      await _openFullAnalysis(tester);

      expect(find.text('Reformulations pour plus de clarté'), findsOneWidget);
      expect(find.text('Corrections'), findsNothing);
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
      // Et surtout : plus de doublon dans « Voir l'analyse complète ».
      expect(find.text("Voir l'analyse complète"), findsNothing);

      await _openTile(tester, 'Ce qui marche');
      expect(find.text('Message clair'), findsOneWidget);
      expect(find.text('Temps du passé maîtrisés'), findsOneWidget);
    });

    testWidgets('aucun détail à montrer : pas de section vide à déplier',
        (tester) async {
      await tester.pumpWidget(_host(_eval(<String, dynamic>{
        'noteSurVingt': 12,
        'feedback': <String, dynamic>{},
      })));

      expect(find.text("Voir l'analyse complète"), findsNothing);
    });
  });

  group('limite de l\'évaluation orale', () {
    testWidgets('affichée en repli quand le correcteur n\'a rien averti',
        (tester) async {
      await tester.pumpWidget(_host(
        _eval(<String, dynamic>{
          'noteSurVingt': 7,
          'feedback': <String, dynamic>{},
        }),
        isOral: true,
      ));
      await _openFullAnalysis(tester);

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
      await _openFullAnalysis(tester);

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
      await _openFullAnalysis(tester);

      expect(find.text(kOralEvaluationLimitNotice), findsNothing);
      expect(find.text('À noter'), findsNothing);
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
    expect(find.text('NIVEAU ESTIMÉ'), findsNothing);

    expect(find.text('Vocabulaire'), findsOneWidget);
    // 13/20 vaut B2 au TCF : la bande le dit, un « 13/20 » scolaire suggérait
    // l'inverse. Seule la note globale reste chiffrée, en tête du rapport.
    expect(find.text('Très bonne maîtrise'), findsOneWidget);
    expect(find.text('13/20', findRichText: true), findsNothing);

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
        expect(legacy.bande, 'Très bonne maîtrise', reason: 'note $note');
        expect(legacy.color, AppColors.green, reason: 'note $note');
      }
    });

    testWidgets('un 9/20 n\'est plus un échec : c\'est le haut du B1',
        (tester) async {
      final neuf = await render(tester, note: 9);

      expect(neuf.bande, 'Satisfaisant');
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
        // Seul le plancher (note < 2, sous le A1) garde la bande « Fragile »
        // du serveur, qui est rouge parce que c'est un jugement qualitatif —
        // pas un niveau CECRL peint en échec.
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
      expect(un.bande, 'Fragile');
      expect(
        un,
        await render(tester, note: 1, bande: BandeCritere.fragile),
      );
    });
  });
}
