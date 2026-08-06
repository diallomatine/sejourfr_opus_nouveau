import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/models/dashboard_models.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/core/models/production_models.dart';
import 'package:sejourfr_mobile/core/router/app_router.dart';
import 'package:sejourfr_mobile/core/theme/app_theme.dart';
import 'package:sejourfr_mobile/core/utils/dashboard_targets.dart';
import 'package:sejourfr_mobile/screens/tcf_production/expression_hub_data.dart';
import 'package:sejourfr_mobile/screens/tcf_production/production_nav.dart';
import 'package:sejourfr_mobile/screens/tcf_production/production_quota_info.dart';
import 'package:sejourfr_mobile/screens/tcf_production/task_training_data.dart';
import 'package:sejourfr_mobile/screens/tcf_production/tcf_production_module.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/production_common.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/production_module_bar.dart';

ProductionTaskDto _task(String id, int tache) => ProductionTaskDto(
      id: id,
      epreuve: EpreuveType.tcfEe,
      tacheNumero: tache,
      niveauCible: 'B1',
      consigne: 'Consigne $id',
      motsMin: 60,
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
        singles: [],
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
        singles: [],
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

  group('ProductionModuleBar', () {
    testWidgets('porte les trois modes de la maquette, jamais un de plus',
        (tester) async {
      var picked = ProductionModuleTab.sujets;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProductionModuleBar(
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
}
