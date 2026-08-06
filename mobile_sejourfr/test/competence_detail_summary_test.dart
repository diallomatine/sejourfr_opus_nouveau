import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sejourfr_mobile/core/api/repositories.dart';
import 'package:sejourfr_mobile/core/api/skill_repository.dart';
import 'package:sejourfr_mobile/core/models/skill_models.dart';
import 'package:sejourfr_mobile/screens/tcf_production/competences/competence_detail_screen.dart';
import 'package:sejourfr_mobile/screens/tcf_production/tcf_production_module.dart';

/// La carte de résumé d'une compétence **ne porte plus l'explication** : six
/// lignes de texte y repoussaient le critère et la liste des sujets. Elle vit
/// derrière une pastille d'information — et cette pastille n'existe pas quand
/// il n'y a rien à expliquer.

const String _kDescription =
    "On n'écrit pas de la même façon à un ami, à un voisin, à un employeur ou "
    "à une administration. Cette compétence entraîne le choix du ton, du "
    "tutoiement ou du vouvoiement et des formules de politesse, que le TCF "
    "observe dès la première ligne.";

const String _kCriterion = 'Le message est adapté à son destinataire.';

const String _kInfoLabel = 'À quoi sert cette compétence ?';

Map<String, dynamic> _detailJson(String description) => {
      'skill': {
        'id': 'c1',
        'section': 'EE',
        'taskCode': 'EE1',
        'code': 'EE1-C1',
        'title': 'Adapter le message au destinataire',
        'description': description,
        'generalCriterion': _kCriterion,
        'targetLevel': 'A2',
        'displayOrder': 1,
        'promptCount': 5,
        'attemptedCount': 0,
        'validatedCount': 0,
        'toReinforceCount': 0,
      },
      'prompts': [
        for (var i = 0; i < 5; i++)
          {
            'id': 'p${i + 1}',
            'code': 'EE1-C1-S${i + 1}',
            'title': 'Sujet ${i + 1}',
            'uniqueCriterion': _kCriterion,
            'difficultyLevel': 'EASY',
            'displayOrder': i + 1,
            'status': 'TODO',
            'attemptCount': 0,
          },
      ],
    };

/// Repository de test : l'écran de détail ne lit que le détail de la compétence.
class _FakeSkillRepository implements SkillRepository {
  _FakeSkillRepository(this.description);

  final String description;

  @override
  Future<SkillDetail> getSkillDetail(String skillId) async =>
      SkillDetail.fromJson(_detailJson(description));

  @override
  Future<SkillPromptDto> getPrompt(String promptId) async =>
      throw UnimplementedError();

  @override
  Future<SkillAnalysisQuotaDto> analysisQuota() async =>
      throw UnimplementedError();

  @override
  Future<List<SkillDto>> listSkills(String taskCode) async =>
      throw UnimplementedError();

  @override
  Future<List<SkillReferenceDto>> getReferences(String promptId) async =>
      throw UnimplementedError();

  @override
  Future<SkillAttemptDto> getAttempt(String attemptId) async =>
      throw UnimplementedError();

  @override
  Future<SkillAttemptDto> submitText({
    required String skillPromptId,
    required String texte,
    required bool requestAnalysis,
    SkillSelfEvaluation? selfEvaluation,
  }) async =>
      throw UnimplementedError();

  @override
  Future<SkillAttemptDto> submitAudio({
    required String skillPromptId,
    required File audioFile,
    required int durationSec,
    required bool requestAnalysis,
    SkillSelfEvaluation? selfEvaluation,
    String? mimeType,
  }) async =>
      throw UnimplementedError();

  @override
  Future<SkillAttemptDto> requestAnalysis(String attemptId) async =>
      throw UnimplementedError();

  @override
  Future<SkillAttemptDto> retryAnalysis(String attemptId) async =>
      throw UnimplementedError();
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required String description,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        skillRepositoryProvider
            .overrideWithValue(_FakeSkillRepository(description)),
      ],
      child: const MaterialApp(
        home: CompetenceDetailScreen(
          module: TcfProductionModule.ee,
          skillId: 'c1',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Le bouton d'information : annoncé aux lecteurs d'écran **et** au survol.
final Finder _infoButton = find.byWidgetPredicate(
  (w) =>
      w is Semantics &&
      w.properties.button == true &&
      w.properties.label == _kInfoLabel,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('carte de résumé d\'une compétence', () {
    testWidgets('l\'explication n\'est plus dans le corps de la carte',
        (tester) async {
      await _pumpDetail(tester, description: _kDescription);

      expect(find.text(_kDescription), findsNothing);
      // Ce qui reste visible sans rien toucher : le titre et le critère.
      expect(find.text('Adapter le message au destinataire'), findsWidgets);
      expect(find.text('CRITÈRE TRAVAILLÉ'), findsOneWidget);
      expect(find.text(_kCriterion), findsWidgets);
    });

    testWidgets('la pastille d\'information ouvre l\'explication',
        (tester) async {
      await _pumpDetail(tester, description: _kDescription);

      expect(_infoButton, findsOneWidget);
      expect(find.byTooltip(_kInfoLabel), findsOneWidget);

      // Cible tactile : au moins 44×44, quelle que soit la taille du dessin.
      final size = tester.getSize(_infoButton);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));

      await tester.tap(_infoButton);
      await tester.pumpAndSettle();

      expect(find.text(_kDescription), findsOneWidget);
    });

    testWidgets('sans explication, pas de bouton qui ouvrirait du vide',
        (tester) async {
      await _pumpDetail(tester, description: '');

      expect(_infoButton, findsNothing);
      expect(find.byTooltip(_kInfoLabel), findsNothing);
      expect(find.text('CRITÈRE TRAVAILLÉ'), findsOneWidget);
    });
  });
}
