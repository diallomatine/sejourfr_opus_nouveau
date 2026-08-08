import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sejourfr_mobile/core/api/api_exception.dart';
import 'package:sejourfr_mobile/core/api/production_repository.dart';
import 'package:sejourfr_mobile/core/api/repositories.dart';
import 'package:sejourfr_mobile/core/api/skill_repository.dart';
import 'package:sejourfr_mobile/core/auth/auth_controller.dart';
import 'package:sejourfr_mobile/core/auth/token_storage.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/core/models/production_models.dart';
import 'package:sejourfr_mobile/core/models/skill_models.dart';
import 'package:sejourfr_mobile/core/providers/shared_prefs_provider.dart';
import 'package:sejourfr_mobile/screens/tcf_production/competences/competences_providers.dart';
import 'package:sejourfr_mobile/screens/tcf_production/expression_hub_data.dart';
import 'package:sejourfr_mobile/screens/tcf_production/production_catalog.dart';
import 'package:sejourfr_mobile/screens/tcf_production/production_parcours_screen.dart';
import 'package:sejourfr_mobile/screens/tcf_production/production_quota_info.dart';
import 'package:sejourfr_mobile/screens/tcf_production/tcf_production_module.dart';
import 'package:sejourfr_mobile/screens/tcf_production/task_training_data.dart';
import 'package:sejourfr_mobile/screens/tcf_production/widgets/production_mode_tabs.dart';

/// Ce fichier verrouille le **contrat de fluidité** du parcours TCF EE/EO :
/// naviguer entre les tâches et entre les modes ne redemande rien au backend.
/// Les faux repositories comptent les appels — c'est la seule preuve qui tient,
/// un écran peut paraître instantané en rechargeant quand même.

// ---------------------------------------------------------------- compétences

SkillDto _skill(SkillSection section, int tache, int order) => SkillDto.fromJson({
      'id': '${section.wire}$tache-$order',
      'section': section.wire,
      'taskCode': section.taskCode(tache),
      'code': 'C$order',
      'title': 'Compétence $order',
      'description': 'Pourquoi',
      'generalCriterion': 'Critère',
      'targetLevel': 'B1',
      'displayOrder': order,
      'promptCount': 5,
      'attemptedCount': 0,
      'validatedCount': 0,
      'toReinforceCount': 0,
    });

/// Repository de compétences qui **compte** ses appels. `noSuchMethod` couvre
/// le reste de l'interface : ces tests ne portent que sur les deux lectures de
/// liste.
class _CountingSkillRepository implements SkillRepository {
  _CountingSkillRepository({this.sectionFilterSupported = true});

  /// `false` simule un backend où `?section=` n'est pas encore déployé.
  final bool sectionFilterSupported;

  int sectionCalls = 0;
  final List<String> taskCodeCalls = [];

  @override
  Future<List<SkillDto>> listSkillsBySection(String section) async {
    sectionCalls++;
    if (!sectionFilterSupported) {
      throw ApiException(statusCode: 400, message: 'Unknown parameter');
    }
    final s = SkillSection.fromWire(section);
    return [
      for (var tache = 1; tache <= 3; tache++)
        for (var order = 1; order <= 8; order++) _skill(s, tache, order),
    ];
  }

  @override
  Future<List<SkillDto>> listSkills(String taskCode) async {
    taskCodeCalls.add(taskCode);
    final s = SkillSection.fromWire(taskCode.substring(0, 2));
    final tache = int.parse(taskCode.substring(2));
    return [for (var order = 1; order <= 8; order++) _skill(s, tache, order)];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

// ----------------------------------------------------------------- production

ProductionTaskDto _task(String id, int tache) => ProductionTaskDto(
      id: id,
      epreuve: EpreuveType.tcfEe,
      tacheNumero: tache,
      niveauCible: 'B1',
      consigne: 'Consigne $id',
      motsMin: 40,
      motsMax: 90,
    );

class _CountingProductionRepository implements ProductionRepository {
  int listTasksCalls = 0;
  int listMineCalls = 0;
  final List<int> listExamplesCalls = [];

  @override
  Future<List<ProductionTaskDto>> listTasks({
    required EpreuveType epreuve,
    String? niveau,
    int? tacheNumero,
  }) async {
    listTasksCalls++;
    return [
      for (var tache = 1; tache <= 3; tache++)
        for (var i = 1; i <= 4; i++) _task('t$tache-$i', tache),
    ];
  }

  @override
  Future<List<ProductionSubmissionDto>> listMine({
    EpreuveType? epreuve,
    int limit = 50,
  }) async {
    listMineCalls++;
    return [
      ProductionSubmissionDto.fromJson({
        'id': 'sub-1',
        'epreuve': 'TCF_EE',
        'tacheNumero': 1,
        'productionTaskId': 't1-1',
        'statut': 'EVALUATED',
        'submittedAt': DateTime.now().toIso8601String(),
      }),
    ];
  }

  @override
  Future<List<ProductionExampleDto>> listExamples({
    required EpreuveType epreuve,
    required int tacheNumero,
  }) async {
    listExamplesCalls.add(tacheNumero);
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Abonne le container au provider et attend sa résolution, comme le ferait un
/// widget monté. L'abonnement est **gardé** : c'est ce qui reproduit un écran
/// qui reste à l'écran (ou monté dans l'`IndexedStack` du parcours).
Future<T> _settle<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider,
) async {
  container.listen(provider, (_, __) {}, fireImmediately: true);
  await Future<void>.delayed(Duration.zero);
  final value = container.read(provider);
  return value.requireValue;
}

/// Secure storage muet : le bootstrap d'auth conclut « déconnecté » sans
/// toucher au canal natif. Suffisant ici — le parcours ne lit l'auth que pour
/// le verrou freemium, hors périmètre de ces tests.
class _NoTokenStorage extends TokenStorage {
  @override
  Future<String?> readAccess() async => null;
}

void main() {
  group('Compétences — un seul appel pour les trois tâches', () {
    test('T1 → T2 → T3 → T1 ne déclenche qu\'un appel réseau', () async {
      final repo = _CountingSkillRepository();
      final container = ProviderContainer(
        overrides: [skillRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      SkillsKey key(int tache) =>
          SkillsKey(section: SkillSection.ee, tacheNumero: tache);

      final t1 = await _settle(container, skillsListProvider(key(1)));
      expect(t1, hasLength(8));
      expect(t1.every((s) => s.taskCode == 'EE1'), isTrue);

      for (final tache in [2, 3, 1, 2]) {
        await _settle(container, skillsListProvider(key(tache)));
      }

      // Un aller-retour entre les tâches est un tri local, pas un appel.
      expect(repo.sectionCalls, 1);
      expect(repo.taskCodeCalls, isEmpty);
    });

    test('les pastilles trient localement, dans l\'ordre d\'affichage',
        () async {
      final repo = _CountingSkillRepository();
      final container = ProviderContainer(
        overrides: [skillRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final t2 = await _settle(
        container,
        skillsListProvider(
            const SkillsKey(section: SkillSection.ee, tacheNumero: 2)),
      );

      expect(t2.map((s) => s.taskCode).toSet(), {'EE2'});
      expect(t2.map((s) => s.displayOrder).toList(), [1, 2, 3, 4, 5, 6, 7, 8]);
    });

    test('backend sans filtre `section` : repli en UNE passe, pas un appel '
        'par bascule', () async {
      final repo = _CountingSkillRepository(sectionFilterSupported: false);
      final container = ProviderContainer(
        overrides: [skillRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      for (final tache in [1, 2, 3, 1]) {
        final skills = await _settle(
          container,
          skillsListProvider(
              SkillsKey(section: SkillSection.eo, tacheNumero: tache)),
        );
        expect(skills, hasLength(8));
      }

      expect(repo.sectionCalls, 1);
      expect(repo.taskCodeCalls, ['EO1', 'EO2', 'EO3']);
    });

    test('une soumission invalide la progression — le cache ne ment pas',
        () async {
      final repo = _CountingSkillRepository();
      final container = ProviderContainer(
        overrides: [skillRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      const key = SkillsKey(section: SkillSection.ee, tacheNumero: 1);
      await _settle(container, skillsListProvider(key));
      expect(repo.sectionCalls, 1);

      container.invalidate(skillsSectionProvider(SkillSection.ee));
      await _settle(container, skillsListProvider(key));

      expect(repo.sectionCalls, 2);
    });
  });

  group('Sujets et Examens — un catalogue d\'épreuve, pas un par tâche', () {
    test('T1 → T2 → T1 ne redemande ni les sujets ni les productions',
        () async {
      final repo = _CountingProductionRepository();
      final container = ProviderContainer(
        overrides: [productionRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      TaskTrainingKey key(int tache) =>
          TaskTrainingKey(epreuve: EpreuveType.tcfEe, tacheNumero: tache);

      final t1 = await _settle(container, taskTrainingProvider(key(1)));
      expect(t1.subjects, hasLength(4));
      expect(t1.doneCount, 1);

      for (final tache in [2, 1, 2]) {
        final data = await _settle(container, taskTrainingProvider(key(tache)));
        expect(data.subjects, hasLength(4));
      }

      expect(repo.listTasksCalls, 1);
      expect(repo.listMineCalls, 1);
      // Seuls les modèles sont réellement portés par la tâche : un appel par
      // tâche visitée, jamais deux pour la même.
      expect(repo.listExamplesCalls, [1, 2]);
    });

    test('passer sur le mode Examens ne coûte aucun appel de plus', () async {
      final repo = _CountingProductionRepository();
      final container = ProviderContainer(
        overrides: [productionRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await _settle(
        container,
        taskTrainingProvider(
            const TaskTrainingKey(epreuve: EpreuveType.tcfEe, tacheNumero: 1)),
      );
      final before = repo.listTasksCalls + repo.listMineCalls;

      final hub =
          await _settle(container, expressionHubProvider(EpreuveType.tcfEe));

      expect(hub.totalSubjects, 12);
      expect(hub.doneSubjects, 1);
      expect(repo.listTasksCalls + repo.listMineCalls, before);
    });

    test('après une production, le catalogue est explicitement rechargé',
        () async {
      final repo = _CountingProductionRepository();
      final container = ProviderContainer(
        overrides: [productionRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      const key =
          TaskTrainingKey(epreuve: EpreuveType.tcfEe, tacheNumero: 1);
      await _settle(container, taskTrainingProvider(key));
      expect(repo.listMineCalls, 1);

      container.invalidate(productionCatalogProvider(EpreuveType.tcfEe));
      await _settle(container, taskTrainingProvider(key));

      // La progression du candidat doit repartir du serveur : c'est elle qui
      // bouge avec l'usage, contrairement au catalogue éditorial.
      expect(repo.listMineCalls, 2);
      // Les modèles, eux, n'ont pas bougé : rien à redemander.
      expect(repo.listExamplesCalls, [1]);
    });
  });

  group('Parcours — les trois modes vivent dans un seul écran', () {
    setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

    testWidgets(
        'changer de mode ne démonte pas le mode quitté et ne recharge rien',
        (tester) async {
      // L'info one-time « 1 essai gratuit » est marquée vue : elle ouvrirait un
      // bottom sheet par-dessus l'écran testé.
      SharedPreferences.setMockInitialValues(
          {prodQuotaInfoKey(EpreuveType.tcfEe): true});
      final prefs = await SharedPreferences.getInstance();
      final skills = _CountingSkillRepository();
      final production = _CountingProductionRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
            tokenStorageProvider.overrideWithValue(_NoTokenStorage()),
            skillRepositoryProvider.overrideWithValue(skills),
            productionRepositoryProvider.overrideWithValue(production),
          ],
          child: const MaterialApp(
            home: ProductionParcoursScreen(
              module: TcfProductionModule.ee,
              tab: ProductionModuleTab.competences,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compétences de la tâche 1'), findsOneWidget);
      // Le catalogue de l'épreuve est chargé **dès l'entrée** depuis que la
      // tête du parcours (héros chiffré) est commune aux trois modes : il
      // compte les sujets et les examens de l'épreuve entière, quel que soit
      // le mode affiché. Ce qui reste vrai — et c'est l'objet de ce test — est
      // qu'une bascule ne coûte **rien de plus**.
      expect(production.listTasksCalls, 1);
      expect(production.listMineCalls, 1);

      await tester.tap(find.text('Sujets'));
      await tester.pumpAndSettle();

      expect(find.text("Sujets d'entraînement"), findsOneWidget);
      // `skipOffstage: false` : le mode quitté est toujours dans l'arbre, avec
      // son état local et sa position de défilement — c'est tout l'objet de
      // l'`IndexedStack`.
      expect(
        find.text('Compétences de la tâche 1', skipOffstage: false),
        findsOneWidget,
      );

      await tester.tap(find.text('Compétences'));
      await tester.pumpAndSettle();

      expect(find.text('Compétences de la tâche 1'), findsOneWidget);
      // Un aller-retour entre deux modes : aucun appel de plus, ni d'un côté
      // ni de l'autre.
      expect(skills.sectionCalls, 1);
      expect(production.listTasksCalls, 1);
      expect(production.listMineCalls, 1);
    });

    testWidgets('le sélecteur de tâche ne recharge pas les compétences',
        (tester) async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final skills = _CountingSkillRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
            tokenStorageProvider.overrideWithValue(_NoTokenStorage()),
            skillRepositoryProvider.overrideWithValue(skills),
            productionRepositoryProvider
                .overrideWithValue(_CountingProductionRepository()),
          ],
          child: const MaterialApp(
            home: ProductionParcoursScreen(
              module: TcfProductionModule.eo,
              tab: ProductionModuleTab.competences,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Le sélecteur de tâche de la maquette porte l'intitulé court de la
      // tâche (« Entretien dirigé », « Jeu de rôle », « Opinion »), plus un
      // simple « Tâche 2 » : c'est le format et la contrainte qui distinguent
      // les trois tâches, pas leur numéro.
      const labels = {2: 'Jeu de rôle', 3: 'Opinion', 1: 'Entretien dirigé'};
      for (final entry in labels.entries) {
        await tester.tap(find.text(entry.value));
        await tester.pumpAndSettle();
        expect(find.text('Compétences de la tâche ${entry.key}'),
            findsOneWidget);
      }

      expect(skills.sectionCalls, 1);
    });
  });
}
