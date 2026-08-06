import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sejourfr_mobile/core/models/skill_models.dart';
import 'package:sejourfr_mobile/core/theme/app_theme.dart';
import 'package:sejourfr_mobile/core/widgets/app_tag.dart';
import 'package:sejourfr_mobile/screens/tcf_production/competences/widgets/competence_card.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/production_blocks.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/production_hero.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/production_task_pills.dart';
import 'package:sejourfr_mobile/screens/tcf_production/competences/widgets/skill_prompt_card.dart';
import 'package:sejourfr_mobile/screens/tcf_production/competences/widgets/skill_references_tabs.dart';
import 'package:sejourfr_mobile/screens/tcf_production/competences/widgets/skill_status_badge.dart';
import 'package:sejourfr_mobile/screens/tcf_production/tcf_production_module.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

SkillReferenceDto _ref(SkillReferenceLevel level) => SkillReferenceDto(
      level: level,
      text: 'Texte ${level.wire}',
      pedagogicalNote: 'Note ${level.wire}',
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('accent du module', () {
    test('EO est rouge, EE est bleu — declaré une seule fois', () {
      expect(TcfProductionModule.eo.accent, AppColors.red);
      expect(TcfProductionModule.eo.accentDark, AppColors.redDark);
      expect(TcfProductionModule.ee.accent, AppColors.blue);
      expect(TcfProductionModule.ee.accentDark, AppColors.blueDark);
    });
  });

  group('AppTag', () {
    testWidgets('le ton ambre passe par le token de texte, jamais un hex',
        (tester) async {
      await tester.pumpWidget(
        _host(const AppTag(label: 'À renforcer', tone: TagTone.amber)),
      );

      final text = tester.widget<Text>(find.text('À renforcer'));
      expect(text.style!.color, AppColors.amberDark);
      // Le token de remplissage reste illisible en lettres : on ne doit pas
      // y revenir par mégarde.
      expect(text.style!.color, isNot(AppColors.amber));
    });

    testWidgets('compact change la graisse et la taille, pas le ton',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              AppTag(label: 'defaut', tone: TagTone.amber),
              AppTag(label: 'compact', tone: TagTone.amber, compact: true),
            ],
          ),
        ),
      );

      final normal = tester.widget<Text>(find.text('defaut')).style!;
      final compact = tester.widget<Text>(find.text('compact')).style!;

      expect(normal.fontSize, 12);
      expect(normal.fontWeight, FontWeight.w600);
      expect(compact.fontSize, 10);
      expect(compact.fontWeight, FontWeight.w900);
      expect(compact.color, normal.color);
    });
  });

  group('hero de l\'accueil Compétences', () {
    testWidgets('affiche la progression globale de la tâche', (tester) async {
      await tester.pumpWidget(
        _host(
          ProductionHero(
            accent: AppColors.blue,
            accentDark: AppColors.blueDark,
            eyebrow: 'Parcours TCF',
            title: 'Tâche 1 · Expression écrite',
            description: 'Travaille une compétence à la fois.',
            percent: 7 / 40 * 100,
            progressLabel: '7/40 sujets traités',
            level: 'A2',
          ),
        ),
      );

      expect(find.text('PARCOURS TCF'), findsOneWidget);
      expect(find.text('Tâche 1 · Expression écrite'), findsOneWidget);
      expect(find.text('Progression · 7/40 sujets traités'), findsOneWidget);
      expect(find.text('18 %'), findsOneWidget);
      expect(find.text('A2'), findsOneWidget);
    });

    testWidgets('sans palier connu, aucune pilule inventée', (tester) async {
      await tester.pumpWidget(
        _host(
          const ProductionHero(
            accent: AppColors.red,
            accentDark: AppColors.redDark,
            eyebrow: 'Parcours TCF',
            title: 'Tâche 2 · Expression orale',
            description: 'Travaille une compétence à la fois.',
            percent: 0,
            progressLabel: '0/40 sujets traités',
          ),
        ),
      );

      expect(find.text('0 %'), findsOneWidget);
      expect(find.textContaining('A2'), findsNothing);
    });
  });

  group('pastilles de tâche', () {
    testWidgets('la tâche active est pleine, un tap change de tâche',
        (tester) async {
      int? tapped;
      await tester.pumpWidget(
        _host(
          ProductionTaskPills(
            active: 2,
            accent: AppColors.blue,
            onChanged: (n) => tapped = n,
          ),
        ),
      );

      expect(find.text('Tâche 1'), findsOneWidget);
      expect(find.text('Tâche 2'), findsOneWidget);
      expect(find.text('Tâche 3'), findsOneWidget);

      // Actif = texte blanc sur fond accent ; inactif = texte encre.
      expect(tester.widget<Text>(find.text('Tâche 2')).style!.color,
          AppColors.white);
      expect(tester.widget<Text>(find.text('Tâche 1')).style!.color,
          AppColors.inkSoft);

      await tester.tap(find.text('Tâche 3'));
      expect(tapped, 3);
    });
  });

  group('verdict du critère unique', () {
    test('PARTIEL prend l\'ambre LISIBLE — la couleur habille le libellé', () {
      expect(skillCriterionColor(SkillCriterionStatus.partial),
          AppColors.amberDark);
      expect(skillCriterionColor(SkillCriterionStatus.partial),
          isNot(AppColors.amber));
      // Les deux autres verdicts ne bougent pas.
      expect(
          skillCriterionColor(SkillCriterionStatus.validated), AppColors.green);
      expect(skillCriterionColor(SkillCriterionStatus.notValidated),
          AppColors.red);
    });
  });

  group('références comparatives', () {
    testWidgets('aucune référence ⇒ le widget ne rend rien (et ne casse pas)',
        (tester) async {
      await tester.pumpWidget(_host(const SkillReferencesTabs(references: [])));

      expect(tester.takeException(), isNull);
      expect(find.text('Attendu'), findsNothing);
      // L'écran de résultat retire le titre avec le contenu : plus d'intertitre
      // orphelin au-dessus du vide.
      expect(find.text('Compare avec les niveaux de référence'), findsNothing);
    });

    test('Insuffisant rouge · Attendu vert · Très réussi bleu', () {
      expect(
        skillReferenceColor(SkillReferenceLevel.insufficient),
        AppColors.red,
      );
      expect(skillReferenceColor(SkillReferenceLevel.expected), AppColors.green);
      expect(skillReferenceColor(SkillReferenceLevel.excellent), AppColors.blue);
    });

    testWidgets('ouvre sur « Attendu » et colore l\'onglet actif',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SkillReferencesTabs(
            references: [
              _ref(SkillReferenceLevel.insufficient),
              _ref(SkillReferenceLevel.expected),
              _ref(SkillReferenceLevel.excellent),
            ],
          ),
        ),
      );

      // La cible, pas le contre-exemple.
      expect(find.text('Texte EXPECTED'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Attendu')).style!.color,
        AppColors.green,
      );
      expect(
        tester.widget<Text>(find.text('Insuffisant')).style!.color,
        AppColors.inkSoft,
      );

      await tester.tap(find.text('Insuffisant'));
      await tester.pumpAndSettle();

      expect(find.text('Texte INSUFFICIENT'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Insuffisant')).style!.color,
        AppColors.red,
      );
    });
  });

  group('tipline', () {
    testWidgets('explique pourquoi les références sont masquées',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const ProductionTipline(
            lead: 'Important :',
            body: 'Les exemples de référence et l\'analyse apparaissent '
                'seulement après ta production.',
          ),
        ),
      );

      expect(
        find.textContaining('seulement après ta production'),
        findsOneWidget,
      );
    });
  });

  group('cartes de liste', () {
    SkillPromptSummary prompt(SkillPromptStatus status) => SkillPromptSummary(
          id: 'p1',
          code: 'EE1-C1-P1',
          title: 'Refuser une invitation',
          uniqueCriterion: 'Annoncer le refus et donner une raison.',
          difficultyLevel: SkillDifficulty.easy,
          displayOrder: 1,
          status: status,
          attemptCount: status.isTreated ? 2 : 0,
        );

    testWidgets('un sujet traité porte le liseré, un sujet à faire non',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              SkillPromptCard(
                prompt: prompt(SkillPromptStatus.validated),
                accent: AppColors.blue,
                onTap: () {},
              ),
              SkillPromptCard(
                prompt: prompt(SkillPromptStatus.todo),
                accent: AppColors.blue,
                onTap: () {},
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Validé'), findsOneWidget);
      expect(find.text('À faire'), findsOneWidget);
      // Le liseré n'existe que sur le sujet traité : une seule barre de 3 px.
      final rails = find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxWidth == 3,
      );
      expect(rails, findsOneWidget);
    });

    testWidgets('la carte de compétence se rend sans erreur de contrainte',
        (tester) async {
      await tester.pumpWidget(
        _host(
          CompetenceCard(
            skill: SkillDto.fromJson(const <String, dynamic>{
              'id': 's1',
              'section': 'EE',
              'taskCode': 'EE1',
              'code': 'EE1-C1',
              'title': 'Répondre à une invitation',
              'description': 'Savoir accepter ou refuser clairement.',
              'generalCriterion': 'Le refus est explicite et justifié.',
              'targetLevel': 'A2',
              'displayOrder': 1,
              'promptCount': 5,
              'attemptedCount': 3,
              'validatedCount': 2,
              'toReinforceCount': 1,
            }),
            accent: AppColors.blue,
            onTap: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Répondre à une invitation'), findsOneWidget);
      expect(find.text('3/5 traités · 2 ✓'), findsOneWidget);
    });
  });

  group('intertitre de section', () {
    testWidgets('le lien est absent quand aucune action n\'est fournie',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const ProductionSectionHead(
            title: 'Petits sujets',
            description: 'Les sujets déjà réalisés restent identifiables.',
          ),
        ),
      );

      expect(find.text('Petits sujets'), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('le lien « Continuer » déclenche son action', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(
          ProductionSectionHead(
            title: 'Compétences de la tâche 1',
            linkLabel: 'Continuer',
            onLinkTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Continuer'));
      expect(tapped, isTrue);
    });
  });
}
