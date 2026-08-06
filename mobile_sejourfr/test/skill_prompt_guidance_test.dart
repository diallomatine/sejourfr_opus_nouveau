import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sejourfr_mobile/core/models/skill_models.dart';
import 'package:sejourfr_mobile/core/theme/app_theme.dart';
import 'package:sejourfr_mobile/screens/tcf_production/competences/widgets/prompt_guidance.dart';
import 'package:sejourfr_mobile/screens/tcf_production/competences/widgets/skill_answer_card.dart';

/// Le guidage d'un petit sujet : quatre champs **tous facultatifs**, un écran
/// qui doit rester correct quand ils manquent, et une parité écrit ⇄ oral qui
/// tient parce que les deux passent par la même coque.
Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

Map<String, dynamic> _promptJson(Map<String, dynamic> extra) => {
      'id': 's1',
      'skillId': 'c1',
      'skillCode': 'EE1-C1',
      'skillTitle': 'Saluer et prendre congé',
      'section': 'EE',
      'taskCode': 'EE1',
      'taskTitle': 'Écrire un message court',
      'code': 'EE1-C1-S1',
      'title': 'Un mot pour votre voisine',
      'context': 'Vous partez 3 jours. Vos plantes ont besoin d\'eau.',
      'instruction': 'Écrivez les deux premières phrases de votre message.',
      'uniqueCriterion': 'Employer une salutation adaptée.',
      'difficultyLevel': 'EASY',
      'displayOrder': 1,
      'status': 'TODO',
      'attemptCount': 0,
      ...extra,
    };

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('décodage des 4 champs de guidage', () {
    test('un sujet guidé porte check-list, étiquettes, amorce et astuce', () {
      final prompt = SkillPromptDto.fromJson(_promptJson({
        'checklist': [
          'Saluez votre voisine',
          'Dites qui vous êtes',
          'Écrivez 2 phrases',
        ],
        'constraintTags': [
          {'label': 'Vouvoiement', 'icon': 'PERSON'},
          {'label': 'Ton poli', 'icon': 'TONE'},
        ],
        'answerStarter': 'Bonjour Madame, je suis votre voisin du…',
        'tip': 'commencez par bonjour, puis présentez-vous.',
      }));

      expect(prompt.checklist, hasLength(3));
      expect(prompt.checklist.first, 'Saluez votre voisine');
      expect(prompt.constraintTags.map((t) => t.label),
          ['Vouvoiement', 'Ton poli']);
      expect(prompt.constraintTags.first.icon, SkillConstraintIcon.person);
      expect(prompt.answerStarter, endsWith('…'));
      // Le mot « Astuce : » est ajouté par le front, jamais porté par la valeur.
      expect(prompt.tip, isNot(startsWith('Astuce')));
    });

    test('les quatre champs absents ⇒ des vides exploitables, jamais de null '
        'à l\'écran', () {
      final prompt = SkillPromptDto.fromJson(_promptJson({}));

      expect(prompt.checklist, isEmpty);
      expect(prompt.constraintTags, isEmpty);
      expect(prompt.answerStarter, isNull);
      expect(prompt.tip, isNull);
    });

    test('les chaînes vides valent absentes (pas de cadre sans contenu)', () {
      final prompt = SkillPromptDto.fromJson(_promptJson({
        'checklist': ['Saluez votre voisine', '   ', ''],
        'answerStarter': '   ',
        'tip': '',
      }));

      expect(prompt.checklist, ['Saluez votre voisine']);
      expect(prompt.answerStarter, isNull);
      expect(prompt.tip, isNull);
    });

    test('une étiquette sans libellé n\'existe pas ; un code inconnu, si', () {
      final prompt = SkillPromptDto.fromJson(_promptJson({
        'constraintTags': [
          {'label': '', 'icon': 'TONE'},
          {'icon': 'PERSON'},
          'pas un objet',
          {'label': 'Deux dates', 'icon': 'WAT'},
          {'label': 'Sans icône'},
        ],
      }));

      expect(prompt.constraintTags.map((t) => t.label),
          ['Deux dates', 'Sans icône']);
      // Un code non prévu (contenu créé depuis l'admin) reste affichable.
      expect(prompt.constraintTags.first.icon, SkillConstraintIcon.unknown);
      expect(prompt.constraintTags.last.icon, SkillConstraintIcon.unknown);
    });
  });

  group('table icône ↔ code', () {
    test('les 8 codes du contrat ont chacun leur icône, toutes distinctes', () {
      final contrat = SkillConstraintIcon.values
          .where((e) => e != SkillConstraintIcon.unknown)
          .toList();
      expect(contrat, hasLength(8));

      final icones = contrat.map(skillConstraintIcon).toSet();
      expect(icones, hasLength(8), reason: 'deux codes ne partagent pas une icône');
    });

    test('une valeur inconnue a une icône par défaut, jamais rien', () {
      expect(skillConstraintIcon(SkillConstraintIcon.unknown), isNotNull);
      expect(
        skillConstraintIcon(SkillConstraintIcon.unknown),
        isNot(skillConstraintIcon(SkillConstraintIcon.tone)),
      );
    });
  });

  group('puce de longueur — générée, jamais dupliquée par une étiquette', () {
    test('à l\'écrit elle vient des bornes en mots', () {
      final prompt = SkillPromptDto.fromJson(_promptJson({
        'recommendedMinWords': 15,
        'recommendedMaxWords': 35,
      }));
      expect(skillLengthHint(prompt), '≈ 15–35 mots');
    });

    test('à l\'oral elle vient de la durée conseillée', () {
      final prompt = SkillPromptDto.fromJson(_promptJson({
        'section': 'EO',
        'recommendedDurationSeconds': 45,
      }));
      expect(skillLengthHint(prompt), '≈ 45 secondes');
    });

    test('sans borne, aucune longueur inventée', () {
      expect(skillLengthHint(SkillPromptDto.fromJson(_promptJson({}))), isNull);
      // Une seule borne ne fait pas une fourchette.
      expect(
        skillLengthHint(
          SkillPromptDto.fromJson(_promptJson({'recommendedMinWords': 15})),
        ),
        isNull,
      );
    });
  });

  group('carte « Ce qu\'il faut faire »', () {
    testWidgets('rend un geste par ligne', (tester) async {
      await tester.pumpWidget(
        _host(
          const SkillChecklistCard(
            checklist: ['Saluez votre voisine', 'Dites qui vous êtes'],
            fallback: 'La consigne complète.',
            accent: AppColors.blue,
          ),
        ),
      );

      expect(find.text("Ce qu'il faut faire"), findsOneWidget);
      expect(find.text('Saluez votre voisine'), findsOneWidget);
      expect(find.text('Dites qui vous êtes'), findsOneWidget);
      expect(find.byIcon(LucideIcons.circleCheck), findsNWidgets(2));
      // La consigne brute ne double pas la check-list.
      expect(find.text('La consigne complète.'), findsNothing);
    });

    testWidgets('sans check-list, la carte retombe sur la consigne',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const SkillChecklistCard(
            checklist: [],
            fallback: 'La consigne complète.',
            accent: AppColors.blue,
          ),
        ),
      );

      // Jamais de carte vide : le candidat doit toujours savoir quoi faire.
      expect(find.text("Ce qu'il faut faire"), findsOneWidget);
      expect(find.text('La consigne complète.'), findsOneWidget);
      expect(find.byIcon(LucideIcons.circleCheck), findsNothing);
    });
  });

  group('rangée de contraintes', () {
    testWidgets('longueur d\'abord, puis les étiquettes avec leur icône',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const SkillConstraintRow(
            lengthHint: '≈ 15–35 mots',
            tags: [
              SkillConstraintTag(
                label: 'Vouvoiement',
                icon: SkillConstraintIcon.person,
              ),
            ],
            isEo: false,
          ),
        ),
      );

      expect(find.text('≈ 15–35 mots'), findsOneWidget);
      expect(find.text('Vouvoiement'), findsOneWidget);
      expect(find.byIcon(LucideIcons.user), findsOneWidget);
      expect(find.byIcon(LucideIcons.type), findsOneWidget);
    });

    testWidgets('sans étiquette, seule la longueur reste', (tester) async {
      await tester.pumpWidget(
        _host(
          const SkillConstraintRow(
            lengthHint: '≈ 45 secondes',
            tags: [],
            isEo: true,
          ),
        ),
      );

      expect(find.text('≈ 45 secondes'), findsOneWidget);
      expect(find.byIcon(LucideIcons.timer), findsOneWidget);
    });

    testWidgets('sans rien, la rangée n\'occupe aucune ligne', (tester) async {
      const row = SkillConstraintRow(lengthHint: null, tags: [], isEo: false);
      expect(row.isEmpty, isTrue);

      await tester.pumpWidget(_host(row));
      expect(find.byType(Wrap), findsNothing);
    });
  });

  group('carte « Votre réponse »', () {
    testWidgets('astuce à gauche, compteur à droite', (tester) async {
      await tester.pumpWidget(
        _host(
          const SkillAnswerCard(
            accent: AppColors.blue,
            tip: 'commencez par bonjour.',
            meta: '0 / 35 mots',
            child: SizedBox(height: 40),
          ),
        ),
      );

      expect(find.text('Votre réponse'), findsOneWidget);
      // Le préfixe « Astuce : » est ajouté ici, pas porté par la donnée.
      expect(find.text('Astuce : commencez par bonjour.'), findsOneWidget);
      expect(find.text('0 / 35 mots'), findsOneWidget);
      expect(find.byIcon(LucideIcons.lightbulb), findsOneWidget);
    });

    testWidgets('sans astuce, le pied n\'affiche que le compteur',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const SkillAnswerCard(
            accent: AppColors.blue,
            meta: '0 / 35 mots',
            child: SizedBox(height: 40),
          ),
        ),
      );

      expect(find.text('0 / 35 mots'), findsOneWidget);
      expect(find.byIcon(LucideIcons.lightbulb), findsNothing);
      expect(find.textContaining('Astuce'), findsNothing);
    });

    testWidgets('sans astuce ni compteur, aucun pied de carte', (tester) async {
      await tester.pumpWidget(
        _host(
          const SkillAnswerCard(
            accent: AppColors.red,
            child: SizedBox(height: 40),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.lightbulb), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('amorce', () {
    testWidgets('à l\'écrit, elle est le texte grisé du champ', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(
          SkillWritingField(
            controller: controller,
            onChanged: (_) {},
            accent: AppColors.blue,
            starter: 'Bonjour Madame, je suis votre voisin du…',
          ),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(
        field.decoration!.hintText,
        'Bonjour Madame, je suis votre voisin du…',
      );
      // Une amorce reste une amorce : elle ne préremplit jamais la réponse.
      expect(controller.text, isEmpty);
    });

    testWidgets('sans amorce, un texte grisé neutre — jamais « null »',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(
          SkillWritingField(
            controller: controller,
            onChanged: (_) {},
            accent: AppColors.blue,
          ),
        ),
      );

      final hint = tester.widget<TextField>(find.byType(TextField))
          .decoration!
          .hintText!;
      expect(hint, isNotEmpty);
      expect(hint.toLowerCase(), isNot(contains('null')));
    });

    testWidgets('à l\'oral, elle devient une suggestion de démarrage',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const SkillStarterHint(
            starter: 'Bonjour Madame, je suis votre voisin du…',
          ),
        ),
      );

      expect(find.textContaining('Commencez par'), findsOneWidget);
      expect(
        find.textContaining('Bonjour Madame, je suis votre voisin du…'),
        findsOneWidget,
      );
    });
  });
}
