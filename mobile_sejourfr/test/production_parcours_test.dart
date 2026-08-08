import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/models/dashboard_models.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/core/models/production_models.dart';
import 'package:sejourfr_mobile/core/models/skill_models.dart';
import 'package:sejourfr_mobile/core/router/app_router.dart';
import 'package:sejourfr_mobile/core/theme/app_theme.dart';
import 'package:sejourfr_mobile/core/utils/dashboard_targets.dart';
import 'package:sejourfr_mobile/screens/tcf_production/competences/widgets/competence_card.dart';
import 'package:sejourfr_mobile/screens/tcf_production/expression_hub_data.dart';
import 'package:sejourfr_mobile/screens/tcf_production/production_nav.dart';
import 'package:sejourfr_mobile/screens/tcf_production/production_quota_info.dart';
import 'package:sejourfr_mobile/screens/tcf_production/task_training_data.dart';
import 'package:sejourfr_mobile/screens/tcf_production/tcf_production_module.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/production_common.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/production_mode_tabs.dart';

ProductionTaskDto _task(String id, int tache) => ProductionTaskDto(
      id: id,
      epreuve: EpreuveType.tcfEe,
      tacheNumero: tache,
      niveauCible: 'B1',
      consigne: 'Consigne $id',
      motsMin: 40,
      motsMax: 90,
    );

DashboardCategoryStat _stat(String code) => DashboardCategoryStat(
      themeId: null,
      code: code,
      label: code,
      percent: null,
      answered: 0,
      total: 0,
      mockExams: 0,
      bestMockScore: null,
      lastMockScore: null,
      prevMockScore: null,
      level: null,
    );

ProductionSubmissionDto _submission(String taskId) =>
    ProductionSubmissionDto.fromJson({
      'id': 'sub-$taskId',
      'epreuve': 'TCF_EE',
      'tacheNumero': 2,
      'productionTaskId': taskId,
      'statut': 'EVALUATED',
      'submittedAt': DateTime.now().toIso8601String(),
    });

void main() {
  group('Entrée du parcours EE/EO depuis Réviser', () {
    test('EE et EO ouvrent l\'accueil du parcours, pas un hub d\'épreuve', () {
      // Le hub d'épreuve (3 cartes de tâche + historique récent) est supprimé :
      // on arrive directement sur le mode « Compétences » de la tâche 1, le
      // changement de tâche se faisant par les pastilles T1/T2/T3.
      expect(dashboardCategoryRoute(_stat('TCF_EE')), AppRoutes.tcfEeEntry);
      expect(dashboardCategoryRoute(_stat('TCF_EO')), AppRoutes.tcfEoEntry);
    });

    test('les constantes d\'entrée sont la tâche 1 en mode Compétences', () {
      // Un seul endroit décide de la forme du chemin : si `production_nav`
      // change, la constante du registre de routes doit suivre.
      expect(AppRoutes.tcfEeEntry,
          productionCompetencesPath(TcfProductionModule.ee, 1));
      expect(AppRoutes.tcfEoEntry,
          productionCompetencesPath(TcfProductionModule.eo, 1));
    });

    test('les épreuves QCM gardent leur hub', () {
      expect(dashboardCategoryRoute(_stat('TCF_CO')), AppRoutes.tcfCoDetail);
      expect(dashboardCategoryRoute(_stat('TCF_CE')), AppRoutes.tcfCeDetail);
    });
  });

  group('HubData — progression réelle d\'une épreuve', () {
    test('la barre compte les sujets traités, pas les sessions', () {
      const data = HubData(
        countByTache: {1: 5, 2: 5, 3: 10},
        doneByTache: {1: 2, 3: 3},
        exams: [],
      );

      expect(data.totalSubjects, 20);
      expect(data.doneSubjects, 5);
      expect(data.percent, 25);
    });

    test('aucun sujet publié ⇒ 0 %, jamais une barre pleine', () {
      const data = HubData(
        countByTache: {},
        doneByTache: {},
        exams: [],
      );

      expect(data.totalSubjects, 0);
      expect(data.percent, 0);
    });
  });

  group('TaskTrainingData — progression d\'une tâche', () {
    test('un sujet repris ne compte qu\'une fois', () {
      final data = TaskTrainingData(
        subjects: [_task('a', 2), _task('b', 2), _task('c', 2), _task('d', 2)],
        examples: const [],
        lastByTaskId: {
          'a': _submission('a'),
          'b': _submission('b'),
        },
      );

      expect(data.doneCount, 2);
      expect(data.percent, 50);
    });

    test('une soumission sur un sujet retiré du catalogue ne gonfle rien', () {
      final data = TaskTrainingData(
        subjects: [_task('a', 2)],
        examples: const [],
        lastByTaskId: {
          'a': _submission('a'),
          'retire': _submission('retire'),
        },
      );

      expect(data.doneCount, 1);
      expect(data.percent, 100);
    });
  });

  group('productionTaskMeta — parité écrit ⇄ oral', () {
    test('les deux épreuves décrivent leurs 3 tâches, sans trou', () {
      for (final module in TcfProductionModule.values) {
        for (var tache = 1; tache <= 3; tache++) {
          final meta = productionTaskMeta(module, tache);
          expect(meta.title.trim(), isNotEmpty, reason: '$module T$tache');
          expect(meta.subtitle.trim(), isNotEmpty, reason: '$module T$tache');
          expect(meta.intro.trim(), isNotEmpty, reason: '$module T$tache');
        }
      }
    });
  });

  group('Navigation du module', () {
    // Depuis la passe fluidité, une bascule Compétences/Sujets/Examens ne
    // navigue plus : elle se joue dans `ProductionParcoursScreen`. Ne restent
    // ici que les chemins réellement empruntés.
    test('les chemins empruntés portent la bonne tâche', () {
      const mod = TcfProductionModule.eo;
      expect(productionCompetencesPath(mod, 2), '/tcf/eo/tache/2/competences');
      expect(productionExamplesPath(mod, 2), '/tcf/eo/tache/2/exemples');
      expect(productionCompetencesPath(TcfProductionModule.ee, 1),
          '/tcf/ee/tache/1/competences');
    });
  });

  group('ProductionModeTabs', () {
    testWidgets('porte les trois modes de la maquette, jamais un de plus',
        (tester) async {
      var picked = ProductionModuleTab.sujets;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProductionModeTabs(
            active: ProductionModuleTab.sujets,
            accent: AppColors.blue,
            onChanged: (t) => picked = t,
          ),
        ),
      ));

      expect(find.text('Compétences'), findsOneWidget);
      expect(find.text('Sujets'), findsOneWidget);
      expect(find.text('Examens'), findsOneWidget);
      // « Exemples » n'est pas un mode : c'est une ressource d'appoint, atteinte
      // depuis la liste des sujets.
      expect(find.text('Exemples'), findsNothing);

      await tester.tap(find.text('Examens'));
      expect(picked, ProductionModuleTab.examens);
    });
  });

  group("Info « 1 essai gratuit par épreuve »", () {
    // L'annonce a disparu du parcours quand le hub d'épreuve a été supprimé :
    // le candidat découvrait la limite en la consommant. Elle est remise sur la
    // liste des sujets TCF complets — le seul écran où la règle s'applique.
    test('la clé de mémorisation est PAR ÉPREUVE', () {
      expect(prodQuotaInfoKey(EpreuveType.tcfEe),
          'sejourfr.prodQuotaInfo.TCF_EE');
      expect(prodQuotaInfoKey(EpreuveType.tcfEo),
          'sejourfr.prodQuotaInfo.TCF_EO');
      expect(prodQuotaInfoKey(EpreuveType.tcfEe),
          isNot(prodQuotaInfoKey(EpreuveType.tcfEo)));
    });

    test('la clé est exactement celle du web — les deux fronts se souviennent '
        'de la même chose', () {
      for (final module in TcfProductionModule.values) {
        expect(
          prodQuotaInfoKey(module.epreuve),
          'sejourfr.prodQuotaInfo.${module.epreuve.wire}',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // Libellés partagés avec le web — CONTRAT GELÉ. Ces chaînes ne transitent pas
  // par le réseau : chaque front en tient une copie écrite à la main, donc rien
  // n'empêche une couche de dériver — sauf ce test, écrit des deux côtés sur
  // exactement les mêmes chaînes (`lib/parcours-tcf-navigation.test.ts`,
  // `lib/skill-progress.test.ts`).
  // -------------------------------------------------------------------------

  group('intitulés courts du sélecteur de tâche', () {
    test('expression écrite : Message · Récit · Opinion', () {
      const mod = TcfProductionModule.ee;
      expect(productionTaskShortTitle(mod, 1), 'Message');
      expect(productionTaskShortTitle(mod, 2), 'Récit');
      expect(productionTaskShortTitle(mod, 3), 'Opinion');
    });

    test('expression orale : Entretien dirigé · Jeu de rôle · Opinion', () {
      const mod = TcfProductionModule.eo;
      expect(productionTaskShortTitle(mod, 1), 'Entretien dirigé');
      expect(productionTaskShortTitle(mod, 2), 'Jeu de rôle');
      expect(productionTaskShortTitle(mod, 3), 'Opinion');
    });

    test("un numéro hors référentiel ne fabrique pas d'intitulé", () {
      expect(productionTaskShortTitle(TcfProductionModule.ee, 7), 'Tâche 7');
    });
  });

  group("titre d'une carte de sujet", () {
    test("le titre éditorial servi par l'API l'emporte", () {
      expect(productionSubjectTitle('Message à un ami', 1), 'Message à un ami');
    });

    test('titre absent ⇒ « Sujet N », jamais un titre vide ni un placeholder',
        () {
      expect(productionSubjectTitle(null, 1), 'Sujet 1');
      expect(productionSubjectTitle(null, 12), 'Sujet 12');
    });

    test('un titre blanc est traité comme absent', () {
      expect(productionSubjectTitle('   ', 3), 'Sujet 3');
    });

    test('les espaces de bord sont retirés', () {
      expect(
        productionSubjectTitle("  Refus d'une invitation  ", 2),
        "Refus d'une invitation",
      );
    });
  });

  group('contrainte d\'un sujet — jamais une borne inventée', () {
    ProductionTaskDto task({int? motsMin, int? motsMax, int? dureeMaxSec}) =>
        ProductionTaskDto(
          id: 't',
          epreuve: EpreuveType.tcfEe,
          tacheNumero: 1,
          niveauCible: 'B1',
          consigne: 'Consigne',
          motsMin: motsMin,
          motsMax: motsMax,
          dureeMaxSec: dureeMaxSec,
        );

    test("à l'écrit : les bornes servies par l'API, telles quelles", () {
      expect(
        productionTaskConstraint(task(motsMin: 40, motsMax: 90), isOral: false),
        '40-90 mots',
      );
    });

    test("à l'oral : la durée maximale", () {
      expect(
        productionTaskConstraint(task(dureeMaxSec: 180), isOral: true),
        '3 min',
      );
    });

    test('borne absente ⇒ rien : la source de vérité est `production_tasks`',
        () {
      expect(productionTaskConstraint(task(motsMin: 40), isOral: false), isNull);
      expect(productionTaskConstraint(task(), isOral: true), isNull);
    });
  });

  group('libellé d\'état d\'une compétence', () {
    SkillDto skill({
      required int total,
      required int attempted,
      required int validated,
    }) =>
        SkillDto.fromJson({
          'id': 's',
          'section': 'EE',
          'taskCode': 'EE1',
          'code': 'EE1-C1',
          'title': 'Compétence',
          'description': 'Pourquoi',
          'generalCriterion': 'Critère',
          'targetLevel': 'A2',
          'displayOrder': 1,
          'promptCount': total,
          'attemptedCount': attempted,
          'validatedCount': validated,
          'toReinforceCount': 0,
        });

    test('rien de tenté : on invite, on ne reproche rien', () {
      expect(
        competenceProgressLabel(skill(total: 5, attempted: 0, validated: 0)),
        '5 à découvrir',
      );
    });

    test('des sujets réussis : « N réussis · M restants »', () {
      expect(
        competenceProgressLabel(skill(total: 5, attempted: 2, validated: 2)),
        '2 réussis · 3 restants',
      );
      expect(
        competenceProgressLabel(skill(total: 5, attempted: 1, validated: 1)),
        '1 réussi · 4 restants',
      );
    });

    test('traité mais rien de validé : « commencé », jamais « réussi »', () {
      expect(
        competenceProgressLabel(skill(total: 5, attempted: 1, validated: 0)),
        '1 commencé · 4 restants',
      );
      expect(
        competenceProgressLabel(skill(total: 5, attempted: 3, validated: 0)),
        '3 commencés · 2 restants',
      );
    });

    test('tout traité : plus de « restants » à annoncer', () {
      expect(
        competenceProgressLabel(skill(total: 5, attempted: 5, validated: 4)),
        '4 réussis',
      );
    });

    test("compétence sans sujet publié : on le dit, pas de « 0/0 »", () {
      expect(
        competenceProgressLabel(skill(total: 0, attempted: 0, validated: 0)),
        'Bientôt disponible',
      );
    });

    test('un backend incohérent ne produit jamais « 6/5 »', () {
      expect(
        competenceProgressLabel(skill(total: 5, attempted: 9, validated: 9)),
        '5 réussis',
      );
    });
  });
}
